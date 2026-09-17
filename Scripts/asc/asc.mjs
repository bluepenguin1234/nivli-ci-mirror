// A small App Store Connect API client. No dependencies beyond Node 18+.
//
// Usage:
//   node Scripts/asc/asc.mjs <method> <path> [json-body]
//   node Scripts/asc/asc.mjs GET /v1/apps
//   node Scripts/asc/asc.mjs PATCH /v1/subscriptionLocalizations/ID '{"data":{...}}'
//
// Configuration comes from the environment, never from the repository:
//   ASC_KEY_PATH   path to the AuthKey_XXXX.p8 file (App Store Connect API key)
//   ASC_KEY_ID     the key ID (the XXXX in the filename)
//   ASC_ISSUER_ID  the Issuer ID shown on App Store Connect → Users and Access → Integrations
//
// The key file is read to sign a 15-minute token; its contents are never printed.
import { createSign } from "node:crypto";
import { readFileSync } from "node:fs";

const keyPath = process.env.ASC_KEY_PATH;
const keyId = process.env.ASC_KEY_ID;
const issuerId = process.env.ASC_ISSUER_ID;
if (!keyPath || !keyId || !issuerId) {
  console.error("Set ASC_KEY_PATH, ASC_KEY_ID and ASC_ISSUER_ID.");
  process.exit(2);
}

const b64 = (value) => Buffer.from(JSON.stringify(value)).toString("base64url");

export function token() {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "ES256", kid: keyId, typ: "JWT" };
  const payload = { iss: issuerId, iat: now, exp: now + 15 * 60, aud: "appstoreconnect-v1" };
  const unsigned = `${b64(header)}.${b64(payload)}`;
  const signer = createSign("SHA256");
  signer.update(unsigned);
  const signature = signer.sign({ key: readFileSync(keyPath, "utf8"), dsaEncoding: "ieee-p1363" });
  return `${unsigned}.${signature.toString("base64url")}`;
}

export async function asc(method, path, body) {
  const url = path.startsWith("http") ? path : `https://api.appstoreconnect.apple.com${path}`;
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token()}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  if (!response.ok) {
    const error = new Error(`${method} ${path} → ${response.status}`);
    error.status = response.status;
    error.data = data;
    throw error;
  }
  return data;
}

if (process.argv[1] && process.argv[1].endsWith("asc.mjs") && process.argv.length > 3) {
  const [, , method, path, json] = process.argv;
  asc(method.toUpperCase(), path, json ? JSON.parse(json) : undefined)
    .then((data) => console.log(JSON.stringify(data, null, 2)))
    .catch((error) => {
      console.error(error.message);
      if (error.data) console.error(JSON.stringify(error.data, null, 2));
      process.exit(1);
    });
}
