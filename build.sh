#!/usr/bin/env bash
# Build BrainrotLab.rbxlx from the Rojo project.
# Requires: rojo (https://rojo.space) and wally (https://wally.run) on PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo ">> Installing Wally packages..."
if command -v wally >/dev/null 2>&1; then
  wally install
else
  echo "!! wally not found. Install from https://wally.run — skipping package install."
fi

echo ">> Building place file..."
if ! command -v rojo >/dev/null 2>&1; then
  echo "!! rojo not found. Install from https://rojo.space and rerun." >&2
  exit 1
fi

rojo build default.project.json --output BrainrotLab.rbxlx
echo ">> Done: BrainrotLab.rbxlx"
