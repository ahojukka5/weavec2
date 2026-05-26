#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '[weavec2-test-all] %s\n' "$*"
}

log 'build'
"$ROOT/build.sh"

log 'correctness'
"$ROOT/test.sh"

log 'performance'
"$ROOT/test/performance/test.sh"

log 'quantum'
"$ROOT/test/quantum/test.sh"

log 'self-host'
"$ROOT/test/selfhost/test.sh"

log 'all weavec2 checks passed'
