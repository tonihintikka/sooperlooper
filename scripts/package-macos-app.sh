#!/usr/bin/env bash
# Build and package SooperLooper.app (standalone + GUI, no AU plugin).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAC="${ROOT}/mac"
DIST="${MAC}/macdist"
APP="${DIST}/SooperLooper.app"

cd "${ROOT}"

echo "==> build"
"${ROOT}/scripts/build-macos.sh"

VERSION="$(grep const version.h | awk '{print $7}' | tr -d '";')"
echo "==> package SooperLooper.app (${VERSION})"

rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources" "${APP}/Contents/Frameworks"

cp "${ROOT}/src/sooperlooper" "${APP}/Contents/MacOS/"
cp "${ROOT}/src/gui/slgui" "${APP}/Contents/MacOS/"
xattr -cr "${APP}/Contents/MacOS/" 2>/dev/null || true

if [[ -f "${MAC}/slgui.icns" ]]; then
  cp "${MAC}/slgui.icns" "${APP}/Contents/Resources/"
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
  xattr -cr "${APP}" 2>/dev/null || true
else
  echo "==> skip dylibbundler (not installed)"
  echo "    App may need Homebrew libs in PATH when launched from Finder."
  echo "    Install: brew install dylibbundler"
fi

echo ""
echo "Package ready:"
echo "  ${APP}"
echo ""
echo "Try:"
echo "  open \"${APP}\""
echo ""
echo "Note: start JACK first (jackd -d coreaudio or qjackctl)."
