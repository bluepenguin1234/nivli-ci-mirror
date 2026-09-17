#!/usr/bin/env python3
"""Read APP_STORE_CONNECT_PRIVATE_KEY from the environment and print it as a clean PEM.

Owners paste the .p8 by hand; this accepts Windows line endings, surrounding quotes, and a
paste where the line breaks were lost, and exits 1 if the value is not a private key at all.
Never prints anything but the key itself, so it can be captured with $(...)."""
import os
import re
import sys

raw = os.environ.get("APP_STORE_CONNECT_PRIVATE_KEY", "")
text = raw.replace("\r", "").strip().strip('"').strip("'")
match = re.search(r"-----BEGIN ([A-Z ]*PRIVATE KEY)-----(.*?)-----END \1-----", text, re.S)
if not match:
    sys.exit(1)
label = match.group(1)
body = re.sub(r"\s+", "", match.group(2))
if len(body) < 100 or not re.fullmatch(r"[A-Za-z0-9+/=]+", body):
    sys.exit(1)
lines = [body[i:i + 64] for i in range(0, len(body), 64)]
print("-----BEGIN %s-----\n%s\n-----END %s-----" % (label, "\n".join(lines), label))
