#!/usr/bin/env bash
set -euo pipefail

DATE="${1:-$(date +%F)}"
YEAR="$(date -d "$DATE" +%Y)"
MONTH="$(date -d "$DATE" +%m)"
DIR="logs/$YEAR/$MONTH"
FILE="$DIR/$DATE.json"

mkdir -p "$DIR"

if [ -f "$FILE" ]; then
  echo "Already exists: $FILE"
else
  cat > "$FILE" <<JSON
{
  "date": "$DATE",
  "timezone": "Asia/Tokyo",
  "title": "$(date -d "$DATE" +%Y/%m/%d)_サイバー攻撃キャンペーン日次概要",
  "items": []
}
JSON
  echo "Created: $FILE"
fi

if command -v code >/dev/null 2>&1; then
  echo "Opening file..."
  code "$FILE"
else
  echo "VS Code command 'code' not found. File created at: $FILE"
fi
