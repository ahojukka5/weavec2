# Contributing to weavec2

Thanks for your interest in `weavec2`. Before opening a PR or filing
an issue, please understand the scope: `weavec2` is the
**self-hosted** surface-Weave compiler at the top of the chain. It is
written in surface Weave (`src/**/*.weave`) and bootstrapped by
[`weavefront`](https://github.com/ahojukka5/weavefront) (surface →
WIR) and [`weavec1`](https://github.com/ahojukka5/weavec1) (WIR →
LLVM IR).

## Principles

- **WIR is the boundary contract.** weavec2 emits LLVM IR via a WIR-
  backed pipeline. Don't extend WIR from weavec2; that change goes in
  `weavec0` / `weavec1` first.
- **Surface Weave evolves here.** Surface syntax additions (new
  forms, syntax sugar, struct features, quantum ops) land in
  `src/frontend/`. The expectation is that they lower to WIR the
  backends already accept.
- **No feature without a test.** Every change must come with a test:
  - a `.weave` fixture under `test/correctness/surface/` or
  - a `.wir` fixture + `.expected.ll` golden under
    `test/performance/` or
  - a `.weave` quantum fixture under `test/quantum/`.
  `./test-all.sh` must continue to end with
  `all weavec2 checks passed`.
- **Goldens are reviewed.** The performance tests diff emitted LLVM
  against checked-in `*.expected.ll` files. Regenerate with
  `test/performance/regen-golden.sh` and review the `git diff` before
  committing.
- **Self-host basic must keep passing.** `test/selfhost/test.sh`
  re-compiles `build/weavec2.wir` (the bootstrapped weavec2 source)
  with the freshly-built weavec2 binary and verifies the output is
  accepted by `llvm-as`. Any backend change that breaks self-host is
  a regression even if the explicit test ladder passes.

## What does NOT belong here

- New WIR primitives. Those go in the backends (`weavec0` /
  `weavec1`).
- Optimisation passes targeting LLVM. The backend handles its own
  codegen; weavec2's emitter aims for clarity and correctness, not
  hand-tuned IR.
- Anything that requires extending `weavec0`'s admitted extern set.
  That goes in `weavec0` first, gets a release, and then the
  `WEAVEC0_TAG` pin in `build.sh` is bumped.

## Workflow

1. Fork and create a feature branch.
2. Edit the relevant `src/**/*.weave`, add or update test fixtures.
3. Run `./build.sh` locally — must succeed.
4. Run `./test-all.sh` — full ladder
   (124 correctness + 168 performance + 4 quantum + 1 quantum-e2e +
   self-host basic) must pass.
5. If your change affects the LLVM backend output, regenerate the
   performance goldens with
   `./test/performance/regen-golden.sh` and commit the regenerated
   `*.expected.ll` files alongside your source change.
6. Open a PR. CI re-runs the full ladder on Linux and macOS.

## Licensing

By submitting a contribution, you agree that your contribution is
licensed under the Apache License, Version 2.0 (see
[`LICENSE`](LICENSE)).
