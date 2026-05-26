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
| 0081–0130 | Hand-written algorithm demos (ongoing) |
| 0131–9999 | Next free ids for new demonstrations |

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
