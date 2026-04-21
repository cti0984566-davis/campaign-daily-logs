#!/usr/bin/env bash
set -euo pipefail

TARGET_FILES=()

collect_all_json() {
  while IFS= read -r file; do
    TARGET_FILES+=("$file")
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
    [ -n "$file" ] && TARGET_FILES+=("$file")
  done < <(printf '%s\n' "${files[@]}" | grep -E '\.json$' | sort -u)
}

if [ "$#" -ge 1 ]; then
  if [ "$#" -eq 1 ] && [ "$1" = "*" ]; then
    # 全 JSON を対象
    collect_all_json
  else
    # 引数で指定されたファイルだけを対象
    for file in "$@"; do
      if [ ! -f "$file" ]; then
        echo "File not found: $file"
        exit 1
      fi
      TARGET_FILES+=("$file")
    done
  fi
else
  # 引数がない場合は更新ファイルのみ対象
  collect_updated_json
fi

if [ "${#TARGET_FILES[@]}" -eq 0 ]; then
  echo "No JSON files found."
  exit 0
fi

echo "Validating JSON files..."
./scripts/validate.sh "${TARGET_FILES[@]}"

echo "Adding files..."
git add "${TARGET_FILES[@]}"

if git diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

if [ "$#" -eq 0 ]; then
  COMMIT_MSG="Add/update changed JSON logs (validated)"
elif [ "$#" -eq 1 ] && [ "$1" = "*" ]; then
  COMMIT_MSG="Add/update all JSON logs (validated)"
elif [ "$#" -eq 1 ]; then
  BASENAME="$(basename "$1")"
  COMMIT_MSG="Add/update campaign log: ${BASENAME} (validated)"
else
  COMMIT_MSG="Add/update selected JSON logs (validated)"
fi

echo "Committing: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

echo "Pushing..."
git push

echo "Done."
