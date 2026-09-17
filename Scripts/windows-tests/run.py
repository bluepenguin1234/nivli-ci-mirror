#!/usr/bin/env python3
"""Run Nivli's pure-logic unit tests on a machine with no Xcode (Windows or Linux).

The Shared layer and the entitlement rule are plain Swift plus Foundation, apart from three
imports that only exist on Apple platforms: FamilyControls (FamilyActivitySelection), UIKit
(UIColor in BrandColors) and os (Logger). This script copies those sources and the matching
XCTest files into a throw-away Swift package, swaps the Apple-only imports for tiny stubs,
and runs `swift test`. It proves the day, streak, rest-day, shield-policy, store and
entitlement rules on any Swift toolchain; the SwiftUI screens and the Apple frameworks are
still verified on Codemagic.

Usage:  python3 Scripts/windows-tests/run.py [--keep] [output-dir]
Needs:  a Swift toolchain on PATH (swift.org, 6.x) with its platform SDK installed.
"""
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SOURCES = [
    "Nivli/Shared/SharedConstants.swift",
    "Nivli/Shared/DayKey.swift",
    "Nivli/Shared/WorkoutEntry.swift",
    "Nivli/Shared/NivliState.swift",
    "Nivli/Shared/SharedStore.swift",
    "Nivli/Shared/StreakEngine.swift",
    "Nivli/Shared/ShieldPolicy.swift",
    "Nivli/Services/Entitlements.swift",
]
TESTS = [
    "NivliTests/TestSupport.swift",
    "NivliTests/DayKeyTests.swift",
    "NivliTests/StreakEngineTests.swift",
    "NivliTests/ShieldPolicyTests.swift",
    "NivliTests/SharedStoreTests.swift",
    "NivliTests/NivliStateTests.swift",
    "NivliTests/EntitlementsTests.swift",
]
APPLE_ONLY_IMPORTS = re.compile(r"^import (FamilyControls|UIKit|os|Observation)\s*$", re.M)

STUBS = '''
// Stand-ins for the Apple-only types the Shared layer touches. Behaviourally irrelevant to
// the rules under test; they only have to compile and round-trip through Codable.
import Foundation

struct ApplicationToken: Hashable, Codable { let id: String }
struct ActivityCategoryToken: Hashable, Codable { let id: String }
struct WebDomainToken: Hashable, Codable { let id: String }

struct FamilyActivitySelection: Codable, Equatable {
    var applicationTokens: Set<ApplicationToken> = []
    var categoryTokens: Set<ActivityCategoryToken> = []
    var webDomainTokens: Set<WebDomainToken> = []
    var includeEntireCategory: Bool
    init(includeEntireCategory: Bool = false) { self.includeEntireCategory = includeEntireCategory }
}

final class UIColor {
    let red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat
    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }
    static let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    static let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    func withAlphaComponent(_ alpha: CGFloat) -> UIColor { UIColor(red: red, green: green, blue: blue, alpha: alpha) }
}

struct OSLogPrivacy { static let `public` = OSLogPrivacy(); static let `private` = OSLogPrivacy() }

struct OSLogMessage: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    let text: String
    init(stringLiteral value: String) { text = value }
    init(stringInterpolation: Interpolation) { text = stringInterpolation.output }
    struct Interpolation: StringInterpolationProtocol {
        var output = ""
        init(literalCapacity: Int, interpolationCount: Int) {}
        mutating func appendLiteral(_ literal: String) { output += literal }
        mutating func appendInterpolation<T>(_ value: T) { output += String(describing: value) }
        mutating func appendInterpolation<T>(_ value: T, privacy: OSLogPrivacy) { output += String(describing: value) }
    }
}

struct Logger {
    init(subsystem: String, category: String) {}
    func log(_ message: OSLogMessage) {}
    func error(_ message: OSLogMessage) {}
    func info(_ message: OSLogMessage) {}
    func debug(_ message: OSLogMessage) {}
}

/// The class Entitlements.swift extends. Only the static rule is under test.
@MainActor final class SubscriptionStore {}
'''

MANIFEST = '''// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NivliLogic",
    targets: [
        .target(name: "Nivli", path: "Sources/Nivli"),
        .testTarget(name: "NivliTests", dependencies: ["Nivli"], path: "Tests/NivliTests"),
    ]
)
'''


def copy_stripped(source: Path, destination: Path) -> None:
    text = source.read_text(encoding="utf-8")
    text = APPLE_ONLY_IMPORTS.sub("", text)
    destination.write_text(text, encoding="utf-8")


def main() -> int:
    keep = "--keep" in sys.argv
    positional = [arg for arg in sys.argv[1:] if not arg.startswith("--")]
    package_dir = Path(positional[0]) if positional else Path(tempfile.mkdtemp(prefix="nivli-logic-"))
    sources = package_dir / "Sources/Nivli"
    tests = package_dir / "Tests/NivliTests"
    if package_dir.exists() and positional:
        shutil.rmtree(package_dir)
    sources.mkdir(parents=True)
    tests.mkdir(parents=True)

    (package_dir / "Package.swift").write_text(MANIFEST, encoding="utf-8")
    (sources / "AppleStubs.swift").write_text(STUBS, encoding="utf-8")
    for relative in SOURCES:
        copy_stripped(ROOT / relative, sources / Path(relative).name)
    for relative in TESTS:
        copy_stripped(ROOT / relative, tests / Path(relative).name)

    print(f"Package: {package_dir}")
    result = subprocess.run(["swift", "test"], cwd=package_dir)
    if not keep and not positional and result.returncode == 0:
        shutil.rmtree(package_dir, ignore_errors=True)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
