#!/bin/bash
set -eo pipefail

echo "=============================="
echo "WORKSPACE DEBUG"
echo "=============================="
ls -la /github/workspace

echo "=============================="
echo "INPUT DEBUG"
echo "=============================="

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
# CONFIG
# =========================
FILTER_REGEX="${FILTER_REGEX:-.*}"
FILTER_FW_SPLIT="${FILTER_FW_SPLIT:-false}"
IGNORE_HIDDEN="${IGNORE_HIDDEN:-false}"

echo "SOURCE_ROOT   = $SOURCE_ROOT"
echo "HASHTAB_ROOT  = $HASHTAB_ROOT"
echo "DEST_REPO     = $DEST_REPO"

echo "=============================="

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
for base_dir in "$SOURCE_ROOT"/*/; do

  [[ -d "$base_dir" ]] || continue

  base=$(basename "$base_dir")

  # skip hidden dirs
  if [[ "$IGNORE_HIDDEN" == "true" && "$base" == .* ]]; then
    continue
  fi

  shopt -s nullglob
  fw_dirs=("$base_dir"*/)

  for dir in "${fw_dirs[@]}"; do

    [[ -d "$dir" ]] || continue

    fw_full=$(basename "$dir")

    # =========================
    # FW NORMALIZATION (FIX 🔥)
    # =========================
    fw=$(echo "$fw_full" | awk -F. '{print $1"."$2}')

    [[ "$fw_full" =~ $FILTER_REGEX ]] || continue

    echo "--------------------------------"
    echo "FW FULL: $fw_full"
    echo "FW USED: $fw"

    find "$dir" -type f \
      ! -path "*/.*/*" \
      ! -path "*/.*" | while IFS= read -r file; do

      [[ -f "$file" ]] || continue

      echo "FILE: $file"

      # relativní cesta v cíli
      rel_path="${file#$SOURCE_ROOT/}"
      destfile="$TMP/$rel_path"

      mkdir -p "$(dirname "$destfile")"

      # =========================
      # COPY
      # =========================
      cp "$file" "$destfile"

      # =========================
      # QMD HASH
      # =========================
      if [[ "$file" == *.qmd ]]; then

        hashtab="$HASHTAB_ROOT/$fw/hashtab"

        echo "HASHTAB: $hashtab"

        if [[ ! -f "$hashtab" ]]; then
          echo "❌ Missing hashtab -> skipping"
          continue
        fi

        BEFORE=$(md5sum "$destfile" || true)

        qmldiff hash-diffs "$hashtab" "$destfile" || {
          echo "❌ qmldiff failed"
          continue
        }

        AFTER=$(md5sum "$destfile" || true)

        if [[ "$BEFORE" != "$AFTER" ]]; then
          echo "✅ QMD modified"
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
# COMMIT + PUSH
# =========================
if git diff --cached --quiet; then
  echo "No changes in repo"
  exit 0
fi

git commit -m "${COMMIT_MESSAGE:-Update hashed QMD files}"
git push origin HEAD

echo "=============================="
echo "DONE"