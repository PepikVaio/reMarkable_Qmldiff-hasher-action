#!/bin/bash
set -e

# =========================
# INPUTS (GitHub Action)
# =========================
SOURCE_ROOT="${INPUT_SOURCE_ROOT}"
HASHTAB_ROOT="${INPUT_HASHTAB_ROOT}"
DEST_REPO="${INPUT_DEST_REPO}"
TOKEN="${INPUT_TOKEN}"
COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE}"

TMP="/destrepo"

# =========================
# CONFIG (FROM WORKFLOW env)
# =========================
FILTER_REGEX="${FILTER_REGEX:-.*}"
FILTER_FW_SPLIT="${FILTER_FW_SPLIT:-false}"
IGNORE_HIDDEN="${IGNORE_HIDDEN:-false}"

# =========================
# CLONE DEST REPO
# =========================
git clone "https://x:${TOKEN}@github.com/${DEST_REPO}.git" "$TMP"

# =========================
# HASH + COPY LOGIC (TVŮJ KÓD)
# =========================
for base_dir in "$SOURCE_ROOT"/*/; do

  base=$(basename "$base_dir")

  # =========================
  # SKIP hidden dirs
  # =========================
  if [[ "$IGNORE_HIDDEN" == "true" ]]; then
    [[ "$base" == .* ]] && continue
  fi

  shopt -s nullglob
  fw_dirs=("$base_dir"*/)

  for dir in "${fw_dirs[@]}"; do

    fw_full=$(basename "$dir")

    # FW filter
    [[ "$fw_full" =~ $FILTER_REGEX ]] || continue

    find "$dir" -type f \
      ! -path "*/.*/*" \
      ! -path "*/.*" | while IFS= read -r file; do

      [ -f "$file" ] || continue

      rel_path="${file#$SOURCE_ROOT/}"
      destfile="$TMP/$rel_path"

      mkdir -p "$(dirname "$destfile")"

      # =========================
      # QMD processing
      # =========================
      if [[ "$file" == *.qmd ]]; then

        if [[ "$FILTER_FW_SPLIT" == "true" ]]; then
          fw=$(echo "$fw_full" | cut -d'.' -f1-2)
        else
          fw="$fw_full"
        fi

        hashtab="$HASHTAB_ROOT/$fw/hashtab"

        if [ ! -f "$hashtab" ]; then
          echo "⚠️ Missing hashtab for $fw"
          continue
        fi

		cp "$file" "$destfile"
		qmldiff hash-diffs "$hashtab" "$destfile"
		git add "$destfile"

		# COMMIT_FILE="$(basename "$file")"
		# git commit -m "Updated $COMMIT_FILE to fw $fw" || true
		git commit -m "Updated to fw $fw" || true
		echo "✅ QMD hashed + committed: $file"

	  else
		cp "$file" "$destfile"

		git add "$destfile"
		git commit -m "Updated to fw $fw" || true

		echo "📄 Copied + committed: $file"
	  fi



    done
  done
done

# =========================
# COMMIT + PUSH
# =========================
cd "$TMP"

git config user.email "action@github.com"
git config user.name "Hash Bot"

git push origin HEAD