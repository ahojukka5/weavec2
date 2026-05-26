# Quantum tests (planned)

Quantum behavior is tested through surface `.weave` programs, not a separate
file format.

When the frontend accepts `Qubit`, `gate`, and `measure`, add fixtures here, for
example:

```text
nativization/test-hadamard-single.weave
nativization/expected/test-hadamard-single.wir   # or LLVM / dump golden
```

Run via a `test.sh` sibling to `test/performance/test.sh`, driven by weavec2
after `./build.sh`.

Design: `docs/representation-lowering.md`.
