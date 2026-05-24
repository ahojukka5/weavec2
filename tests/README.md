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
exit codes. It also runs every copied single-file surface fixture through
`--frontend`, `--backend`, LLVM validation, native linking, and runtime
exit-code checks, plus one multi-file frontend check.

Several compile-fail WIR fixtures are active expected-failure tests for backend
diagnostics. Run `./surface-matrix.sh` to see the full surface compatibility
matrix split by frontend, backend, LLVM validation, native linking, and runtime
checks.

`./selfhost.sh` builds stage1 and stage2 compilers, then uses stage2 to compile
selected surface fixtures and compare their normalized WIR against golden
outputs before validating LLVM and runtime exit codes.

The first frontend sugar fixture is `60_let_literal_sugar.weave`; typed `let`
statements can use integer literals directly when the statement already carries
the target type.
