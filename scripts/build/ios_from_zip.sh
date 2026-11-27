#!/usr/bin/env bash
# iOS Simulator build from an encrypted source zip kept in the "private-apps" release.
# For ios_build (ios_app_path must point at the output: <workspace>/prebuilt-ios/App.app):
#   bash "$GITHUB_WORKSPACE/scripts/build/ios_from_zip.sh" <asset.zip.enc> "<scheme>" [configuration]
# The zip holds one folder with the .xcodeproj / .xcworkspace in it (Swift packages are resolved here).
set -euo pipefail
ASSET=${1:?asset}; SCHEME=${2:?scheme}; CONF=${3:-Debug}
W=${GITHUB_WORKSPACE:?}; SRC="$W/src-zip"; OUT="$W/prebuilt-ios"
bash "$W/scripts/build/fetch_encrypted.sh" "$ASSET" "$SRC/source.zip"
rm -f "$SRC/source.zip"
P=$(find "$SRC" -maxdepth 3 -name '*.xcworkspace' -not -path '*.xcodeproj/*' -not -path '*/Pods/*' | head -1)
if [ -n "$P" ]; then K=-workspace; else P=$(find "$SRC" -maxdepth 3 -name '*.xcodeproj' | head -1); K=-project; fi
[ -n "$P" ] || { echo "No Xcode project in the zip"; exit 1; }
D=$(dirname "$P"); [ -f "$D/Podfile" ] && (cd "$D" && pod install)
echo "Building $SCHEME ($CONF) from $(basename "$P")"
xcodebuild $K "$P" -scheme "$SCHEME" -configuration "$CONF" -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$RUNNER_TEMP/dd" \
  -skipPackagePluginValidation -skipMacroValidation \
  EXCLUDED_ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
APP=$(find "$RUNNER_TEMP/dd/Build/Products" -maxdepth 2 -path '*iphonesimulator/*.app' -not -name '*Tests*' | head -1)
[ -n "$APP" ] || { echo "No Simulator .app built"; exit 1; }
rm -rf "$OUT"; mkdir -p "$OUT"; cp -R "$APP" "$OUT/App.app"
echo "Built $(basename "$APP")"
