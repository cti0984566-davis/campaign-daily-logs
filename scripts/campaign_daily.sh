#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: ./scripts/campaign_daily.sh <campaign_name> [date]"
  exit 1
fi

CAMPAIGN_NAME="$1"
DATE="${2:-$(date +%F)}"

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

if command -v code >/dev/null 2>&1; then
  echo "Opening file..."
  code "$FILE"
else
  echo "VS Code command 'code' not found. File created at: $FILE"
fi
