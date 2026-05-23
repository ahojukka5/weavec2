#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEAVEC2="$ROOT/build/weavec2"
RUNTIME="$ROOT/../weavec0/runtime.c"
TEST_DIR="$ROOT/tests/wir"
BUILD_DIR="$ROOT/build/tests"
LL_DIR="$BUILD_DIR/ll"
BC_DIR="$BUILD_DIR/bc"
BIN_DIR="$BUILD_DIR/bin"

pass_count=0
fail_count=0

log() {
  printf '[weavec2-test] %s\n' "$*"
}

fail() {
  printf '[weavec2-test] error: %s\n' "$*" >&2
  fail_count=$((fail_count + 1))
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    printf '[weavec2-test] missing required tool: %s\n' "$1" >&2
    exit 1
  }
}

expected_exit() {
  case "$1" in
    01_return_constant) echo 0 ;;
    02_return_42) echo 42 ;;
    03_add) echo 42 ;;
    04_one_arg_function) echo 42 ;;
    05_let_local) echo 42 ;;
    06_set_local) echo 42 ;;
    07_if) echo 42 ;;
    08_while) echo 42 ;;
    09_two_arg_function) echo 42 ;;
    10_string_literal) echo 42 ;;
    11_const_i64) echo 42 ;;
    12_i64_arithmetic) echo 42 ;;
    13_i64_comparisons) echo 42 ;;
    14_bool_ops) echo 42 ;;
    15_ptr_null) echo 42 ;;
    16_extern_malloc_free) echo 42 ;;
    17_ptr_add_store_load_i64) echo 42 ;;
    18_store_load_i8) echo 42 ;;
    19_call_void) echo 42 ;;
    20_call_i64) echo 42 ;;
    21_call_ptr) echo 42 ;;
    22_return_void) echo 42 ;;
    23_mod_i32) echo 2 ;;
    24_buffer_like_smoke) echo 42 ;;
    25_ptr_params_call_i32) echo 42 ;;
    26_bool_return) echo 42 ;;
    27_three_arg_function) echo 42 ;;
    28_i32_memory_and_cast) echo 42 ;;
    29_const_string_ptr) echo 42 ;;
    30_i64_sub_eq) echo 42 ;;
    31_not_bool) echo 42 ;;
    32_codegen_join_and_i64_arg) echo 42 ;;
    33_store_i8_temp) echo 42 ;;
    34_ge_i32) echo 42 ;;
    35_sub_i32) echo 42 ;;
    36_mul_i32) echo 42 ;;
    37_div_i32) echo 42 ;;
    38_i32_comparisons_full) echo 42 ;;
    39_i64_ge_gt) echo 42 ;;
    40_call_bool_direct) echo 42 ;;
    41_load_store_ptr) echo 42 ;;
    42_empty_do) echo 42 ;;
    43_if_fallthrough_join) echo 42 ;;
    44_while_zero_iterations) echo 42 ;;
    45_nested_while) echo 42 ;;
    46_forward_function_call) echo 42 ;;
    47_multiple_externs_used_subset) echo 42 ;;
    48_string_escape) echo 42 ;;
    49_negative_i32_literal) echo 42 ;;
    54_debug_marker) echo 42 ;;
    55_integration_nested_control_flow) echo 75 ;;
    56_integration_multi_function_chain) echo 35 ;;
    57_integration_memory_flow) echo 100 ;;
    *) return 1 ;;
  esac
}

is_positive_wir_test() {
  expected_exit "$1" >/dev/null
}

[[ -x "$WEAVEC2" ]] || {
  printf '[weavec2-test] build/weavec2 not found; run ./build.sh first\n' >&2
  exit 1
}

[[ -f "$RUNTIME" ]] || {
  printf '[weavec2-test] runtime not found: %s\n' "$RUNTIME" >&2
  exit 1
}

require_tool llvm-as
require_tool clang

mkdir -p "$LL_DIR" "$BC_DIR" "$BIN_DIR"

for src in "$TEST_DIR"/*.wir; do
  name="$(basename "$src" .wir)"

  if ! is_positive_wir_test "$name"; then
    log "skip $name"
    continue
  fi

  ll="$LL_DIR/$name.ll"
  bc="$BC_DIR/$name.bc"
  bin="$BIN_DIR/$name"
  expected="$(expected_exit "$name")"

  log "compile $name"

  if ! "$WEAVEC2" "$src" "$ll"; then
    fail "$name: weavec2 failed"
    continue
  fi

  if ! llvm-as "$ll" -o "$bc"; then
    fail "$name: llvm-as failed"
    continue
  fi

  if ! clang "$ll" "$RUNTIME" -o "$bin"; then
    fail "$name: clang failed"
    continue
  fi

  set +e
  "$bin"
  actual="$?"
  set -e

  if [[ "$actual" != "$expected" ]]; then
    fail "$name: expected exit $expected, got $actual"
    continue
  fi

  log "ok $name"
  pass_count=$((pass_count + 1))
done

log "$pass_count passed, $fail_count failed"

if [[ "$fail_count" -ne 0 ]]; then
  exit 1
fi
