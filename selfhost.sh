#!/usr/bin/env bash
# Build weavec2 with weavec2 itself.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED="$ROOT/build/weavec2"
BUILD_DIR="$ROOT/build/selfhost"

log() { printf '[weavec2-selfhost] %s\n' "$*"; }
fail() { printf '[weavec2-selfhost] error: %s\n' "$*" >&2; exit 1; }

require_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required tool: $1"
}

[[ -x "$SEED" ]] || fail "seed compiler not found at $SEED; run ./build.sh first"
require_tool llvm-link
require_tool clang

chmod -R u+rw "$BUILD_DIR" 2>/dev/null || true

SOURCES=(
  "$ROOT/src/core/extern.weave"
  "$ROOT/src/core/io.weave"
  "$ROOT/src/core/util.weave"
  "$ROOT/src/frontend/emit.weave"
  "$ROOT/src/frontend/struct.weave"
  "$ROOT/src/frontend/lower.weave"
  "$ROOT/src/frontend/driver.weave"
  "$ROOT/src/llvm/ctx.weave"
  "$ROOT/src/llvm/types.weave"
  "$ROOT/src/llvm/locals.weave"
  "$ROOT/src/llvm/strings.weave"
  "$ROOT/src/llvm/expr.weave"
  "$ROOT/src/llvm/stmt.weave"
  "$ROOT/src/llvm/fn.weave"
  "$ROOT/src/llvm/module.weave"
  "$ROOT/src/main.weave"
)

RUNTIME_MODULES=(
  sexpr_tokens
  sexpr_tree
  sexpr_lexer
  sexpr_parser
)

build_stage() {
  local compiler="$1"
  local out_dir="$2"
  local out_bin="$out_dir/weavec2"

  mkdir -p "$out_dir"

  log "frontend $out_dir/weavec2.wir"
  "$compiler" --frontend "$out_dir/weavec2.wir" "${SOURCES[@]}"

  log "backend $out_dir/weavec2.ll"
  "$compiler" --backend "$out_dir/weavec2.wir" "$out_dir/weavec2.ll"

  local runtime_ll=()
  local mod
  for mod in "${RUNTIME_MODULES[@]}"; do
    log "runtime $mod"
    "$compiler" --backend \
      "$ROOT/src/runtime-wir/$mod.wir" \
      "$out_dir/$mod.ll"
    runtime_ll+=("$out_dir/$mod.ll")
  done

  log "link $out_dir/weavec2.bc"
  llvm-link "$out_dir/weavec2.ll" "${runtime_ll[@]}" -o "$out_dir/weavec2.bc"

  log "clang $out_bin"
  clang "$out_dir/weavec2.bc" -o "$out_bin"
}

build_stage "$SEED" "$BUILD_DIR/stage1"
build_stage "$BUILD_DIR/stage1/weavec2" "$BUILD_DIR/stage2"

log "complete: $BUILD_DIR/stage2/weavec2"
