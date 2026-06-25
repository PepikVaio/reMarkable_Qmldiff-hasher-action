#!/bin/bash
set -eo pipefail

echo "WORKSPACE CONTENT:"
ls -la /github/workspace

# =========================
# INPUTS (GitHub Action)
# =========================
SOURCE_ROOT="/github/workspace/${INPUT_SOURCE_ROOT}"
HASHTAB_ROOT="/github/workspace/${INPUT_HASHTAB_ROOT}"
DEST_REPO="${INPUT_DEST_REPO}"
TOKEN="${INPUT_TOKEN}"
COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE}"

TMP="/destrepo"

# =========================
# CONFIG
# =========================
FILTER_REGEX="${FILTER_REGEX:-.*}"
FILTER_FW_SPLIT="${FILTER_FW_SPLIT:-false}"
IGNORE_HIDDEN="${IGNORE_HIDDEN:-false}"

echo "SOURCE_ROOT: $SOURCE_ROOT"
echo "HASHTAB_ROOT: $HASHTAB_ROOT"
echo "DEST_REPO: $DEST_REPO"

# =========================
# CLONE DEST REPO
# =========================
git clone "https://x:${TOKEN}@github.com/${DEST_REPO}.git" "$TMP"
cd "$TMP"

git config user.email "action@github.com"
git config user.name "Hash Bot"

# =========================
# PROCESSING
# =========================
shopt -s nullglob

for base_dir in "$SOURCE_ROOT"/*/; do

  base=$(basename "$base_dir")

  if [[ "$IGNORE_HIDDEN" == "true" && "$base" == .* ]]; then
    continue
  fi

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

      fw="$fw_full"
      if [[ "$FILTER_FW_SPLIT" == "true" ]]; then
        fw=$(echo "$fw_full" | cut -d'.' -f1-2)
      fi

      hashtab="$HASHTAB_ROOT/$fw/hashtab"

      echo "--------------------------------"
      echo "FILE: $file"
      echo "FW: $fw"
      echo "DEST: $destfile"
      echo "HASHTAB: $hashtab"

      FILE_EXISTS="false"
      [[ -f "$destfile" ]] && FILE_EXISTS="true"

      # =========================
      # COPY FIRST
      # =========================
      cp "$file" "$destfile"

      BEFORE_HASH=""
      AFTER_HASH=""

      if [[ "$file" == *.qmd ]]; then

        if [[ ! -f "$hashtab" ]]; then
          echo "❌ Missing hashtab -> skipping"
          continue
        fi

        BEFORE_HASH=$(md5sum "$destfile" || true)

        qmldiff hash-diffs "$hashtab" "$destfile" || {
          echo "❌ qmldiff failed"
          continue
        }

        AFTER_HASH=$(md5sum "$destfile" || true)

      fi

      git add "$destfile"

      # =========================
      # DETECT CHANGE
      # =========================
      if git diff --cached --quiet -- "$destfile"; then
        echo "ℹ️ no change: $file"
        continue
      fi

      # =========================
      # MESSAGE BUILD
      # =========================
      NAME=$(basename "$file")

      if [[ "$FILE_EXISTS" == "true" ]]; then
        ACTION="Updated"
      else
        ACTION="Created"
      fi

      if [[ "$file" == *.qmd ]]; then
        MSG="QMD ${ACTION} ${NAME} (fw ${fw})"
      else
        MSG="${ACTION} ${NAME}"
      fi

      git commit -m "$MSG"

      echo "✅ $MSG"

    done
  done
done

# =========================
# PUSH
# =========================
git push origin HEAD
echo "✅ DONE"