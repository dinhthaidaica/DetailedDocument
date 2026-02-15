#!/usr/bin/env bash

set -euo pipefail

APP_NAME="${APP_NAME:-LunarV}"
PROJECT="${PROJECT:-LunarV.xcodeproj}"
SCHEME="${SCHEME:-LunarV}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-build}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
VERSION="${VERSION:-local}"

rm -rf "${DERIVED_DATA_PATH}" "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -sdk macosx \
  -destination "generic/platform=macOS" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
if [[ ! -d "${APP_PATH}" ]]; then
  echo "Could not find built app at: ${APP_PATH}" >&2
  exit 1
fi

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "${STAGING_DIR}"' EXIT

cp -R "${APP_PATH}" "${STAGING_DIR}/${APP_NAME}.app"
ln -s /Applications "${STAGING_DIR}/Applications"

DMG_PATH="${OUTPUT_DIR}/${APP_NAME}-${VERSION}.dmg"
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}" >/dev/null

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "dmg_path=${DMG_PATH}" >> "${GITHUB_OUTPUT}"
fi

echo "Created DMG: ${DMG_PATH}"
