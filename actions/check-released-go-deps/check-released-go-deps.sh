#!/usr/bin/env bash
# Fails when a go.mod file depends on an unreleased version of an enforced module. See README.md.

set -euo pipefail

error() {
  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    echo "::error::$1"
  else
    echo "error: $1" >&2
  fi
}

# Prints the entries of a newline-separated input: trimmed, with blank lines and # comments removed.
entries() {
  printf '%s\n' "$1" | sed -e 's/^[[:space:]]*//' -e 's/^#.*//' -e 's/[[:space:]]#.*//' \
    -e 's/[[:space:]]*$//' -e '/^$/d'
}

# Escapes a value for use as a workflow command property (file=) or message.
escape_data() {
  local s=$1
  s=${s//\%/%25}
  s=${s//$'\r'/%0D}
  s=${s//$'\n'/%0A}
  printf '%s' "$s"
}
escape_property() {
  local s
  s=$(escape_data "$1")
  s=${s//:/%3A}
  s=${s//,/%2C}
  printf '%s' "$s"
}

prefixes=()
while IFS= read -r entry; do
  case "$entry" in
    *[[:space:]]*)
      error "module_prefixes: expected one module path prefix per line, got '$entry'"
      exit 2
      ;;
  esac
  prefixes+=("$entry")
done < <(entries "${MODULE_PREFIXES:-}")
if [ "${#prefixes[@]}" -eq 0 ]; then
  error "module_prefixes must list at least one module path prefix"
  exit 2
fi

allowed=()
allowed_re='^[^@[:space:]]+@v[^@[:space:]]+$'
while IFS= read -r entry; do
  if [[ ! $entry =~ $allowed_re ]]; then
    error "allowed: expected one exact module@version per line, got '$entry'"
    exit 2
  fi
  allowed+=("$entry")
done < <(entries "${ALLOWED:-}")

excludes=()
while IFS= read -r entry; do
  entry=${entry#./}
  while [ "${entry%/}" != "$entry" ]; do entry=${entry%/}; done
  if [ -n "$entry" ]; then excludes+=("$entry"); fi
done < <(entries "${EXCLUDE:-}")

candidates=()
if [ -n "$(entries "${GO_MOD_FILES:-}")" ]; then
  while IFS= read -r entry; do candidates+=("$entry"); done < <(entries "$GO_MOD_FILES")
else
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    error "Not in a git work tree. Run actions/checkout before this action, or set go_mod_files."
    exit 2
  fi
  while IFS= read -r -d '' entry; do candidates+=("$entry"); done < <(git ls-files -z -- go.mod '*/go.mod')
fi

files=()
for f in ${candidates[@]+"${candidates[@]}"}; do
  f=${f#./}
  skip=""
  for e in ${excludes[@]+"${excludes[@]}"}; do
    if [[ "$f" == "$e" || "$f" == "$e"/* ]]; then skip=$e; fi
  done
  if [ -n "$skip" ]; then
    echo "Skipping $f (excluded by '$skip')"
    continue
  fi
  if [ ! -f "$f" ]; then
    error "go.mod file not found: $f"
    exit 2
  fi
  files+=("$f")
done
if [ "${#files[@]}" -eq 0 ]; then
  error "No go.mod files to check. Run actions/checkout before this action, or check go_mod_files and exclude."
  exit 2
fi

# Prints one line per finding: status|line|module|version|reason. status is "violation" or "allowed".
read -r -d '' awk_program <<'AWK' || true
function enforced(path,    k) {
  for (k = 1; k <= np; k++) if (index(path, prefix[k]) == 1) return 1
  return 0
}
function classify(v) {
  if (v ~ final_re) return ""
  if (v == "") return "has no version"
  if (v ~ pseudo_re) return "is a pseudo-version, not a release"
  if (v ~ /^v[0-9]+\.[0-9]+\.[0-9]+-/) return "is a pre-release, not a final release"
  return "is not a released version"
}
function report(status, path, ver, reason) {
  print status "|" FNR "|" path "|" ver "|" reason
}
function check_replace(first,    i, arrow, rhs, why) {
  arrow = 0
  for (i = first; i <= NF; i++) if ($i == "=>") { arrow = i; break }
  if (enforced($first)) {
    rhs = ""
    if (arrow) for (i = arrow + 1; i <= NF; i++) rhs = rhs (rhs == "" ? "" : " ") $i
    report("violation", $first, (arrow > first + 1 ? $(first + 1) : ""),
      "is replaced" (rhs == "" ? "" : " by " rhs) "; enforced modules must not be replaced")
    return
  }
  if (arrow == 0 || arrow == NF || !enforced($(arrow + 1))) return
  why = classify(arrow + 2 <= NF ? $(arrow + 2) : "")
  if (why != "") report("violation", $(arrow + 1), (arrow + 2 <= NF ? $(arrow + 2) : ""), why " (replace target)")
}
BEGIN {
  np = split(prefixes, prefix, " ")
  na = split(allowed, entry, " ")
  for (k = 1; k <= na; k++) ok[entry[k]] = 1
  final_re = "^v[0-9]+\\.[0-9]+\\.[0-9]+(\\+incompatible)?$"
  d = "[0-9]"; h = "[0-9a-f]"
  pseudo_re = "(-|-0\\.|\\.0\\.)" d d d d d d d d d d d d d d "-" h h h h h h h h h h h h "(\\+incompatible)?$"
  skip["module"] = skip["go"] = skip["toolchain"] = skip["godebug"] = 1
  skip["retract"] = skip["exclude"] = skip["tool"] = skip["ignore"] = 1
}
{ gsub(/\r/, ""); sub(/\/\/.*/, ""); gsub(/"/, ""); gsub(/^[ \t]+|[ \t]+$/, "") }
NF == 0 { next }
block == "" && /^[a-z]+[ \t]*\([ \t]*\)$/ { next }
block == "" && /^[a-z]+[ \t]*\($/ { block = $0; sub(/[ \t]*\($/, "", block); next }
$0 == ")" { block = ""; next }
{
  if (block != "") { dir = block; first = 1 } else { dir = $1; first = 2 }
  if (dir in skip) next
  if (dir == "replace") { check_replace(first); next }
  for (i = first; i <= NF; i++) {
    if (!enforced($i)) continue
    ver = (i < NF ? $(i + 1) : "")
    why = classify(ver)
    if (why == "") continue
    report(((($i "@" ver) in ok) ? "allowed" : "violation"), $i, ver, why)
  }
}
AWK

joined_prefixes="${prefixes[*]}"
joined_allowed="${allowed[*]-}"
violations=0
used_allowed=" "
summary_rows=""
allowed_rows=""

echo "Checking ${#files[@]} go.mod file(s) for unreleased versions of modules under: ${prefixes[*]}"
for f in "${files[@]}"; do
  echo "Checking $f"
  findings=$(awk -v prefixes="$joined_prefixes" -v allowed="$joined_allowed" "$awk_program" "$f")
  while IFS='|' read -r status line module version reason; do
    [ -n "$status" ] || continue
    text="$module${version:+ $version} $reason"
    row="| \`$f:$line\` | \`$module\` | ${version:+\`$version\`} | $reason |"
    if [ "$status" = "allowed" ]; then
      echo "Allowed: $f:$line: $text (exempted by the allowed input)"
      used_allowed="$used_allowed$module@$version "
      allowed_rows="$allowed_rows$row"$'\n'
      continue
    fi
    violations=$((violations + 1))
    summary_rows="$summary_rows$row"$'\n'
    if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
      echo "::error file=$(escape_property "$f"),line=$line,title=Unreleased Go dependency::$(escape_data "$f:$line: $text")"
    else
      echo "$f:$line: $text"
    fi
  done <<<"$findings"
done

for entry in ${allowed[@]+"${allowed[@]}"}; do
  case "$used_allowed" in
    *" $entry "*) ;;
    *)
      if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
        echo "::warning::allowed entry $entry matched no requirement in the checked go.mod files; remove it if it is no longer needed"
      else
        echo "warning: allowed entry $entry matched no requirement in the checked go.mod files" >&2
      fi
      ;;
  esac
done

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "violations=$violations" >>"$GITHUB_OUTPUT"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Released Go dependencies"
    echo
    if [ "$violations" -eq 0 ]; then
      echo "Passed: ${#files[@]} go.mod file(s) use only released versions of the enforced modules."
    else
      echo "Failed: $violations unreleased dependency reference(s) in ${#files[@]} go.mod file(s)."
      echo
      echo "| Location | Module | Version | Problem |"
      echo "|----------|--------|---------|---------|"
      printf '%s' "$summary_rows"
    fi
    if [ -n "$allowed_rows" ]; then
      echo
      echo "Exempted by \`allowed\`:"
      echo
      echo "| Location | Module | Version | Problem |"
      echo "|----------|--------|---------|---------|"
      printf '%s' "$allowed_rows"
    fi
  } >>"$GITHUB_STEP_SUMMARY"
fi

if [ "$violations" -ne 0 ]; then
  error "$violations reference(s) to unreleased versions of enforced modules. Depend on released versions, and remove replace directives of enforced modules."
  exit 1
fi
echo "Passed: every enforced module is at a released version."
