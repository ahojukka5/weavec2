#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WEAVEC2="$ROOT/build/weavec2"
WIR="$ROOT/build/weavec2.wir"
OUT_LL="$ROOT/build/test/selfhost/weavec2.ll"
OUT_BC="$ROOT/build/test/selfhost/weavec2.bc"

log() {
  printf '[weavec2-selfhost] %s\n' "$*"
}

fail() {
  printf '[weavec2-selfhost] error: %s\n' "$*" >&2
  exit 1
}

command -v llvm-as >/dev/null 2>&1 || fail 'missing llvm-as'

[[ -x "$WEAVEC2" ]] || fail 'build/weavec2 not found; run ./build.sh first'
[[ -f "$WIR" ]] || fail 'build/weavec2.wir not found; run ./build.sh first'

mkdir -p "$(dirname "$OUT_LL")"

log "compile $WIR"
"$WEAVEC2" "$WIR" "$OUT_LL" || fail 'weavec2 failed on self-host WIR'

log "llvm-as"
llvm-as "$OUT_LL" -o "$OUT_BC" || fail 'llvm-as failed on self-host LLVM'

if command -v opt >/dev/null 2>&1; then
  OPT_BC="$ROOT/build/test/selfhost/weavec2-mem2reg.bc"
  log "opt -passes=mem2reg"
  opt -passes=mem2reg -disable-output "$OUT_BC" -o "$OPT_BC" || fail 'opt -mem2reg failed'
fi

log 'ok self-host LLVM verifies'
