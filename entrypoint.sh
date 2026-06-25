#!/bin/bash
set -eo pipefail

echo "WORKSPACE CONTENT:"
ls -la /
ls -la /github/workspace

# =========================
# INPUTS (GitHub Action)
# =========================
SOURCE_ROOT="/github/workspace/${INPUT_SOURCE_ROOT}"
HASHTAB_ROOT="${INPUT_HASHTAB_ROOT}"
DEST_REPO="${INPUT_DEST_REPO}"
TOKEN="${INPUT_TOKEN}"
COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE}"

TMP="/destrepo"

# =========================
# CONFIG (fallback + env support)
# =========================
FILTER_REGEX="${FILTER_REGEX:-^[0-9]+\.[0-9]}"
FILTER_FW_SPLIT="${FILTER_FW_SPLIT:-true}"
IGNORE_HIDDEN="${IGNORE_HIDDEN:-true}"

echo "INPUT_SOURCE_ROOT: ${INPUT_SOURCE_ROOT}"
echo "SOURCE_ROOT: $SOURCE_ROOT"
echo "HASHTAB_ROOT: $HASHTAB_ROOT"
echo "DEST_REPO: $DEST_REPO"

# =========================
# SAFETY CHECK (DŮLEŽITÉ)
# =========================
if [[ ! -d "$SOURCE_ROOT" ]]; then
  echo "❌ SOURCE_ROOT does not exist: $SOURCE_ROOT"
  echo "👉 Available folders:"
  ls -ლა /github/workspace
  exit 1
fi

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
CHANGED=0

for base_dir in "$SOURCE_ROOT"/*/; do

  [[ ! -d "$base_dir" ]] && continue

  base=$(basename "$base_dir")

  # skip hidden dirs
  if [[ "$IGNORE_HIDDEN" == "true" && "$base" == .* ]]; then
    continue
  fi

  shopt -s nullglob
  fw_dirs=("$base_dir"*/)

  for dir in "${fw_dirs[@]}"; do

    [[ ! -d "$dir" ]] && continue

    fw_full=$(basename "$dir")

    [[ "$fw_full" =~ $FILTER_REGEX ]] || continue

    find "$dir" -type f \
      ! -path "*/.*/*" \
      ! -path "*/.*" | while IFS= read -r file; do

      [[ ! -f "$file" ]] && continue

      rel_path="${file#$SOURCE_ROOT/}"
      destfile="$TMP/$rel_path"

      mkdir -p "$(dirname "$destfile")"

      echo "--------------------------------"
      echo "FILE: $file"
      echo "FW: $fw_full"

      # =========================
      # FW logic
      # =========================
      if [[ "$FILTER_FW_SPLIT" == "true" ]]; then
        fw=$(echo "$fw_full" | cut -d'.' -f1-2)
      else
        fw="$fw_full"
      fi

      hashtab="$HASHTAB_ROOT/$fw/hashtab"
      echo "HASHTAB: $hashtab"

      cp "$file" "$destfile"

      # =========================
      # QMD HASH
      # =========================
      if [[ "$file" == *.qmd ]]; then

        if [[ ! -f "$hashtab" ]]; then
          echo "❌ Missing hashtab -> skipping"
          continue
        fi

        BEFORE=$(md5sum "$destfile" | awk '{print $1}')

        qmldiff hash-diffs "$hashtab" "$destfile" || {
          echo "❌ qmldiff failed"
          continue
        }

        AFTER=$(md5sum "$destfile" | awk '{print $1}')

        if [[ "$BEFORE" != "$AFTER" ]]; then
          echo "✅ QMD changed"
          CHANGED=1
        else
          echo "⚠️ No change"
        fi

      else
        echo "📄 non-qmd file"
      fi

      git add "$destfile"

    done
  done
done

# =========================
# COMMIT
# =========================
if git diff --cached --quiet; then
  echo "No changes in repo"
  exit 0
fi

git commit -m "${COMMIT_MESSAGE:-Update hashed QMD files}"
git push origin HEAD

echo "✅ DONE"