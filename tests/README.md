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
exit codes. Compile-fail WIR fixtures and surface fixtures are copied here for
the next frontend and diagnostics steps, but are not enforced by `test.sh` yet.
