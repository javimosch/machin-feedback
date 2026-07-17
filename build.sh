#!/usr/bin/env bash
# Build machin-feedback: one static native binary (daemon + CLI). Needs `machin` on PATH.
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
command -v "$MACHIN" >/dev/null 2>&1 || { echo "error: '$MACHIN' not found (set MACHIN=/path/to/machin)"; exit 1; }
"$MACHIN" encode framework/machweb.src src/feedback.src > feedback.mfl
"$MACHIN" build feedback.mfl -o machin-feedback
echo "built ./machin-feedback"
