#!/bin/bash
# The parser's tests alone — a few seconds, no simulator.
set -e
cd "$(dirname "$0")/../Core"
# The build folder is kept OUTSIDE ~/Documents: codesign refuses the extended attributes
# that folder collects, and the test bundle has to be signed (same as AMS Packing).
swift test --scratch-path "${TMPDIR:-/tmp}/AMSExpenses-core" "$@"
