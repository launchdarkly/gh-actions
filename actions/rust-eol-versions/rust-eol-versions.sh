#!/usr/bin/env bash
# Writes the Rust release cycle at $OFFSET to $GITHUB_OUTPUT. See README.md.

set -euo pipefail

if [[ ! "$OFFSET" =~ ^[0-9]+$ ]]; then
  echo "::error::offset must be a non-negative integer, got '$OFFSET'"
  exit 1
fi

payload=$(curl --fail --silent --show-error --location --max-time 30 --retry 3 "$API_URL")

target=$(jq -r --argjson offset "$OFFSET" '.[$offset].cycle // ""' <<<"$payload")

if [[ ! "$target" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "::error::Unexpected Rust release cycle from $API_URL at offset $OFFSET: '$target'"
  exit 1
fi

echo "Rust release cycle at offset $OFFSET: $target"

echo "target=$target" >>"$GITHUB_OUTPUT"
