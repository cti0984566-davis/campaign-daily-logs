#!/usr/bin/env bash
set -euo pipefail

ERRORS=0

if [ $# -ge 1 ]; then
  TARGETS=("$@")
else
  mapfile -t TARGETS < <(find logs campaigns -type f -name "*.json" | sort)
fi

if [ ${#TARGETS[@]} -eq 0 ]; then
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
  else
    SCHEMA="schema/daily_campaign_schema.json"
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
