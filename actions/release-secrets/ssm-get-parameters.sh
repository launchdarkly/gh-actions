#!/usr/bin/env bash
set -euo pipefail

# Parse parameter pairs from format: "/ssm/path = ENV_NAME, /ssm/path2 = ENV_NAME2"
# Fetch values from AWS SSM, mask them in logs, and export them as environment
# variables for subsequent steps.

# Trim leading/trailing whitespace via parameter expansion. (xargs performs
# shell-style quote/backslash processing, not trimming, so it silently mangles
# values containing quotes or backslashes.)
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# Split the input on ',' into pairs, then split each pair on the first '=' into
# an SSM path and a target env var name. Order is preserved and duplicate paths
# are allowed (the same secret can be exported under two env vars).
ssm_paths=()
env_names=()
mapfile -t raw_pairs < <(printf '%s' "${SSM_PARAMETER_PAIRS}" | tr ',' '\n')
for pair in "${raw_pairs[@]}"; do
  pair="$(trim "${pair}")"
  [ -z "${pair}" ] && continue
  # A well-formed pair must contain '='.
  if [ "${pair}" = "${pair#*=}" ]; then
    echo "::error::Malformed ssm_parameter_pairs entry: '${pair}' (expected '/ssm/path = ENV_NAME')"
    exit 1
  fi
  ssm_path="$(trim "${pair%%=*}")"
  env_name="$(trim "${pair#*=}")"
  if [ -z "${ssm_path}" ] || [ -z "${env_name}" ]; then
    echo "::error::Malformed ssm_parameter_pairs entry: '${pair}' (expected '/ssm/path = ENV_NAME')"
    exit 1
  fi
  ssm_paths+=("${ssm_path}")
  env_names+=("${env_name}")
done

total=${#ssm_paths[@]}
if [ "${total}" -eq 0 ]; then
  echo "No SSM parameter pairs to process."
  exit 0
fi

# Fetch all requested parameters, chunked to the SSM GetParameters API limit of
# 10, and build a path -> value map. get-parameters returns successfully even
# when names are missing (they land in .InvalidParameters), so we resolve every
# requested pair against the map afterwards and fail loudly on any miss rather
# than silently exporting fewer vars than requested.
declare -A values=()
chunk_size=10
for ((i=0; i<total; i+=chunk_size)); do
  chunk=("${ssm_paths[@]:i:chunk_size}")
  result="$(aws ssm get-parameters --names "${chunk[@]}" --with-decryption --output json)"

  # Stream Name/Value as NUL-delimited records so values containing newlines,
  # tabs, or '=' are preserved exactly.
  while IFS= read -r -d '' name && IFS= read -r -d '' value; do
    values["${name}"]="${value}"
  done < <(printf '%s' "${result}" | jq -j '.Parameters[] | .Name + "\u0000" + .Value + "\u0000"')
done

# Validate that every requested path was returned BEFORE writing anything, so a
# missing parameter never leaves a partially-populated $GITHUB_ENV that an
# always()/continue-on-error downstream step could read in an inconsistent state.
for ((k=0; k<total; k++)); do
  ssm_path="${ssm_paths[k]}"
  if [ -z "${values["${ssm_path}"]+set}" ]; then
    echo "::error::SSM parameter '${ssm_path}' (-> ${env_names[k]}) was not returned by AWS (missing parameter or insufficient permissions)."
    exit 1
  fi
done

# Resolve each requested pair, mask the value, and export it.
for ((k=0; k<total; k++)); do
  ssm_path="${ssm_paths[k]}"
  env_name="${env_names[k]}"
  value="${values["${ssm_path}"]}"

  # Mask every line of the value. ::add-mask:: is line-oriented, so a multiline
  # secret (PEM key, cert, JSON blob) must be masked line by line or the tail
  # leaks into the logs.
  while IFS= read -r mask_line || [ -n "${mask_line}" ]; do
    [ -n "${mask_line}" ] && echo "::add-mask::${mask_line}"
  done <<< "${value}"

  # Write to GITHUB_ENV using heredoc-delimiter syntax. A plain "NAME=value"
  # only handles single-line values; a multiline value would be truncated and
  # its remaining lines parsed as additional (attacker-controllable) env
  # entries. The delimiter is randomized and verified not to appear in the value.
  delim="EOF_$(openssl rand -hex 16)"
  while [[ "${value}" == *"${delim}"* ]]; do
    delim="EOF_$(openssl rand -hex 16)"
  done
  {
    printf '%s<<%s\n' "${env_name}" "${delim}"
    printf '%s\n' "${value}"
    printf '%s\n' "${delim}"
  } >> "${GITHUB_ENV}"

  echo "Env variable ${env_name} set with value from ssm parameterName ${ssm_path}"
done
