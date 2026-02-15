#!/usr/bin/env bash

set -euo pipefail

APP_NAME="${APP_NAME:-LunarV}"
PROJECT="${PROJECT:-LunarV.xcodeproj}"
SCHEME="${SCHEME:-LunarV}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-build}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
VERSION="${VERSION:-local}"
XCODEBUILD_LOG="${XCODEBUILD_LOG:-build.log}"
XCODEBUILD_MAX_ATTEMPTS="${XCODEBUILD_MAX_ATTEMPTS:-2}"

rm -rf "${DERIVED_DATA_PATH}" "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

: > "${XCODEBUILD_LOG}"

run_xcodebuild() {
  local attempt="$1"
  echo "== xcodebuild attempt ${attempt}/${XCODEBUILD_MAX_ATTEMPTS} ==" | tee -a "${XCODEBUILD_LOG}"

  xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -sdk macosx \
    -destination "generic/platform=macOS" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    clean build 2>&1 | tee -a "${XCODEBUILD_LOG}"
}

attempt=1
while true; do
  if run_xcodebuild "${attempt}"; then
    break
  fi

  if (( attempt >= XCODEBUILD_MAX_ATTEMPTS )); then
    echo "xcodebuild failed after ${attempt} attempt(s)." >&2
    exit 1
  fi

  attempt=$((attempt + 1))
  echo "xcodebuild failed, retrying in 5 seconds..." | tee -a "${XCODEBUILD_LOG}"
  sleep 5
done

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
  -imagekey zlib-level=9 \
  "${DMG_PATH}" >/dev/null

DMG_SIZE="$(stat -f%z "${DMG_PATH}")"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "dmg_path=${DMG_PATH}" >> "${GITHUB_OUTPUT}"
  echo "dmg_name=$(basename "${DMG_PATH}")" >> "${GITHUB_OUTPUT}"
  echo "dmg_size=${DMG_SIZE}" >> "${GITHUB_OUTPUT}"
  echo "build_log=${XCODEBUILD_LOG}" >> "${GITHUB_OUTPUT}"
fi

echo "Created DMG: ${DMG_PATH} (${DMG_SIZE} bytes)"
