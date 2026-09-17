#!/usr/bin/env python3
"""Portable packaging and hygiene checks that run anywhere (no Xcode needed).

They complement, and never replace, the Xcode build and test gates that run on
Codemagic. Exit code is non-zero on the first failure.

Usage:
    python3 Scripts/preflight.py             every check below
    python3 Scripts/preflight.py --release   the same, plus the release gate

The release gate (check 14) refuses any `<<OWNER: ...>>` placeholder left in the
website or the App Store listing, escaped or not. It is deliberately not part of
the default run: the placeholders are expected while the owner has not filled in
their legal name and contact details yet, and only a build that is on its way to
App Store Connect must not carry them. Codemagic therefore runs `--release` in the
ios-testflight and ios-appstore workflows only.
"""
from pathlib import Path
import json
import plistlib
import re
import struct
import sys
import zlib

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIRS = ["Nivli", "NivliMonitor", "NivliShield", "NivliTests", "NivliUITests"]
BUNDLES = {
    "Nivli": "Nivli/Nivli.entitlements",
    "NivliMonitor": "NivliMonitor/NivliMonitor.entitlements",
    "NivliShield": "NivliShield/NivliShield.entitlements",
}
ALLOWED_IMPORTS = {
    "Foundation", "SwiftUI", "StoreKit", "UIKit", "Observation", "Combine", "OSLog", "os",
    "XCTest", "UserNotifications", "HealthKit",
    # Screen Time API: choosing and shielding apps, the daily re-lock, the branded shield.
    "FamilyControls", "ManagedSettings", "ManagedSettingsUI", "DeviceActivity",
}
checks = 0


def fail(message):
    print(f"FAIL: {message}")
    sys.exit(1)


RELEASE = "--release" in sys.argv[1:]
for argument in sys.argv[1:]:
    if argument != "--release":
        fail(f"unknown argument {argument}; the only option is --release")


def tracked_files():
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        parts = path.relative_to(ROOT).parts
        if parts[0] in {".git", "build", "DerivedData", ".claude"} or "xcodeproj" in parts[0]:
            continue
        yield path


def check_png(path, require_opaque):
    raw = path.read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n":
        fail(f"{path}: not a PNG")
    offset = 8
    width = height = color = None
    while offset < len(raw):
        size = struct.unpack(">I", raw[offset:offset + 4])[0]
        kind = raw[offset + 4:offset + 8]
        body = raw[offset + 8:offset + 8 + size]
        crc = raw[offset + 8 + size:offset + 12 + size]
        if len(crc) != 4 or zlib.crc32(kind + body) != struct.unpack(">I", crc)[0]:
            fail(f"{path}: corrupt PNG chunk")
        if kind == b"IHDR":
            width, height, _depth, color = struct.unpack(">IIBB", body[:10])
        if kind == b"IEND":
            break
        offset += size + 12
    if (width, height) != (1024, 1024):
        fail(f"{path}: expected 1024x1024, got {width}x{height}")
    if require_opaque and color != 2:
        fail(f"{path}: the App Store icon must be opaque RGB (no alpha)")


# 1. Property lists, entitlements, privacy manifests parse.
for path in tracked_files():
    if path.suffix in {".plist", ".entitlements", ".xcprivacy"}:
        with path.open("rb") as stream:
            plistlib.load(stream)
        checks += 1

# 2. Asset catalogs reference existing files.
for path in tracked_files():
    if path.name == "Contents.json" and ".xcassets" in str(path):
        data = json.loads(path.read_text(encoding="utf-8"))
        for image in data.get("images", []):
            if "filename" in image and not (path.parent / image["filename"]).is_file():
                fail(f"{path}: missing {image['filename']}")
        checks += 1

# 3. App icon.
icon_dir = ROOT / "Nivli/Assets.xcassets/AppIcon.appiconset"
check_png(icon_dir / "AppIcon.png", require_opaque=True)
for variant in ["AppIcon-Dark.png", "AppIcon-Tinted.png"]:
    if (icon_dir / variant).exists():
        check_png(icon_dir / variant, require_opaque=False)
checks += 1

# 4. Privacy manifests in every bundle that ships.
for folder in BUNDLES:
    manifests = list((ROOT / folder).rglob("*.xcprivacy"))
    if not manifests:
        fail(f"missing privacy manifest in {folder}")
    manifest = plistlib.loads(manifests[0].read_bytes())
    if manifest.get("NSPrivacyTracking"):
        fail(f"{manifests[0]}: tracking must be false")
    if "NSPrivacyAccessedAPICategoryUserDefaults" not in manifests[0].read_text(encoding="utf-8"):
        fail(f"{manifests[0]}: missing UserDefaults required-reason declaration")
    checks += 1

# 5. App Review notes length.
notes = ROOT / "AppStore/REVIEW_NOTES.md"
if notes.exists() and len(notes.read_bytes()) > 4000:
    fail("AppStore/REVIEW_NOTES.md exceeds the 4,000-byte App Store Connect limit")
checks += 1

# 6. Project definition and StoreKit configuration.
project = (ROOT / "project.yml").read_text(encoding="utf-8")
if "name: Nivli" not in project:
    fail("project.yml must define the Nivli project")
json.loads((ROOT / "Config/Nivli.storekit").read_text(encoding="utf-8"))
checks += 1

# 7. Source hygiene: no placeholders, only known frameworks, no secrets, no print().
forbidden = re.compile(r"\b(TODO|FIXME|placeholder text|lorem ipsum)\b", re.IGNORECASE)
secret = re.compile(r"BEGIN (RSA |EC )?PRIVATE KEY|AuthKey_[A-Z0-9]+\.p8")
for folder in SOURCE_DIRS:
    for path in (ROOT / folder).rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        if forbidden.search(text):
            fail(f"{path}: contains a placeholder marker")
        if re.search(r"^\s*print\(", text, re.M):
            fail(f"{path}: uses print(); use os.Logger")
        for line in text.splitlines():
            stripped = line.strip()
            if stripped.startswith("import "):
                module = stripped.split()[1]
                if module not in ALLOWED_IMPORTS:
                    fail(f"{path}: unexpected import {module}")
        checks += 1
for path in tracked_files():
    if path.suffix in {".swift", ".yml", ".yaml", ".md", ".py", ".sh", ".json", ".html"}:
        if secret.search(path.read_text(encoding="utf-8", errors="ignore")):
            fail(f"{path}: looks like it contains a private key")

# 8. UI-test accessibility identifiers exist in the views.
view_ids = set()
for path in (ROOT / "Nivli").rglob("*.swift"):
    for arguments in re.findall(r'accessibilityIdentifier\(([^)\n]*)\)', path.read_text(encoding="utf-8")):
        view_ids.update(re.findall(r'"([a-z][A-Za-z0-9_]*)"', arguments))
test_ids = set()
for path in (ROOT / "NivliUITests").rglob("*.swift"):
    text = path.read_text(encoding="utf-8")
    test_ids.update(re.findall(r'\["([a-z][A-Za-z0-9_]*)"\]', text))
    test_ids.update(re.findall(r'identifier: "([a-z][A-Za-z0-9_]*)"', text))
missing = sorted(test_ids - view_ids)
if missing:
    fail(f"NivliUITests reference accessibility identifiers that no view sets: {', '.join(missing)}")
checks += 1

# 9. StoreKit test configuration lists exactly AppConfig.entitlementProductIDs, and the
# products on sale are a subset of them.
storekit = json.loads((ROOT / "Config/Nivli.storekit").read_text(encoding="utf-8"))
storekit_ids = {product["productID"] for product in storekit.get("products", [])}
for group in storekit.get("subscriptionGroups", []):
    storekit_ids.update(subscription["productID"] for subscription in group.get("subscriptions", []))
app_config = (ROOT / "Nivli/Services/AppConfig.swift").read_text(encoding="utf-8")
constants = dict(re.findall(r'static let (\w+ProductID) = "([^"]+)"', app_config))


def id_list(name):
    array = re.search(r"static let " + name + r": \[String\] = \[([^\]]*)\]", app_config)
    if not array:
        fail(f"AppConfig.{name} not found")
    ids = set()
    for constant in re.findall(r"\w+ProductID", array.group(1)):
        if constant not in constants:
            fail(f"AppConfig.{name} references unknown constant {constant}")
        ids.add(constants[constant])
    return ids


entitlement_ids = id_list("entitlementProductIDs")
sale_ids = id_list("productIDs")
if storekit_ids != entitlement_ids:
    fail(f"Config/Nivli.storekit products {sorted(storekit_ids)} != AppConfig.entitlementProductIDs {sorted(entitlement_ids)}")
if not sale_ids <= entitlement_ids:
    fail("AppConfig.productIDs must be a subset of entitlementProductIDs")
checks += 1

# 10. App Store listing limits: keywords <= 100 bytes, description <= 4000 characters.
listing = ROOT / "AppStore/LISTING.md"
if listing.exists():
    text = listing.read_text(encoding="utf-8")

    def fenced_block(heading):
        match = re.search(r"^## " + heading + r"\b[^\n]*\n+```[^\n]*\n(.*?)\n```", text, re.S | re.M)
        return match.group(1) if match else None

    keywords = fenced_block("Keywords")
    if keywords is not None and len(keywords.strip().encode("utf-8")) > 100:
        fail(f"AppStore/LISTING.md keywords are {len(keywords.strip().encode('utf-8'))} bytes; App Store Connect allows 100")
    description = fenced_block("Description")
    if description is not None and len(description) > 4000:
        fail(f"AppStore/LISTING.md description is {len(description)} characters; App Store Connect allows 4000")
    for heading, limit in [("Name", 30), ("Subtitle", 30), ("Promotional text", 170)]:
        block = fenced_block(heading)
        if block is not None and len(block.strip()) > limit:
            fail(f"AppStore/LISTING.md {heading} is {len(block.strip())} characters; the limit is {limit}")
checks += 1


# 11. Entitlements: every shipping bundle carries the App Group and Family Controls; the app
# also carries HealthKit (with background delivery) and project.yml explains the Health read.
def without_comments(text):
    return "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("#"))


def target_blocks(text):
    section = text.split("\ntargets:\n", 1)[-1]
    found = re.findall(r"^  ([A-Za-z][\w-]*):\n((?:(?: {4}.*)?\n)*)", section, re.M)
    return {name: without_comments(block) for name, block in found}


targets = target_blocks(project)
codemagic = (ROOT / "codemagic.yaml").read_text(encoding="utf-8")
codemagic_header = codemagic.split("\ndefinitions:", 1)[0]
app_group = "group.com.bluepenguin.nivli"
for name, entitlements_path in BUNDLES.items():
    block = targets.get(name)
    if block is None:
        fail(f"project.yml must define the {name} target")
    bundle = re.search(r"^ +PRODUCT_BUNDLE_IDENTIFIER: (\S+)$", block, re.M)
    entitlements = re.search(r"^ +CODE_SIGN_ENTITLEMENTS: (\S+)$", block, re.M)
    if not bundle or not entitlements or entitlements.group(1) != entitlements_path:
        fail(f"project.yml's {name} target needs PRODUCT_BUNDLE_IDENTIFIER and CODE_SIGN_ENTITLEMENTS: {entitlements_path}")
    plist = plistlib.loads((ROOT / entitlements_path).read_bytes())
    if app_group not in plist.get("com.apple.security.application-groups", []):
        fail(f"{entitlements_path} must list the App Group {app_group}")
    if plist.get("com.apple.developer.family-controls") is not True:
        fail(f"{entitlements_path} must set com.apple.developer.family-controls to true")
    variable = re.search(r'^ +(\w+): "' + re.escape(bundle.group(1)) + r'"$', codemagic, re.M)
    if not variable or f'fetch-signing-files "${variable.group(1)}" --type IOS_APP_STORE' not in codemagic:
        fail(f"codemagic.yaml must fetch App Store signing files for {name} ({bundle.group(1)})")
    if not re.search(r"^#\s+" + re.escape(bundle.group(1)) + r"\s", codemagic_header, re.M):
        fail(f"codemagic.yaml's opening comment must list {bundle.group(1)} with the capabilities its App ID needs")
    if name != "Nivli":
        if "APPLICATION_EXTENSION_API_ONLY: YES" not in block:
            fail(f"project.yml's {name} target must set APPLICATION_EXTENSION_API_ONLY: YES")
        if not re.search(r"^      - target: " + name + r"\n        embed: true$", targets.get("Nivli", ""), re.M):
            fail(f"project.yml's Nivli app target must embed {name}")
app_entitlements = plistlib.loads((ROOT / BUNDLES["Nivli"]).read_bytes())
if app_entitlements.get("com.apple.developer.healthkit") is not True:
    fail("Nivli/Nivli.entitlements must enable HealthKit")
if app_entitlements.get("com.apple.developer.healthkit.background-delivery") is not True:
    fail("Nivli/Nivli.entitlements must enable HealthKit background delivery")
if "INFOPLIST_KEY_NSHealthShareUsageDescription" not in targets.get("Nivli", ""):
    fail("project.yml must set NSHealthShareUsageDescription on the app")
checks += 1

# 12. The extensions' principal classes exist and the shield's asset is present.
principal = {
    "NivliMonitor": ("DeviceActivityMonitorExtension", "DeviceActivityMonitor"),
    "NivliShield": ("ShieldConfigurationExtension", "ShieldConfigurationDataSource"),
}
for folder, (class_name, superclass) in principal.items():
    plist = plistlib.loads((ROOT / folder / "Info.plist").read_bytes())
    declared = plist.get("NSExtension", {}).get("NSExtensionPrincipalClass", "")
    if declared != f"$(PRODUCT_MODULE_NAME).{class_name}":
        fail(f"{folder}/Info.plist must name $(PRODUCT_MODULE_NAME).{class_name} as NSExtensionPrincipalClass")
    swift = "\n".join(path.read_text(encoding="utf-8") for path in sorted((ROOT / folder).rglob("*.swift")))
    if not re.search(r"\bclass " + class_name + r"\s*:\s*" + superclass + r"\b", swift):
        fail(f"{folder} must declare `class {class_name}: {superclass}`")
    if re.search(r"@objc\(\w+\)\s*(?:final\s+)?class " + class_name + r"\b", swift):
        fail(f"{class_name} must keep its module-qualified name; an @objc(...) rename breaks NSExtensionPrincipalClass")
    if not (ROOT / folder / "Shared").exists() and f"- path: Nivli/Shared" not in targets.get(folder, ""):
        fail(f"project.yml's {folder} target must compile Nivli/Shared")
checks += 1

# 13. Shared code stays extension-safe: nothing in Nivli/Shared may touch the app-only APIs.
for path in (ROOT / "Nivli/Shared").rglob("*.swift"):
    text = path.read_text(encoding="utf-8")
    if re.search(r"\bUIApplication\b|\bimport SwiftUI\b|\bimport StoreKit\b|\bimport HealthKit\b", text):
        fail(f"{path}: Nivli/Shared is compiled into the extensions and must not use app-only frameworks")
checks += 1

# 14. Release gate (--release only): nothing that ships may still carry an owner placeholder.
if RELEASE:
    placeholder = re.compile(r"<<OWNER|&lt;&lt;OWNER")
    scanned = [path for path in (ROOT / "Web").rglob("*") if path.is_file()]
    listing_path = ROOT / "AppStore/LISTING.md"
    if listing_path.exists():
        scanned.append(listing_path)
    for path in sorted(scanned):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for number, line in enumerate(text.splitlines(), 1):
            if placeholder.search(line):
                fail(f"{path.relative_to(ROOT)}:{number}: fill in the <<OWNER ...>> placeholder before release")
    checks += 1

mode = "release" if RELEASE else "standard"
print(f"PASS: {checks} packaging, privacy, asset and hygiene checks ({mode}). Xcode build/test runs on Codemagic.")
