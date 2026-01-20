#!/usr/bin/bash
set -euo pipefail

id_file=".local-repo-id"
alphabet="ABCDEFGHJKMNPQRSTVWXYZ"
id_len=6
pad=4

gen_repo_id() {
  tr -dc "$alphabet" < /dev/urandom | head -c "$id_len" || true
  # || true is to avoid non-zero exit code if head cuts tr output
}

repo_id_in_use() {
  local rid="$1"
  if find . -maxdepth 1 -name "$rid-*.md" -print -quit | grep -q .; then
    echo "yes"
  else
    echo "no"
  fi
}

next_seq() {
  local rid="$1"
  local max=0
  local n n_dec

  shopt -s nullglob
  for f in "$rid-"*.md; do
    [[ $f =~ ^$rid-([0-9]+)\.md$ ]] || continue
    n="${BASH_REMATCH[1]}"
    n_dec=$((10#$n))   # force decimal, strips padding safely
    (( n_dec > max )) && max="$n_dec"
  done
  shopt -u nullglob

  printf "%0*d" "$pad" $((max + 1))
}

# ---- main ----

if [[ -f $id_file ]]; then
  repo_id=$(<"$id_file")
else
  while :; do
    repo_id=$(gen_repo_id)
    if [[ $(repo_id_in_use "$repo_id")  == no ]]; then
      printf '%s\n' "$repo_id" > "$id_file"
      break
    fi
  done
fi

seq=$(next_seq "$repo_id")
filename="$repo_id-$seq.md"

printf '%s\n' "$filename"