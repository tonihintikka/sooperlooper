#!/usr/bin/env bash
# Build SooperLooper on macOS with Homebrew dependencies.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"

export PKG_CONFIG_PATH="${BREW_PREFIX}/lib/pkgconfig:\
${BREW_PREFIX}/opt/libsigc++@2/lib/pkgconfig:\
${BREW_PREFIX}/opt/libxml2/lib/pkgconfig:\
${BREW_PREFIX}/opt/ncurses/lib/pkgconfig"

JOBS="${JOBS:-$(sysctl -n hw.ncpu)}"
PREFIX="${PREFIX:-${BREW_PREFIX}}"
WX_CONFIG="${WX_CONFIG:-${BREW_PREFIX}/bin/wx-config}"

echo "==> SooperLooper macOS build"
echo "    root:   ${ROOT}"
echo "    prefix: ${PREFIX}"
echo "    jobs:   ${JOBS}"

for cmd in brew pkg-config autoconf automake; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: '${cmd}' not found" >&2
    exit 1
  fi
done

if [[ ! -x ./autogen.sh ]]; then
  echo "error: ./autogen.sh not found" >&2
  exit 1
fi

if ! "${WX_CONFIG}" --version >/dev/null 2>&1; then
  echo "error: wx-config not found at ${WX_CONFIG}" >&2
  echo "Install: brew install wxwidgets" >&2
  exit 1
fi

if [[ ! -f configure ]]; then
  echo "==> ./autogen.sh"
  ./autogen.sh
fi

echo "==> ./configure"
./configure --prefix="${PREFIX}" --with-wxconfig-path="${WX_CONFIG}"

echo "==> make -j${JOBS}"
make -j"${JOBS}"

echo "==> smoke tests"
"${ROOT}/scripts/test-macos.sh"

echo ""
echo "Build OK:"
echo "  ${ROOT}/src/sooperlooper"
echo "  ${ROOT}/src/gui/slgui"
echo ""
echo "Start JACK:  jackd -d coreaudio"
echo "Run engine:  ${ROOT}/src/sooperlooper"
echo "Run GUI:     ${ROOT}/src/gui/slgui"
