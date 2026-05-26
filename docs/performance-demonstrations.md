# Performance demonstrations (weavec2)

Each fixture under `test/performance/` is a small WIR program whose LLVM
output is checked into `expected-llvm/`. The four-digit id leaves room to
add many more benchmarks without renaming.

## Naming

```
NNNN_short_descriptive_name.wir
NNNN_short_descriptive_name.ll   # golden LLVM
```

- `NNNN`: four-digit decimal id, zero-padded (`0001` … `9999`).
- `short_descriptive_name`: kebab-case topic (`binary_search_i32`,
  `factorial_iter_i32`).

Examples:

| Id | File | Purpose |
|----|------|---------|
| 0001 | `0001_return_constant.wir` | Minimal return |
| 0008 | `0008_while.wir` | Loop lowering smoke |
| 0061 | `0061_fibonacci_iterative.wir` | Classical iterative algorithm |
| 0073 | `0073_factorial_iter_i32.wir` | Iterative factorial |

## Id ranges (convention)

| Range | Kind |
|-------|------|
| 0001–0059 | Language and codegen smoke (ops, control flow, calls) |
| 0054–0060 | Integration-style WIR (nested control, memory flow) |
| 0061–0080 | Classical algorithms and small benchmarks |
| 0081–0130 | Hand-written algorithm demos |
| 0131–0152 | Hard stress demos (nested if/loop phis, DP, grids, sorts) |
| 0139 | Reserved (twin parallel if ladders; needs extra phi pred fix) |
| 0153–0164 | i64 arithmetic and heap demos (see below) |
| 0165–9999 | Next free ids for new demonstrations |

Hard batch (0131–0140, except 0139):

| Id | Fixture | Stress target |
|----|---------|----------------|
| 0131 | `0131_loop_triple_if_carried_i32` | 3-deep nested if, 3 carried locals |
| 0132 | `0132_matmul3x3_i32` | Triple nested loop, heap 2D |
| 0133 | `0133_sieve48_i32` | Sieve, nested marking loop |
| 0134 | `0134_floyd_warshall4_i32` | Floyd–Warshall 4 nodes |
| 0135 | `0135_bubble_sort8_i32` | Bubble sort n=8 |
| 0136 | `0136_knapsack01_i32` | 0/1 knapsack DP table |
| 0137 | `0137_mandelbrot_grid6_sum_i32` | 6x6 Mandelbrot sum |
| 0138 | `0138_mod_div_nested_accum_i32` | mod/div in nested branches |
| 0140 | `0140_selection_sort8_i32` | Selection sort n=8 |

Second hard batch (0141–0152):

| Id | Fixture | Stress target |
|----|---------|----------------|
| 0141 | `0141_lcs_table_i32` | LCS DP 9x9 table |
| 0142 | `0142_heap_sift_down4_i32` | Heap sift-down |
| 0143 | `0143_rolling_hash_i32` | Rolling hash 64 bytes |
| 0144 | `0144_matmul4x4_i32` | 4x4 matrix multiply |
| 0145 | `0145_insertion_sort10_i32` | Insertion sort n=10 |
| 0146 | `0146_collatz_stats_i32` | Collatz max/sum batch |
| 0147 | `0147_partition_dutch12_i32` | Dutch-flag partition |
| 0148 | `0148_gcd_batch_i32` | Batch Euclidean GCD |
| 0149 | `0149_binary_search_batch16_i32` | Repeated binary search |
| 0150 | `0150_edit_distance6_i32` | Levenshtein DP 7x7 |
| 0151 | `0151_counting_sort12_i32` | Counting sort n=12 |
| 0152 | `0152_merge_sorted_halves8_i32` | Merge 4+4 sorted halves |

i64 batch (0153–0161):

| Id | Fixture | Stress target |
|----|---------|----------------|
| 0153 | `0153_sum_range_i64` | Sum 1..120, i64 accumulator |
| 0154 | `0154_factorial20_i64` | 20! mod 1e9+7, i64 multiply loop |
| 0155 | `0155_dot_product8_i64` | Dot product, `array_i64_at` / heap |
| 0156 | `0156_gcd_i64` | Euclidean GCD on i64 |
| 0157 | `0157_array_max8_i64` | Max of 8 i64 values |
| 0158 | `0158_fibonacci30_i64` | Fibonacci F(30), i64 add/mod |
| 0159 | `0159_power_mod_i64` | Modular exponentiation i64 |
| 0160 | `0160_fixed_point_mean_i64` | Scaled mean (fixed-point proxy for float) |
| 0161 | `0161_collatz_peak_i64` | Collatz peak tracking on i64 |
| 0162 | `0162_bitwise_mix_i64` | xor/and/shl/shr mix in loop |
| 0163 | `0163_horner_poly_i64` | Horner polynomial evaluation |
| 0164 | `0164_matmul2x2_i64` | 2x2 matrix multiply on heap |

Loop-phi promotion in weavec2 is i32-only today; i64 locals in loops use
stack slots. Floating-point (`f32`/`f64`) is not in the weavec2 emitter
yet—add `types`/`expr` support first, then fixtures in the 0165+ band.

GPU-oriented codegen is out of scope for this suite for now; these fixtures
stay CPU-focused while we broaden type and control-flow coverage.

Gaps in the low range (e.g. no `0006`) are historical; new smoke tests
should use the next free id in the appropriate band.

## Workflow for a new demonstration

1. Pick a classical problem or micro-benchmark (sort, search, GCD, sieve,
   numeric kernel, etc.).
2. Implement it in `test/performance/wir/NNNN_name.wir` (Core WIR; i32 is
   the default for loop-carried locals, i64 for wide arithmetic, pointers
   for heap arrays).
3. Run `./build.sh`, then generate and verify LLVM:

   ```bash
   ./test/performance/regen-golden.sh NNNN_name
   ```

   `regen-golden.sh` runs `weavec2`, checks `llvm-as`, and copies the
   `.ll` into `expected-llvm/`.
4. Run `./test/performance/test.sh` (or `./test-all.sh`).
5. Review the golden IR: structure, redundant loads, branch layout. That
   is the baseline before discussing weavec2 or LLVM optimizations.

## Commands

```bash
./test/performance/test.sh                    # all goldens
./test/performance/regen-golden.sh          # refresh all
./test/performance/regen-golden.sh 0073_factorial_iter_i32
```

Performance tests also run `opt -passes=mem2reg` when `opt` is on `PATH`.
