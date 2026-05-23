#!/usr/bin/env bash
# Build weavec2 — the Weave compiler written in surface Weave.
#
# Prerequisites: weavefront and weavec1 already built.
#
# Strategy:
#   1. Concatenate src/**/*.weave → combined.wir (using weavefront-cat.sh)
#   2. Compile combined.wir → .ll              (using weavec1)
#   3. llvm-link .ll + weavefront runtime modules → .bc
#   4. clang .bc + runtime.c → weavec2 binary

set -euo pipefail

WF="../weavefront"
WEAVEFRONT="$WF/build/weavefront"
WEAVEC1="../weavec1/build/weavec1"
RUNTIME="../weavec0/runtime.c"
WF_BUILD="$WF/build"
BUILD_DIR="build"

log() { echo "[weavec2] $*"; }
fail() { echo "[weavec2] ERROR: $*" >&2; exit 1; }

[[ -x "$WEAVEFRONT" ]] || fail "weavefront not found at $WEAVEFRONT"
[[ -x "$WEAVEC1"    ]] || fail "weavec1 not found at $WEAVEC1"
[[ -f "$RUNTIME"    ]] || fail "runtime.c not found at $RUNTIME"

for mod in sexpr_tokens.ll sexpr_tree.ll sexpr_lexer.ll sexpr_parser.ll; do
  [[ -f "$WF_BUILD/$mod" ]] || fail "weavefront runtime module missing: $WF_BUILD/$mod"
done

mkdir -p "$BUILD_DIR"

FILES=(
  # core: C runtime interface, I/O helpers, tree utilities
  src/core/extern.weave
  src/core/io.weave
  src/core/util.weave
  # frontend: surface Weave → WIR lowering
  src/frontend/emit.weave
  src/frontend/struct.weave
  src/frontend/lower.weave
  src/frontend/driver.weave
  # llvm: WIR → LLVM IR backend
  src/llvm/ctx.weave
  src/llvm/types.weave
  src/llvm/locals.weave
  src/llvm/strings.weave
  src/llvm/expr.weave
  src/llvm/stmt.weave
  src/llvm/fn.weave
  src/llvm/module.weave
  # entry point
  src/main.weave
)

# Step 1: concatenate .weave files
log "Concatenating source files..."
WEAVEFRONT="$WEAVEFRONT" "$WF/weavefront-cat.sh" \
  "$BUILD_DIR/weavec2.wir" "${FILES[@]}" \
  || fail "weavefront-cat.sh failed"
chmod u+rw "$BUILD_DIR/weavec2.wir" 2>/dev/null || true

# Step 2: compile .wir → .ll
log "Compiling WIR → LLVM IR..."
"$WEAVEC1" "$BUILD_DIR/weavec2.wir" "$BUILD_DIR/weavec2.ll" \
  || fail "weavec1 failed to compile weavec2.wir"

# Step 3: link with weavefront runtime modules
log "Linking LLVM modules..."
llvm-link \
  "$BUILD_DIR/weavec2.ll" \
  "$WF_BUILD/sexpr_tokens.ll" \
  "$WF_BUILD/sexpr_tree.ll" \
  "$WF_BUILD/sexpr_lexer.ll" \
  "$WF_BUILD/sexpr_parser.ll" \
  -o "$BUILD_DIR/weavec2.bc" \
  || fail "llvm-link failed"

# Step 4: compile to executable
log "Compiling to executable..."
clang "$BUILD_DIR/weavec2.bc" "$RUNTIME" -o "$BUILD_DIR/weavec2" \
  || fail "clang failed"

log "Build complete: $BUILD_DIR/weavec2"
