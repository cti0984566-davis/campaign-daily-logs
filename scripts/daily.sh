#!/usr/bin/env bash
set -euo pipefail

created_files=()

create_file() {
  local file="$1"
  local date="$2"
  local dir
  local title

  dir="$(dirname "$file")"
  mkdir -p "$dir"

  title="$(date -d "$date" +%Y/%m/%d)_サイバー攻撃キャンペーン日次概要"

  if [ -f "$file" ]; then
    echo "Already exists: $file"
  else
    cat > "$file" <<JSON
{
  "date": "$date",
  "timezone": "Asia/Tokyo",
  "title": "$title",
  "items": []
}
JSON
    echo "Created: $file"
  fi

  created_files+=("$file")
}

# --------------------------------------------------
# 1) 引数なし:
#    今日の日付で logs/YYYY/MM/YYYY-MM-DD.json を作成
# --------------------------------------------------
if [ "$#" -eq 0 ]; then
  DATE="$(date +%F)"
  YEAR="$(date -d "$DATE" +%Y)"
  MONTH="$(date -d "$DATE" +%m)"
  FILE="logs/$YEAR/$MONTH/$DATE.json"

  echo "Mode: default"
  echo "Date: $DATE"
  echo "Target: $FILE"
  echo "--------------------"

  create_file "$FILE" "$DATE"

# --------------------------------------------------
# 2) 引数に .json パス:
#    そのパスに直接ファイルを作成
# --------------------------------------------------
elif [ "$#" -eq 1 ] && [[ "$1" == *.json ]]; then
  FILE="$1"
  BASENAME="$(basename "$FILE" .json)"
  DATE="$BASENAME"

  if [[ ! "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "ERROR: Filename must be YYYY-MM-DD.json"
    echo "Example: ./scripts/daily.sh logs/2026/04/2026-04-21.json"
    exit 1
  fi

  echo "Mode: explicit file path"
  echo "Date: $DATE"
  echo "Target: $FILE"
  echo "--------------------"

  create_file "$FILE" "$DATE"

# --------------------------------------------------
# 3) 引数に日付:
#    logs/YYYY/MM/YYYY-MM-DD.json を作成
# --------------------------------------------------
elif [ "$#" -eq 1 ] && [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  DATE="$1"
  YEAR="$(date -d "$DATE" +%Y)"
  MONTH="$(date -d "$DATE" +%m)"
  FILE="logs/$YEAR/$MONTH/$DATE.json"

  echo "Mode: date"
  echo "Date: $DATE"
  echo "Target: $FILE"
  echo "--------------------"

  create_file "$FILE" "$DATE"

else
  echo "Usage:"
  echo "  ./scripts/daily.sh"
  echo "  ./scripts/daily.sh YYYY-MM-DD"
  echo "  ./scripts/daily.sh logs/YYYY/MM/YYYY-MM-DD.json"
  exit 1
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
