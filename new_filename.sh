#!/bin/sh
set -eu

ID_FILE=".local-repo-id"
ALPHABET="ABCDEFGHJKMNPQRSTVWXYZ"
ID_LEN=6
PAD=4

gen_repo_id() {
  LC_ALL=C tr -dc "$ALPHABET" < /dev/urandom | head -c "$ID_LEN"
}

repo_id_in_use() {
  rid="$1"
  find . -maxdepth 1 -name "$rid-*.md" -print -quit | grep -q .
}

next_seq() {
  rid="$1"
  max=0
  echo 1 $max

  find . -maxdepth 1 -name "$rid-*.md" | while IFS= read -r f; do
    echo 2 $max
    n=$(printf '%s\n' "$f" |
        sed -n "s/^.*$rid-\([0-9][0-9]*\)\.md$/\1/p")
    [ -n "$n" ] || continue
    n_raw="$n"
    echo 3 $max
    n_dec=$(printf '%s\n' "$n_raw" | sed 's/^0*//')
    [ -z "$n_dec" ] && n_dec=0

    [ "$n_dec" -gt "$max" ] && max="$n_dec"
    echo 4 $max
  done
  
  echo 5 $max

  printf "%0*d" "$PAD" $((max + 1))
}

# Main
if [ -f "$ID_FILE" ]; then
  REPO_ID=$(cat "$ID_FILE")
else
  while :; do
    REPO_ID=$(gen_repo_id)
    if ! repo_id_in_use "$REPO_ID"; then
      printf '%s\n' "$REPO_ID" > "$ID_FILE"
      break
    fi
  done
fi

SEQ=$(next_seq "$REPO_ID")

echo $REPO_ID
echo $SEQ

FILENAME="$REPO_ID-$SEQ.md"

printf '%s\n' "$FILENAME"
