#!/usr/bin/env bash
# Smoke test for ssm-get-parameters.sh.
#
# Runs the script under a mocked `aws` CLI (real jq/openssl) and asserts on the
# masking directives it prints and the contents it writes to $GITHUB_ENV. The
# env file is parsed exactly as the GitHub Actions runner does (supporting the
# heredoc-delimiter form) so multiline values are verified end to end.
#
# Usage: bash actions/release-secrets/tests/ssm-get-parameters.test.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/../ssm-get-parameters.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

# --- Mock `aws` CLI -------------------------------------------------------
# Emulates `aws ssm get-parameters --names A B C --with-decryption --output json`.
# Looks each requested name up in the JSON object at $MOCK_PARAMS_FILE; present
# names go to .Parameters, absent ones to .InvalidParameters (mirroring the real
# API, which returns success either way).
MOCK_BIN="${WORK}/bin"
mkdir -p "${MOCK_BIN}"
cat > "${MOCK_BIN}/aws" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
names=()
while [ $# -gt 0 ]; do
  case "$1" in
    --names)
      shift
      while [ $# -gt 0 ] && [[ "$1" != --* ]]; do names+=("$1"); shift; done
      ;;
    *) shift ;;
  esac
done
# Mirror the real GetParameters limit: >10 names is a ValidationException.
if [ "${#names[@]}" -gt 10 ]; then
  echo "ValidationException: Member must have length less than or equal to 10" >&2
  exit 255
fi
names_json="$(printf '%s\n' "${names[@]+"${names[@]}"}" | jq -R . | jq -s .)"
jq -n \
  --argjson fix "$(cat "${MOCK_PARAMS_FILE}")" \
  --argjson names "${names_json}" '
  {
    Parameters: [ $names[] | select($fix[.] != null) | {Name: ., Value: $fix[.]} ],
    InvalidParameters: [ $names[] | select($fix[.] == null) ]
  }'
MOCK
chmod +x "${MOCK_BIN}/aws"

# --- Test harness ---------------------------------------------------------
PASS=0
FAIL=0

# parse_env_file <file> -> populates global assoc array ENV_OUT, mirroring how
# the Actions runner parses $GITHUB_ENV (KEY=value and KEY<<DELIM ... DELIM).
declare -A ENV_OUT
parse_env_file() {
  ENV_OUT=()
  local line name delim val first
  while IFS= read -r line; do
    if [[ "${line}" == *"<<"* ]]; then
      name="${line%%<<*}"
      delim="${line#*<<}"
      val=""
      first=1
      while IFS= read -r vl; do
        [ "${vl}" = "${delim}" ] && break
        if [ "${first}" -eq 1 ]; then val="${vl}"; first=0; else val="${val}"$'\n'"${vl}"; fi
      done
      ENV_OUT["${name}"]="${val}"
    elif [[ "${line}" == *"="* ]]; then
      ENV_OUT["${line%%=*}"]="${line#*=}"
    fi
  done < "$1"
}

# run_script <params-json> <pairs> -> sets RC, OUT (stdout+stderr), ENV_FILE
run_script() {
  local params="$1" pairs="$2"
  MOCK_PARAMS_FILE="${WORK}/params.json"
  printf '%s' "${params}" > "${MOCK_PARAMS_FILE}"
  ENV_FILE="${WORK}/github_env"
  : > "${ENV_FILE}"
  set +e
  OUT="$(PATH="${MOCK_BIN}:${PATH}" \
        MOCK_PARAMS_FILE="${MOCK_PARAMS_FILE}" \
        SSM_PARAMETER_PAIRS="${pairs}" \
        GITHUB_ENV="${ENV_FILE}" \
        bash "${SCRIPT}" 2>&1)"
  RC=$?
  set -e
  set +e
}

ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; }

assert_rc()       { [ "${RC}" -eq "$1" ] && ok "exit ${1}" || bad "expected exit ${1}, got ${RC}" "${OUT}"; }
assert_env()      { parse_env_file "${ENV_FILE}"; [ "${ENV_OUT["$1"]+set}" ] && [ "${ENV_OUT["$1"]}" = "$2" ] && ok "env ${1} matches" || bad "env ${1}: expected [$2], got [${ENV_OUT["$1"]-<unset>}]"; }
assert_env_unset(){ parse_env_file "${ENV_FILE}"; [ -z "${ENV_OUT["$1"]+set}" ] && ok "env ${1} unset" || bad "env ${1} should be unset, got [${ENV_OUT["$1"]}]"; }
assert_out()      { grep -qF -- "$1" <<< "${OUT}" && ok "output contains [$1]" || bad "output missing [$1]" "${OUT}"; }

# ==========================================================================
echo "Test 1: single-line happy path"
run_script '{"/app/db":"secretDB"}' "/app/db = DB_PASS"
assert_rc 0
assert_env DB_PASS "secretDB"
assert_out "::add-mask::secretDB"

echo "Test 2: multiline value (PEM-style) — heredoc + per-line masking"
run_script '{"/app/key":"-----BEGIN-----\nLINE2\n-----END-----"}' "/app/key = PRIVATE_KEY"
assert_rc 0
assert_env PRIVATE_KEY $'-----BEGIN-----\nLINE2\n-----END-----'
assert_out "::add-mask::-----BEGIN-----"
assert_out "::add-mask::LINE2"
assert_out "::add-mask::-----END-----"

echo "Test 3: missing parameter fails loudly (InvalidParameters)"
run_script '{"/app/db":"secretDB"}' "/app/db = DB_PASS, /app/missing = API_KEY"
assert_rc 1
assert_out "/app/missing"
assert_env_unset API_KEY

echo "Test 4: duplicate path -> two env vars"
run_script '{"/app/shared":"shVal"}' "/app/shared = ENV_A, /app/shared = ENV_B"
assert_rc 0
assert_env ENV_A "shVal"
assert_env ENV_B "shVal"

echo "Test 5: value containing '=' and '&' is preserved"
run_script '{"/app/url":"a=b&c=d"}' "/app/url = URL"
assert_rc 0
assert_env URL "a=b&c=d"

echo "Test 6: value containing a backslash is preserved (xargs regression)"
run_script '{"/app/p":"a\\b\\c"}' "/app/p = BS"
assert_rc 0
assert_env BS 'a\b\c'

echo "Test 7: chunking across the 10-parameter API limit (12 params)"
# The mock rejects any single get-parameters call with >10 names (like real AWS),
# so this only passes if the script actually chunks. Assert across the 10/11
# chunk boundary and the full count to guard the chunk loop.
params="{"; pairs=""
for n in $(seq 1 12); do
  params+="\"/p/${n}\":\"v${n}\""; [ "${n}" -lt 12 ] && params+=","
  pairs+="/p/${n} = E_${n}"; [ "${n}" -lt 12 ] && pairs+=", "
done
params+="}"
run_script "${params}" "${pairs}"
assert_rc 0
assert_env E_1 "v1"
assert_env E_10 "v10"
assert_env E_11 "v11"
assert_env E_12 "v12"
parse_env_file "${ENV_FILE}"
[ "${#ENV_OUT[@]}" -eq 12 ] && ok "all 12 vars written" || bad "expected 12 vars, got ${#ENV_OUT[@]}"

echo "Test 11: missing param after a success does not leave a partial GITHUB_ENV"
run_script '{"/app/ok":"goodval"}' "/app/ok = FIRST, /app/missing = SECOND"
assert_rc 1
assert_env_unset FIRST
assert_env_unset SECOND

echo "Test 8: malformed pair (no '=') fails loudly"
run_script '{"/app/db":"secretDB"}' "/app/db = DB_PASS, /app/orphan"
assert_rc 1
assert_out "Malformed"

echo "Test 9: surrounding whitespace is trimmed"
run_script '{"/app/db":"v"}' "   /app/db    =    DB_PASS   "
assert_rc 0
assert_env DB_PASS "v"

echo "Test 10: empty input is a no-op success"
run_script '{}' ""
assert_rc 0

# ==========================================================================
echo
echo "Passed: ${PASS}  Failed: ${FAIL}"
[ "${FAIL}" -eq 0 ]
