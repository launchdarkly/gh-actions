#!/usr/bin/env bash
# Writes the two most recent supported Go versions to $GITHUB_OUTPUT as `latest` and
# `penultimate`.
#
# The endoflife.date response is untrusted input. It is held in a variable and read with
# jq, never interpolated into a command, and each extracted version must match a strict
# version pattern before it is written to $GITHUB_OUTPUT. That means a caller which
# interpolates these outputs into a `run:` block is still safe, which is the whole point
# of centralizing this: the validation cannot be forgotten one repository at a time.

set -euo pipefail

case "$PRECISION" in
  cycle | latest) ;;
  *)
    echo "::error::precision must be 'cycle' or 'latest', got '$PRECISION'"
    exit 1
    ;;
esac

payload=$(curl --fail --silent --show-error --location --max-time 30 --retry 3 "$API_URL")

latest=$(jq -r --arg field "$PRECISION" '.[0][$field] // ""' <<<"$payload")
penultimate=$(jq -r --arg field "$PRECISION" '.[1][$field] // ""' <<<"$payload")

for version in "$latest" "$penultimate"; do
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo "::error::Unexpected Go version string from $API_URL: '$version'"
    exit 1
  fi
done

echo "Latest supported Go version: $latest (penultimate: $penultimate)"

echo "latest=$latest" >>"$GITHUB_OUTPUT"
echo "penultimate=$penultimate" >>"$GITHUB_OUTPUT"
