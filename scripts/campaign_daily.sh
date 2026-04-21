#!/usr/bin/env bash
set -euo pipefail

created_files=()

create_file() {
  local file="$1"
  local campaign_name="$2"
  local date="$3"
  local dir

  dir="$(dirname "$file")"
  mkdir -p "$dir"

  if [ -f "$file" ]; then
    echo "Already exists: $file"
  else
    cat > "$file" <<JSON
{
  "date": "$date",
  "timezone": "Asia/Tokyo",
  "campaign": {
    "name": "$campaign_name",
    "aliases": [],
    "cluster": "",
    "suspected_actor": "",
    "attribution_confidence": "medium"
  },
  "items": []
}
JSON
    echo "Created: $file"
  fi

  created_files+=("$file")
}

# --------------------------------------------------
# 1) 引数なし:
#    カレントディレクトリに今日の日付ファイルを作成
#    campaign.name は現在ディレクトリ名を使う
# --------------------------------------------------
if [ "$#" -eq 0 ]; then
  DATE="$(date +%F)"
  CAMPAIGN_NAME="$(basename "$PWD")"
  FILE="./$DATE.json"

  echo "Mode: current directory"
  echo "Campaign: $CAMPAIGN_NAME"
  echo "Date: $DATE"
  echo "Target: $FILE"
  echo "--------------------"

  create_file "$FILE" "$CAMPAIGN_NAME" "$DATE"

# --------------------------------------------------
# 2) 引数に .json パスが含まれる場合:
#    そのパスに直接ファイルを作成
#    campaign.name は親ディレクトリ名を使う
# --------------------------------------------------
elif [ "$#" -eq 1 ] && [[ "$1" == *.json ]]; then
  FILE="$1"
  BASENAME="$(basename "$FILE" .json)"
  DATE="$BASENAME"
  CAMPAIGN_NAME="$(basename "$(dirname "$FILE")")"

  if [[ ! "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "ERROR: Filename must be YYYY-MM-DD.json"
    echo "Example: ./scripts/campaign_daily.sh campaigns/APT28/2026-04-21.json"
    exit 1
  fi

  echo "Mode: explicit file path"
  echo "Campaign: $CAMPAIGN_NAME"
  echo "Date: $DATE"
  echo "Target: $FILE"
  echo "--------------------"

  create_file "$FILE" "$CAMPAIGN_NAME" "$DATE"

# --------------------------------------------------
# 3) 従来モード:
#    campaign 名を複数指定
#    最後の引数が YYYY-MM-DD なら日付として扱う
# --------------------------------------------------
else
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

  echo "Mode: campaign name(s)"
  echo "Date: $DATE"
  echo "Targets:"
  for ((i=1; i<=CAMPAIGN_COUNT; i++)); do
    echo "  - ${!i}"
  done
  echo "--------------------"

  for ((i=1; i<=CAMPAIGN_COUNT; i++)); do
    CAMPAIGN_NAME="${!i}"
    FILE="campaigns/$CAMPAIGN_NAME/$DATE.json"
    create_file "$FILE" "$CAMPAIGN_NAME" "$DATE"
  done
fi

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
