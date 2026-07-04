#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

paths=("$@")
if [ ${#paths[@]} -eq 0 ]; then
  paths=("$ROOT_DIR/Dayflow/Dayflow")
fi

allow_file="$ROOT_DIR/scripts/ui-english-allowlist.txt"
allow_patterns=()
allow_missing=0

while IFS=$'\t' read -r pattern reason _ || [[ -n "${pattern-}" ]]; do
  [[ -z "${pattern-}" || "${pattern}" == \#* ]] && continue
  if [[ -z "${reason-}" ]]; then
    echo "Allowlist format error: pattern '$pattern' has no reason" >&2
    allow_missing=1
    continue
  fi
  allow_patterns+=("$pattern")
done < "$allow_file"

if [ "$allow_missing" -ne 0 ]; then
  echo "Fix allowlist reason columns before running scanner." >&2
  exit 2
fi

matchers=(
  'Text\('
  'Button\('
  'Label\('
  'TextField\('
  'SecureField\('
  'Toggle\('
  'Picker\('
  '\.navigationTitle\('
  '\.help\('
  '\.accessibilityLabel\('
  'Alert\('
  '\.alert\('
  'content\.title'
  'content\.body'
)

should_skip() {
  local str="$1"
  local pat
  for pat in "${allow_patterns[@]}"; do
    if [[ "$str" == *"$pat"* ]]; then
      return 0
    fi
  done
  return 1
}

has_interpolation_only_text() {
  local value="$1"
  [[ "$value" =~ ^[[:space:]]*\\\(.+\\\)[[:space:]]*$ ]]
}

extract_visible_text() {
  local text="$1"
  printf '%s' "$text" | perl -pe 's/\\\([^)]*\)//g'
}

scan_file() {
  local file="$1"
  local rel_file="${file#$ROOT_DIR/}"
  local matcher
  local line
  local line_no
  local line_text
  local token
  local str
  local trimmed
  local visible_text

  for matcher in "${matchers[@]}"; do
    while IFS= read -r line; do
      line_no="${line%%:*}"
      line_text="${line#*:}"

      while IFS= read -r token; do
        [[ -z "$token" ]] && continue
        str="$token"
        trimmed="$(printf '%s' "$str" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

        # Skip interpolation-only placeholders and punctuation-only strings.
        if has_interpolation_only_text "$trimmed"; then
          continue
        fi
        if [[ "$trimmed" =~ ^[[:punct:]]+$ ]]; then
          continue
        fi

        visible_text="$(extract_visible_text "$trimmed")"
        if [[ ! "$visible_text" =~ [A-Za-z] ]]; then
          continue
        fi

        if should_skip "$trimmed"; then
          continue
        fi

        pending_files+=("$rel_file:$line_no:$trimmed")
      done < <(printf '%s\n' "$line_text" | perl -ne 'while(/\"((?:[^\\\"]|\\.)+)\"/g){print "$1\n";}')
    done < <(rg -n --max-columns 2000 "$matcher" "$file" || true)
  done
}

pending_files=()

for path in "${paths[@]}"; do
  if [ -d "$path" ]; then
    while IFS= read -r file; do
      scan_file "$file"
    done < <(rg --files "$path" -g '*.swift' || true)
  elif [ -f "$path" ]; then
    scan_file "$path"
  fi
done

if (( ${#pending_files[@]} > 0 )); then
  sorted_pending="$(printf '%s\n' "${pending_files[@]}" | sort -u)"
  printf '%s\n' "$sorted_pending"
  pending_count="$(printf '%s\n' "$sorted_pending" | wc -l | tr -d ' ')"
  echo "pending_count=$pending_count"
  exit 1
fi

echo "No untranslated-inline-string-like matches found."
exit 0
