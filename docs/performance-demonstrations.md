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
| 0153–9999 | Next free ids for new demonstrations |

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

Gaps in the low range (e.g. no `0006`) are historical; new smoke tests
should use the next free id in the appropriate band.

## Workflow for a new demonstration

1. Pick a classical problem or micro-benchmark (sort, search, GCD, sieve,
   numeric kernel, etc.).
2. Implement it in `test/performance/wir/NNNN_name.wir` (Core WIR, i32
   unless you need pointers/arrays).
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
