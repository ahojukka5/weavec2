#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Quantum surface tests: WIR goldens (nativization/) and expect-fail validation/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WEAVEC2="$ROOT/build/weavec2"
FIXTURE_ROOT="$ROOT/test/quantum"
OUT_DIR="$ROOT/build/test/quantum"
pass_count=0
fail_count=0

log() {
  printf '[weavec2-quantum] %s\n' "$*"
}

fail() {
  printf '[weavec2-quantum] error: %s\n' "$*" >&2
  fail_count=$((fail_count + 1))
}

normalize_wir() {
  tr '\n\t\r' ' ' < "$1" |
    sed -E 's/[[:space:]]+/ /g; s/\( /(/g; s/ \)/)/g; s/^ //; s/ $//'
}

[[ -x "$WEAVEC2" ]] || {
  printf '[weavec2-quantum] build/weavec2 not found; run ./build.sh first\n' >&2
  exit 1
}

mkdir -p "$OUT_DIR"

# WIR golden tests (nativization/ only).
while IFS= read -r -d '' src; do
  dir="$(dirname "$src")"
  base="$(basename "$src" .weave)"
  rel="${dir#$FIXTURE_ROOT/}"
  expected="$dir/$base.expected.wir"
  wir="$OUT_DIR/${rel//\//-}-$base.wir"

  log "golden $rel/$base"

  if [[ ! -f "$expected" ]]; then
    fail "$rel/$base: missing $expected"
    continue
  fi

  if ! "$WEAVEC2" --frontend "$wir" "$src"; then
    fail "$rel/$base: frontend failed"
    continue
  fi

  if ! diff -u <(normalize_wir "$expected") <(normalize_wir "$wir"); then
    fail "$rel/$base: WIR golden mismatch"
    continue
  fi

  pass_count=$((pass_count + 1))
done < <(find "$FIXTURE_ROOT/nativization" -name '*.weave' -print0)

# Validation fixtures must fail the frontend before WIR is written.
while IFS= read -r -d '' src; do
  dir="$(dirname "$src")"
  base="$(basename "$src" .weave)"
  rel="${dir#$FIXTURE_ROOT/}"
  wir="$OUT_DIR/${rel//\//-}-$base-should-fail.wir"

  log "reject $rel/$base"

  if "$WEAVEC2" --frontend "$wir" "$src"; then
    fail "$rel/$base: expected frontend failure, got success"
    continue
  fi

  pass_count=$((pass_count + 1))
done < <(find "$FIXTURE_ROOT/validation" -name '*.weave' -print0)

log "passed $pass_count"
if [[ "$fail_count" -gt 0 ]]; then
  log "failed $fail_count"
  exit 1
fi
