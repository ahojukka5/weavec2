# Quantum tests

Surface `.weave` programs; goldens are `.expected.wir` beside each source.

Run (after `./build.sh`):

```bash
./test/quantum/test.sh
./test/quantum/test-e2e.sh   # surface -> WIR -> LLVM -> stub qrt_* runtime
```

Fixtures:

| Path | Checks |
|------|--------|
| `nativization/test-hadamard-single.weave` | `(qgate H q0)` with `Qubit` -> `qrt_ry` + `qrt_rz` |
| `nativization/test-hadamard-measure.weave` | H nativize + `(qmeasure q0 c0)` |
| `e2e/test-quantum-smoke.weave` | Full pipeline returns exit 42 |
| `validation/*.weave` | Frontend must reject (bad arity, non-Qubit operand) |

Implementation:

- H decomposition: `src/frontend/quantum_nativize.weave` (H to RY + RZ before WIR emit)
- `Qubit` surface type lowers to `i64` in `src/frontend/emit.weave`
- Typecheck: `validate_quantum_program` in `src/frontend/lower.weave` (called before emit; see `quantum_typecheck.weave` for module index)
- E2E runtime: `runtime/quantum_runtime.c`

Design: `docs/representation-lowering.md`, `docs/quantum-surface-syntax.md`.
