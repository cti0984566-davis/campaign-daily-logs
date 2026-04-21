#!/usr/bin/env bash
set -euo pipefail

ERRORS=0
TARGETS=()

collect_all_json() {
  while IFS= read -r file; do
    TARGETS+=("$file")
  done < <(find logs campaigns -type f -name "*.json" | sort)
}

collect_updated_json() {
  local files=()

  # Git 管理下の変更済みファイル（未stage）
  while IFS= read -r file; do
    files+=("$file")
  done < <(git diff --name-only -- logs campaigns 2>/dev/null || true)

  # Git 管理下の変更済みファイル（stage済み）
  while IFS= read -r file; do
    files+=("$file")
  done < <(git diff --cached --name-only -- logs campaigns 2>/dev/null || true)

  # Git 未管理の新規ファイル
  while IFS= read -r file; do
    files+=("$file")
  done < <(git ls-files --others --exclude-standard logs campaigns 2>/dev/null || true)

  if [ "${#files[@]}" -eq 0 ]; then
    return 0
  fi

  while IFS= read -r file; do
    [ -n "$file" ] && TARGETS+=("$file")
  done < <(printf '%s\n' "${files[@]}" | grep -E '\.json$' | sort -u)
}

if [ "$#" -ge 1 ]; then
  if [ "$#" -eq 1 ] && [ "$1" = "*" ]; then
    # 全 JSON を対象
    collect_all_json
  else
    # 引数で指定されたファイルだけを対象
    for file in "$@"; do
      TARGETS+=("$file")
    done
  fi
else
  # 引数がない場合は更新ファイルのみ対象
  collect_updated_json
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "No JSON files found."
  exit 0
fi

for file in "${TARGETS[@]}"; do
  if [ ! -f "$file" ]; then
    echo "File not found: $file"
    ERRORS=$((ERRORS + 1))
    echo "--------------------"
    continue
  fi

  # スキーマ切り替え
  if [[ "$file" == campaigns/* ]]; then
    SCHEMA="schema/specific_campaign_schema.json"
  elif [[ "$file" == logs/* ]]; then
    SCHEMA="schema/daily_campaign_schema.json"
  else
    echo "Unknown file type: $file"
    ERRORS=$((ERRORS + 1))
    echo "--------------------"
    continue
  fi

  if [ ! -f "$SCHEMA" ]; then
    echo "Schema not found: $SCHEMA"
    ERRORS=$((ERRORS + 1))
    echo "--------------------"
    continue
  fi

  echo "Checking: $file"
  echo "Using schema: $SCHEMA"

  if ajv validate -s "$SCHEMA" -d "$file" --strict=false; then
    echo "OK: $file"
  else
    echo "NG: $file"
    ERRORS=$((ERRORS + 1))
  fi

  echo "--------------------"
done

if [ "$ERRORS" -gt 0 ]; then
  echo "Validation completed with $ERRORS error(s)."
  exit 1
else
  echo "Validation completed successfully."
  exit 0
fi
