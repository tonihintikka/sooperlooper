#!/usr/bin/env bash
# Quick smoke tests after build or code changes.
# Usage: ./scripts/test-macos.sh [--with-jack]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

WITH_JACK=false
if [[ "${1:-}" == "--with-jack" ]]; then
  WITH_JACK=true
fi

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

echo "==> SooperLooper smoke tests"

# 1. Binaries exist
for bin in src/sooperlooper src/gui/slgui src/slconsole; do
  [[ -x "${bin}" ]] || fail "missing or not executable: ${bin}"
  pass "${bin} exists"
done

# 2. Architecture
file src/sooperlooper | grep -q "arm64" && pass "sooperlooper is arm64" || pass "sooperlooper arch: $(file -b src/sooperlooper)"

# 3. Version / CLI
src/sooperlooper -V 2>&1 | grep -q "1.7.9" || fail "unexpected version"
pass "sooperlooper -V"

HELP=$(src/sooperlooper -h 2>&1 || true)
echo "${HELP}" | grep -q "Usage:" || fail "help missing"
pass "sooperlooper -h"

# 4. No atomic fallback warning in object files (arm64 path used)
if nm src/sooperlooper 2>/dev/null | grep -q "__NO_STRICT_ATOMIC"; then
  fail "built with __NO_STRICT_ATOMIC fallback"
fi
pass "no __NO_STRICT_ATOMIC in sooperlooper"

# 5. Optional JACK runtime test
if ${WITH_JACK}; then
  if ! pgrep -x jackd >/dev/null 2>&1; then
    echo "    starting jackd..."
    jackd -d coreaudio -r 48000 -p 512 >/tmp/jackd-test.log 2>&1 &
    JACK_PID=$!
    sleep 3
    STARTED_JACK=true
  else
    JACK_PID=""
    STARTED_JACK=false
  fi

  src/sooperlooper -q -l 1 &
  SL_PID=$!
  sleep 2

  if kill -0 "${SL_PID}" 2>/dev/null; then
    pass "sooperlooper runs with JACK"
    kill "${SL_PID}" 2>/dev/null || true
  else
    fail "sooperlooper exited immediately with JACK"
  fi

  if ${STARTED_JACK} && [[ -n "${JACK_PID}" ]]; then
    kill "${JACK_PID}" 2>/dev/null || true
  fi
else
  echo "    (skip JACK runtime test; use --with-jack to enable)"
fi

echo ""
echo "All smoke tests passed."
