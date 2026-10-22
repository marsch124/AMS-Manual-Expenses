#!/bin/bash
# Builds AMS Manual Expenses.   tools/build.sh [build|test] [simulator name]
#
# Two traps this script exists for (both met first on AMS Coffee, kept as in AMS Packing):
#  1. Anything under ~/Documents picks up macOS extended attributes, and codesign
#     refuses them ("resource fork ... detritus not allowed"). So: clear them first —
#     but never inside .git, whose objects are read-only and would fail the sweep.
#  2. Derived data must land OUTSIDE ~/Documents for the same reason.
set -e
cd "$(dirname "$0")/.."
DD="${TMPDIR:-/tmp}/AMSExpenses-build"

find . -path ./.git -prune -o -print0 | xargs -0 xattr -c 2>/dev/null || true
xcodegen generate

# Its own simulator (made 22 Oct 2026), so a run never fights another app's tests for one.
SIM="${2:-Expenses iPhone 18 Pro}"
EXTRA=()
if [ "${1:-build}" = "test" ]; then
  # After a RED test xcodebuild otherwise sits "collecting diagnostics" for minutes.
  EXTRA=(-collect-test-diagnostics never -test-timeouts-enabled YES
         -maximum-test-execution-time-allowance 300)
fi

xcodebuild \
  -project AMSExpenses.xcodeproj \
  -scheme AMSExpenses \
  -destination "platform=iOS Simulator,name=$SIM" \
  -derivedDataPath "$DD" \
  "${EXTRA[@]}" \
  "${1:-build}"

echo
echo "App: $DD/Build/Products/Debug-iphonesimulator/AMSExpenses.app"
