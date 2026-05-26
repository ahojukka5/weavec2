# Quantum tests

Surface `.weave` programs; goldens are `.expected.wir` beside each source.

Run (after `./build.sh`):

```bash
./test/quantum/test.sh
```

Fixtures:

| File | Checks |
|------|--------|
| `nativization/test-hadamard-single.weave` | `(qgate H q0)` → `qrt_ry` + `qrt_rz` |
| `nativization/test-hadamard-measure.weave` | H nativize + `(qmeasure q0 c0)` |

Lowering lives in `src/frontend/emit.weave` until transform passes replace it.
Declarative rules: `src/frontend/targets/rigetti-nativize.weave`.

Design: `docs/representation-lowering.md`, `docs/quantum-surface-syntax.md`.
