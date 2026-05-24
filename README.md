# weavec2

The Weave compiler — written in surface Weave.

weavec2 compiles Weave source files to LLVM IR. It is the first compiler in the
Weave toolchain to be written in Weave itself, making it a self-hosting milestone.
The compiler operates in two stages:

1. Frontend (`src/frontend/`): surface Weave -> WIR (Weave Intermediate Representation)
2. Backend (`src/llvm/`): WIR -> LLVM IR

Shared utilities (I/O helpers, s-expression tree navigation) live in `src/core/`.

## Pipeline

```
source.weave
    │
    v frontend (src/frontend/)
source.wir
    │
    v backend (src/llvm/)
source.ll
    │
    v clang
binary
```

## Bootstrap build

weavec2 is bootstrapped using the existing WIR toolchain:

```
src/**/*.weave
    │
    v weavefront-cat.sh  (concatenates .weave files)
    v weavefront         (surface Weave -> WIR)
build/weavec2.wir
    │
    v weavec1            (WIR -> LLVM IR)
build/weavec2.ll
    │
    v llvm-link          (link parser runtime modules)
build/weavec2.bc
    │
    v clang
build/weavec2
```

Once built, weavec2 can compile itself.

## Directory structure

```
src/
  core/         — shared primitives
    extern.weave  — C runtime interface declarations (libc, POSIX I/O, weavefront)
    io.weave      — write helpers: write_byte, write_cstr, write_i64_dec
    util.weave    — s-expression tree navigation: nth_child, head_equals, slices_equal
  llvm/         — WIR -> LLVM IR backend
    ctx.weave     — emission context: counters, local/param tables, output fd
    types.weave   — type parsing and emission (void, i32, i64, bool, ptr)
    locals.weave  — local and parameter binding tables
    strings.weave — string literal global emission (@.strN = private unnamed_addr ...)
    expr.weave    — WIR expression -> LLVM IR (all operators: arithmetic, memory, calls)
    stmt.weave    — WIR statement -> LLVM IR (let, set, if, while, return, store)
    fn.weave      — function and extern declaration emission
    module.weave  — top-level module emission (header, externs, strings, functions)
  frontend/     — surface Weave -> WIR frontend
  main.weave    — compiler entry point (file I/O, lex/parse, emit)
```

## Building

```bash
./build.sh
```

Requires: `weavefront`, `weavec1`, `llvm-link`, `clang`.
The bootstrap tools are expected in `../weavefront/build/` and `../weavec1/build/`.

Strict self-hosting starts from `build/weavec2`, compiles the vendored parser
runtime WIR modules under `src/runtime-wir/`, builds a stage1 compiler, then
repeats the build with stage1:

```bash
./selfhost.sh
```

That path does not link `../weavec0/runtime.c`, `../weavefront/build/*.ll`, or
`../weavec1/build/weavec1`.

## Usage

```
weavec2 --backend <input.wir> <output.ll>
weavec2 --frontend <output.wir> <input.weave> [input2.weave ...]
```

The historical backend spelling still works:

```
weavec2 <input.wir> <output.ll>
```
