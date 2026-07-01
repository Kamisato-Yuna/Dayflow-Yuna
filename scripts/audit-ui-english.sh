#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
paths=("$@")
if [ ${#paths[@]} -eq 0 ]; then
  paths=("$root/Dayflow/Dayflow")
fi

allow_file="$root/scripts/ui-english-allowlist.txt"
allow_patterns=()
if [ -f "$allow_file" ]; then
  while IFS=$'\t' read -r pattern reason || [ -n "${pattern-}" ]; do
    [[ -z "${pattern-}" || "${pattern}" =~ ^# ]] && continue
    allow_patterns+=("$pattern")
  done < "$allow_file"
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
  'content\.title'
  'content\.body'
)

pending=0
report=()

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

scan_file() {
  local file="$1"
  local rel_file="${file#$root/}"
  for matcher in "${matchers[@]}"; do
    while IFS= read -r line; do
      line_no="${line%%:*}"
      line_text="${line#*:}"

      while IFS= read -r token; do
        [[ -z "$token" ]] && continue
        str="$token"

        if [[ "$str" =~ [A-Za-z] ]]; then
          if [[ "$str" == *$'\xC0'* || "$str" == *$'\x80'* ]]; then
            continue
          fi

          if should_skip "$str"; then
            continue
          fi

          pending=$((pending + 1))
          report+=("$rel_file:$line_no:$str")
        fi
      done < <(printf '%s
' "$line_text" | perl -ne 'while(/\"((?:[^\\\"]|\\.)+)\"/g){print "$1\n";}')
    done < <(rg -n "$matcher" "$file" || true)
  done
}

for path in "${paths[@]}"; do
  if [ -d "$path" ]; then
    while IFS= read -r file; do
      scan_file "$file"
    done < <(rg --files "$path" -g '*.swift')
  elif [ -f "$path" ]; then
    scan_file "$path"
  fi
done

if (( ${#report[@]} > 0 )); then
  printf '%s\n' "${report[@]}" | sort -u
  echo "pending_count=${pending}"
  exit 1
fi

echo "No untranslated-inline-string-like matches found."
exit 0
