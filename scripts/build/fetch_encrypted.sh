#!/usr/bin/env bash
# Downloads a prebuilt app kept encrypted as an asset of this repo's "private-apps" release
# and decrypts it with the APP_FILE_PASSPHRASE secret. For android_build / ios_build:
#   android_build: bash $GITHUB_WORKSPACE/scripts/build/fetch_encrypted.sh speedwallet-dev.apk.enc $GITHUB_WORKSPACE/prebuilt.apk
#   apk_path:      /home/runner/work/my-testers/my-testers/prebuilt.apk   (or any absolute path matching the output)
# A .zip/.tgz output (an iOS Simulator .app) is unpacked next to it.
# Encrypt locally with: openssl enc -aes-256-cbc -pbkdf2 -salt -in app.apk -out app.apk.enc -pass file:<passphrase file>
set -euo pipefail
ASSET=${1:?asset name}; OUT=${2:?output path}; TAG=${3:-private-apps}
: "${APP_FILE_PASSPHRASE:?APP_FILE_PASSPHRASE secret is not set}"
URL="https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAG}/${ASSET}"
TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
curl -fsSL --retry 3 -o "$TMP" "$URL"
mkdir -p "$(dirname "$OUT")"
openssl enc -d -aes-256-cbc -pbkdf2 -in "$TMP" -out "$OUT" -pass env:APP_FILE_PASSPHRASE
case "$OUT" in
  # python's zipfile reads UTF-8 file names correctly; macOS unzip 6.0 does not
  *.zip) python3 -c 'import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$OUT" "$(dirname "$OUT")" ;;
  *.tgz|*.tar.gz) tar -xzf "$OUT" -C "$(dirname "$OUT")" ;;
esac
echo "Decrypted $ASSET"
