# weavec2 tests

This directory mirrors the current bootstrap fixture sets.

- `wir/` contains WIR inputs copied from `../weavec1/tests/`.
- `surface/` contains surface Weave inputs and expected WIR outputs copied from
  `../weavefront/tests/`.

Run the active backend ladder from the `weavec2` directory:

```bash
./test.sh
```

The current harness tests the `build/weavec2` executable as a WIR to LLVM
compiler, then verifies generated LLVM with `llvm-as`, `clang`, and executable
exit codes. It also runs every currently passing single-file surface fixture
through `--frontend`, `--backend`, LLVM validation, native linking, and runtime
exit-code checks, plus one multi-file frontend check.

Compile-fail WIR fixtures and broader surface fixtures are copied here for the
next frontend and diagnostics steps, but only the known-good subset is enforced
by `test.sh` today. Run `./surface-matrix.sh` to see the full non-fatal surface
compatibility matrix and the phase where each remaining fixture fails.
