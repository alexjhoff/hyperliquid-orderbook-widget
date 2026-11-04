#!/usr/bin/env bash
# Archives a Release build and uploads it to App Store Connect for TestFlight.
#
# Prerequisites (one time):
#   1. Xcode > Settings > Accounts: signed in with the paid Apple Developer account,
#      or set ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH to use an App Store Connect API key.
#   2. echo 'DEVELOPMENT_TEAM = <TEAM_ID>' > Config/Local.xcconfig
#   3. An App Store Connect app record for bundle id com.alexhoff.OrderBookWidgetDemo.
#
# Usage: Scripts/archive.sh
# BUILD_NUMBER defaults to the UTC time, which always increases.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: uncommitted changes; a build should match a commit." >&2
  exit 1
fi
if ! grep -qs '^DEVELOPMENT_TEAM *= *[^ ]' Config/Local.xcconfig; then
  echo "error: set DEVELOPMENT_TEAM in Config/Local.xcconfig (see the top of this script)." >&2
  exit 1
fi

auth=()
if [[ -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" && -n "${ASC_KEY_PATH:-}" ]]; then
  auth=(-authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID" -authenticationKeyPath "$ASC_KEY_PATH")
fi

BUILD_NUMBER="${BUILD_NUMBER:-$(date -u +%Y%m%d%H%M)}"
ARCHIVE="build/OrderBookDemo-$BUILD_NUMBER.xcarchive"

xcodebuild archive -quiet \
  -project OrderBookDemo.xcodeproj -scheme OrderBookDemo -configuration Release \
  -destination "generic/platform=iOS" -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates ${auth[@]+"${auth[@]}"} \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER"

xcodebuild -exportArchive -quiet \
  -archivePath "$ARCHIVE" -exportOptionsPlist Scripts/ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates ${auth[@]+"${auth[@]}"}

echo "Uploaded build $BUILD_NUMBER from $(git rev-parse --short HEAD). It appears in TestFlight after processing."
