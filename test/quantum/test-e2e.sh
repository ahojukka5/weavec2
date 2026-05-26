#!/usr/bin/env bash
# Quantum end-to-end: surface .weave -> WIR -> LLVM -> clang + quantum_runtime.c -> run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WEAVEC2="$ROOT/build/weavec2"
RUNTIME="$ROOT/runtime/quantum_runtime.c"
FIXTURE_ROOT="$ROOT/test/quantum/e2e"
OUT_DIR="$ROOT/build/test/quantum-e2e"
pass_count=0
fail_count=0

log() {
  printf '[weavec2-quantum-e2e] %s\n' "$*"
}

fail() {
  printf '[weavec2-quantum-e2e] error: %s\n' "$*" >&2
  fail_count=$((fail_count + 1))
}

[[ -x "$WEAVEC2" ]] || {
  printf '[weavec2-quantum-e2e] build/weavec2 not found; run ./build.sh first\n' >&2
  exit 1
}
[[ -f "$RUNTIME" ]] || {
  printf '[weavec2-quantum-e2e] missing %s\n' "$RUNTIME" >&2
  exit 1
}

mkdir -p "$OUT_DIR"

while IFS= read -r -d '' src; do
  base="$(basename "$src" .weave)"
  wir="$OUT_DIR/$base.wir"
  ll="$OUT_DIR/$base.ll"
  exe="$OUT_DIR/$base"

  log "e2e $base"

  if ! "$WEAVEC2" --frontend "$wir" "$src"; then
    fail "$base: frontend failed"
    continue
  fi
  if ! "$WEAVEC2" --backend "$wir" "$ll"; then
    fail "$base: backend failed"
    continue
  fi
  if ! clang -Wno-override-module "$ll" "$RUNTIME" -o "$exe"; then
    fail "$base: clang link failed"
    continue
  fi
  set +e
  "$exe"
  status=$?
  set -e
  if [[ "$status" != "42" ]]; then
    fail "$base: expected exit 42, got $status"
    continue
  fi

  pass_count=$((pass_count + 1))
done < <(find "$FIXTURE_ROOT" -name '*.weave' -print0)

log "passed $pass_count"
if [[ "$fail_count" -gt 0 ]]; then
  log "failed $fail_count"
  exit 1
fi
exit 0
