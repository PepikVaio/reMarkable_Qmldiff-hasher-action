#!/bin/bash
set -eo pipefail

SOURCE_ROOT="${INPUT_SOURCE_ROOT}"
HASHTAB_ROOT="${INPUT_HASHTAB_ROOT}"
DEST_REPO="${INPUT_DEST_REPO}"
TOKEN="${INPUT_TOKEN}"

TMP="/destrepo"

FILTER_REGEX="${FILTER_REGEX:-.*}"
FILTER_FW_SPLIT="${FILTER_FW_SPLIT:-false}"
IGNORE_HIDDEN="${IGNORE_HIDDEN:-false}"

git clone "https://x:${TOKEN}@github.com/${DEST_REPO}.git" "$TMP"
cd "$TMP"

git config user.email "action@github.com"
git config user.name "Hash Bot"

CHANGES=0

for base_dir in "$SOURCE_ROOT"/*/; do

  base=$(basename "$base_dir")

  [[ "$IGNORE_HIDDEN" == "true" && "$base" == .* ]] && continue

  shopt -s nullglob
  fw_dirs=("$base_dir"*/)

  for dir in "${fw_dirs[@]}"; do

    fw_full=$(basename "$dir")
    [[ "$fw_full" =~ $FILTER_REGEX ]] || continue

    find "$dir" -type f \
      ! -path "*/.*/*" \
      ! -path "*/.*" | while IFS= read -r file; do

      [[ ! -f "$file" ]] && continue

      rel_path="${file#$SOURCE_ROOT/}"
      destfile="$TMP/$rel_path"

      mkdir -p "$(dirname "$destfile")"

      if [[ "$file" == *.qmd ]]; then

        if [[ "$FILTER_FW_SPLIT" == "true" ]]; then
          fw=$(echo "$fw_full" | cut -d'.' -f1-2)
        else
          fw="$fw_full"
        fi

        hashtab="$HASHTAB_ROOT/$fw/hashtab"

        if [[ ! -f "$hashtab" ]]; then
          echo "⚠️ Missing hashtab: $fw"
          continue
        fi

        cp "$file" "$destfile"

        echo "🔧 hashing: $file"
        qmldiff hash-diffs "$hashtab" "$destfile"

      else
        cp "$file" "$destfile"
      fi

      git add "$destfile"
      CHANGES=1

    done
  done
done

if git diff --cached --quiet; then
  echo "No changes"
  exit 0
fi

git commit -m "Update hashed QMD files"
git push origin HEAD