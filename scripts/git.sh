#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: ./scripts/git_daily.sh <file1> [file2 ...]"
  exit 1
fi

for FILE in "$@"; do
  if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
  fi
done

echo "Validating files..."
./scripts/validate.sh "$@"

echo "Adding files..."
git add "$@"

if git diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

FIRST_DATE=$(basename "$1" .json)

if [ $# -eq 1 ]; then
  COMMIT_MSG="Add daily log $FIRST_DATE (validated)"
else
  COMMIT_MSG="Add/update daily logs (validated)"
fi

echo "Committing: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

echo "Pushing..."
git push

echo "Done."
