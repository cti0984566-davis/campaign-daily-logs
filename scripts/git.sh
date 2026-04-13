#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: ./scripts/git.sh <campaign1> [campaign2 ...]"
  exit 1
fi

TARGET_FILES=()

for campaign in "$@"; do
  dir="campaigns/$campaign"

  if [ ! -d "$dir" ]; then
    echo "Directory not found: $dir"
    exit 1
  fi

  while IFS= read -r file; do
    TARGET_FILES+=("$file")
  done < <(find "$dir" -type f -name "*.json" | sort)
done

if [ "${#TARGET_FILES[@]}" -eq 0 ]; then
  echo "No JSON files found in specified campaign directories."
  exit 1
fi

echo "Validating campaign directories..."
./scripts/validate.sh "$@"

echo "Adding files..."
git add "${TARGET_FILES[@]}"

if git diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

if [ "$#" -eq 1 ]; then
  COMMIT_MSG="Add/update campaign log: $1 (validated)"
else
  COMMIT_MSG="Add/update campaign logs (validated)"
fi

echo "Committing: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

echo "Pushing..."
git push

echo "Done."
