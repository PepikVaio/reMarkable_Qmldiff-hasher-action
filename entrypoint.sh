#!/bin/bash
set -eo pipefail

# ============================
# INPUTS (GitHub Action)
# ============================
SOURCE_ROOT="/github/workspace/${INPUT_SOURCE_ROOT}"
HASHTAB_ROOT="/github/workspace/${INPUT_HASHTAB_ROOT}"
DEST_REPO_NAME="${INPUT_DEST_REPO_NAME}"
REPO_ACCESS_TOKEN="${INPUT_REPO_ACCES_TOKEN}"
COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE}"

TMP="/destrepo"

# ============================
# CONFIG
# ============================
FILTER_REGEX="${FILTER_REGEX:-.*}"
FILTER_FW_SPLIT="${FILTER_FW_SPLIT:-false}"
IGNORE_HIDDEN="${IGNORE_HIDDEN:-false}"

# ============================
# CLONE DEST REPO
# ============================
git clone "https://x:${REPO_ACCESS_TOKEN}@github.com/${DEST_REPO_NAME}.git" "$TMP"
cd "$TMP"

git config user.email "action@github.com"
git config user.name "Hash Bot"

echo "SOURCE_ROOT: $SOURCE_ROOT"
echo "HASHTAB_ROOT: $HASHTAB_ROOT"
echo "DEST: $DEST_REPO_NAME"

# ============================
# PROCESSING
# ============================
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

      # ============================
      # PATH FIX (důležité)
      # ============================
      rel_path="${file#$SOURCE_ROOT/}"
      destfile="$TMP/$rel_path"

      mkdir -p "$(dirname "$destfile")"

      # FW handling
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

      # ============================
      # COPY FIRST
      # ============================
      cp "$file" "$destfile"

      # ============================
      # QMD HASH
      # ============================
      if [[ "$file" == *.qmd ]]; then

        if [[ ! -f "$hashtab" ]]; then
          echo "⚠️ Missing hashtab -> skipping"
          continue
        fi

        qmldiff hash-diffs "$hashtab" "$destfile" || {
          echo "❌ qmldiff failed"
          continue
        }

      fi

      # ============================
      # STAGE ONLY THIS FILE
      # ============================
      git add "$destfile"

      # IMPORTANT: staged diff
      if git diff --cached --quiet -- "$destfile"; then
        echo "No change: $file"
        continue
      fi

      # ============================
      # MESSAGE BUILD
      # ============================
      if [[ -n "$COMMIT_MESSAGE" ]]; then
        MSG="$COMMIT_MESSAGE"
      else
        NAME=$(basename "$file")

        if [[ "$file" == *.qmd ]]; then
          MSG="Updated ${NAME} (fw ${fw})"
        else
          MSG="Updated ${NAME}"
        fi
      fi

      git commit -m "$MSG"
      echo "✅ $MSG"

    done
  done
done

# ============================
# PUSH
# ============================
git push origin HEAD

echo "DONE"