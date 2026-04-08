#!/usr/bin/env bash
set -euo pipefail

SCHEMA="schema/campaign_schema.json"
ERRORS=0

if [ ! -f "$SCHEMA" ]; then
  echo "Schema not found: $SCHEMA"
  exit 1
fi

if [ $# -ge 1 ]; then
  TARGETS=("$@")
else
  mapfile -t TARGETS < <(find logs -type f -name "*.json" | sort)
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

  echo "Checking: $file"

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
