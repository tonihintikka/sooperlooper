#!/usr/bin/env bash
# Build and package SooperLooper.app (standalone + GUI, no AU plugin).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAC="${ROOT}/mac"
DIST="${MAC}/macdist"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sooperlooper-app.XXXXXX")"
APP="${WORK}/SooperLooper.app"
FINAL_APP="${DIST}/SooperLooper.app"

cleanup() { rm -rf "${WORK}"; }
trap cleanup EXIT

cd "${ROOT}"

echo "==> build"
"${ROOT}/scripts/build-macos.sh"

VERSION="$(grep sooperlooper_version "${ROOT}/version.h" | sed -n 's/.*"\([^"]*\)".*/\1/p')"
echo "==> package SooperLooper.app (${VERSION}) in ${WORK}"

mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources" "${APP}/Contents/Frameworks"

ditto --norsrc --noextattr --noqtn "${ROOT}/src/sooperlooper" "${APP}/Contents/MacOS/sooperlooper"
ditto --norsrc --noextattr --noqtn "${ROOT}/src/gui/slgui" "${APP}/Contents/MacOS/slgui"

if [[ -f "${MAC}/slgui.icns" ]]; then
  ditto --norsrc --noextattr --noqtn "${MAC}/slgui.icns" "${APP}/Contents/Resources/slgui.icns"
fi

sed -e "s/VVVVV/${VERSION}/g" "${MAC}/Info.plist" > "${APP}/Contents/Info.plist"
echo -n "APPL????" > "${APP}/Contents/PkgInfo"

mkdir -p "${DIST}"
cp "${ROOT}/OSC" "${DIST}/OSC.txt"
cp "${ROOT}/README.md" "${DIST}/README.md"
cp "${ROOT}/COPYING" "${DIST}/COPYING.txt"
cp "${ROOT}/src/slregister" "${DIST}/slregister"
cp "${MAC}/README_AudioUnit64.txt" "${DIST}/" 2>/dev/null || true

if command -v dylibbundler >/dev/null 2>&1; then
  echo "==> bundle dylibs (dylibbundler)"
  for bin in sooperlooper slgui; do
    dylibbundler -od -b -ns -x "${APP}/Contents/MacOS/${bin}" \
      -d "${APP}/Contents/Frameworks/" \
      -p @executable_path/../Frameworks/
  done
else
  echo "error: dylibbundler required (brew install dylibbundler)" >&2
  exit 1
fi

echo "==> ad-hoc codesign (Apple Silicon requires valid signature)"
shopt -s nullglob
for lib in "${APP}"/Contents/Frameworks/*.dylib; do
  codesign --force --sign - "${lib}"
done
codesign --force --sign - "${APP}/Contents/MacOS/sooperlooper"
codesign --force --sign - "${APP}/Contents/MacOS/slgui"
codesign --force --sign - "${APP}"

verify_sign() {
  local target="$1"
  local out
  out="$(codesign -vv --strict "${target}" 2>&1)" || true
  echo "${out}" | grep -q "valid on disk" || {
    echo "error: codesign verification failed for ${target}" >&2
    echo "${out}" >&2
    exit 1
  }
}

verify_sign "${APP}/Contents/MacOS/slgui"
echo "PASS: codesign ok in temp dir"

echo "==> install to ${FINAL_APP}"
rm -rf "${FINAL_APP}"
ditto --norsrc --noextattr --noqtn "${APP}" "${FINAL_APP}"

verify_sign "${FINAL_APP}/Contents/MacOS/slgui"
echo "PASS: codesign ok after install"

echo ""
echo "Package ready:"
echo "  ${FINAL_APP}"
echo ""
echo "Try:"
echo "  open \"${FINAL_APP}\""
echo ""
echo "Note: start JACK first (jackd -d coreaudio or qjackctl)."
