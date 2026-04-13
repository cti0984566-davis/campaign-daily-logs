#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: ./scripts/campaign_daily.sh <campaign_name> [campaign_name ...] [date]"
  exit 1
fi

# 最後の引数が YYYY-MM-DD 形式なら日付として扱う
last_arg="${!#}"
if [[ "$last_arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  DATE="$last_arg"
  CAMPAIGN_COUNT=$(($# - 1))
else
  DATE="$(date +%F)"
  CAMPAIGN_COUNT=$#
fi

if [ "$CAMPAIGN_COUNT" -lt 1 ]; then
  echo "ERROR: No campaign name provided."
  exit 1
fi

echo "Date: $DATE"
echo "Targets:"
for ((i=1; i<=CAMPAIGN_COUNT; i++)); do
  echo "  - ${!i}"
done
echo "--------------------"

created_files=()

for ((i=1; i<=CAMPAIGN_COUNT; i++)); do
  CAMPAIGN_NAME="${!i}"
  DIR="campaigns/$CAMPAIGN_NAME"
  FILE="$DIR/$DATE.json"

  mkdir -p "$DIR"

  if [ -f "$FILE" ]; then
    echo "Already exists: $FILE"
  else
    cat > "$FILE" <<JSON
{
  "date": "$DATE",
  "timezone": "Asia/Tokyo",
  "campaign": {
    "name": "$CAMPAIGN_NAME",
    "aliases": [],
    "cluster": "",
    "suspected_actor": "",
    "attribution_confidence": "medium"
  },
  "items": []
}
JSON
    echo "Created: $FILE"
  fi

  created_files+=("$FILE")
done

echo "--------------------"

if command -v code >/dev/null 2>&1; then
  echo "Opening file(s)..."
  code "${created_files[@]}"
else
  echo "VS Code command 'code' not found."
  echo "Created/target files:"
  for file in "${created_files[@]}"; do
    echo "  - $file"
  done
fi
