# Quantum surface syntax (proposal)

Status: Proposal for weavec2 frontend and transform passes  
Date: 2026-05-25  
See also: [representation-lowering.md](representation-lowering.md)

## Goals

- Quantum operations are normal Weave surface syntax in `.weave` files.
- Classical and quantum code share functions, types, control flow, and modules.
- Gate decomposition and device lowering are transform passes, not a new language.
- Tests use `.weave` sources under `test/quantum/` (same compiler as classical).

Non-goals for v1:

- A separate circuit file format or IDE-only DSL.
- Lowering quantum gates inside `src/llvm/` (backend emits what the IR already
  contains).

## Types

```weave
(type Qubit (opaque))
(type QubitRef (ref Qubit))
(type ClassicalBit (alias Int32))  ; 0/1 measurement result, refine later
```

Allocation and release use ordinary functions until ownership rules land:

```weave
(fn qubit-alloc (params ()) (returns Qubit) ...)
(fn qubit-release (params (q Qubit)) (returns Void) ...)
```

## Gate application

Uniform statement form — gate name is a symbol, qubits are values:

```weave
(qgate H q0)
(qgate CNOT q0 q1)
(qgate RZ q0 angle)
```

`qgate` is a statement (like `let` or `if-stmt`), not a function call, so the
compiler can attach rewrite metadata and target packs without ADL ambiguity.

Parameterized gates take classical `Float64` angles at the surface; the
nativization pass may fold constants.

## Measurement

```weave
(let c0 ClassicalBit (qmeasure q0))
```

Optional basis (later):

```weave
(qmeasure q0 c0 (basis X))
```

## Example program

```weave
(program
  (name "bell-prep")
  (doc "Prepare Bell pair; return 42 on success")
  (entry main
    (params ())
    (returns Int32)
    (body
      (let q0 Qubit (qubit-alloc))
      (let q1 Qubit (qubit-alloc))
      (qgate H q0)
      (qgate CNOT q0 q1)
      (let c0 ClassicalBit (qmeasure q0))
      (let c1 ClassicalBit (qmeasure q1))
      (qubit-release q0)
      (qubit-release q1)
      (return 42))))
```

## Transform: nativize on surface

Before WIR emission, a `lower` pass rewrites non-native gates. Rigetti-style
pack (`RY`, `RZ`, `RX`, `CZ` native; no `H`):

```weave
(transform-rule nativize-hadamard
  (pattern (qgate H ?q:Qubit))
  (replacement
    (seq
      (qgate RY ?q 1.5707963267948966)
      (qgate RZ ?q 3.141592653589793)))
  (when (native? RY RZ)))
```

Rules live in Weave modules, e.g. `(include "targets/rigetti-nativize.weave")`,
selected by compile flag or module attribute (design TBD).

## Lowering to WIR (sketch)

After nativization, the frontend lowers each `(qgate ...)` to target-specific
WIR. Two viable v1 strategies:

1. Extern calls to a quantum runtime (`extern void qrt_ry(...)`).
2. Intrinsics embedded in WIR as `(qop ...)` nodes if Core gains quantum
   forms — only if they share the same module as classical code.

weavec2 v1 recommendation: extern runtime stubs so `src/llvm/` stays unchanged
until intrinsics are justified. Classical `main` still returns `Int32`; quantum
side effects happen through the runtime.

## Parser / frontend checklist

| Step | Component |
|------|-----------|
| 1 | Lexer: `qgate`, `qmeasure` keywords |
| 2 | Parser: statement variants in `src/frontend/` |
| 3 | Typecheck: `Qubit` only where required |
| 4 | Transform registry: nativize pass before `lower.weave` |
| 5 | `lower.weave`: emit WIR for remaining `qgate` nodes |
| 6 | Test: `test/quantum/nativization/test-hadamard-single.weave` |

## First test (planned)

`test/quantum/nativization/test-hadamard-single.weave` — one `H`, assert dump
after nativize shows `RY` + `RZ` only. Golden: text from `--dump-surface` or a
small WIR snippet, not a new file extension.

## Open questions

- `qgate` vs `(gate H q0)` — prefer `qgate` prefix to reserve short names.
- Variational parameters: angles as `Float64` params vs symbolic refs.
- Classical control of quantum ops: allowed inside `if-stmt` with phase
  constraints (measurement collapse rules).
