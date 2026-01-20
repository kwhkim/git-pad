#!/usr/bin/bash
set -euo pipefail

ID_FILE=".local-repo-id"
ALPHABET="ABCDEFGHJKMNPQRSTVWXYZ"
ID_LEN=6
PAD=4

# Generate a random alphabetic UID
gen_uid() {
  LC_ALL=C tr -dc "$ALPHABET" < /dev/urandom | head -c "$ID_LEN"
}

# Check whether a UID already exists in filenames
uid_in_use() {
  local uid="$1"
  ls "${uid}-"*.md >/dev/null 2>&1
}

# Get next sequence number for a UID
next_seq() {
  local uid="$1"
  local last

  last=$(
    ls "${uid}-"*.md 2>/dev/null \
      | sed -n "s/^${uid}-\([0-9]\+\)\.md$/\1/p" \
      | sort -n \
      | tail -1
  )

  if [[ -z "${last:-}" ]]; then
    printf "%0*d" "$PAD" 1
  else
    printf "%0*d" "$PAD" "$((10#$last + 1))"
  fi
}

# Main logic
if [[ -f "$ID_FILE" ]]; then
  repoID=$(cat "$ID_FILE")
else
  while :; do
    repoID=$(gen_uid)
    if ! uid_in_use "$repoID"; then
      echo "$repoID" > "$ID_FILE"
      break
    fi
  done
fi

SEQ=$(next_seq "$repoID")
FILENAME="${repoID}-${SEQ}.md"

echo "$FILENAME"
