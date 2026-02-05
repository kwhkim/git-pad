#!/usr/bin/bash
#set -euo pipefail

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

secure_repo_id() {
  if [[ -f $id_file ]]; then
    repo_id=$(< "$id_file")
    echo "$repo_id"
  else
    while :; do
      repo_id=$(gen_repo_id)
      if [[ $(repo_id_in_use "$repo_id") == no ]]; then
        printf '%s\n' "$repo_id" > "$id_file"
        break
      fi
    done
  fi
}

next_seq() {
  local rid="$1"
  local ext="$2"
  local max=0
  local n n_dec

  shopt -s nullglob
  for f in "issues/""$rid-"*"$ext"; do
    [[ $f =~ ^issues/$rid-([0-9]+)$ext$ ]] || continue
    n="${BASH_REMATCH[1]}"
    n_dec=$((10#$n)) # force decimal, strips padding safely
    ((n_dec > max)) && max="$n_dec"
  done
  shopt -u nullglob

  printf "%0*d" "$pad" $((max + 1))
}

next_seq_comment() {
  local rid="$1"
  local ext="$2"
  local issue_id="$3"
  local max=0
  local n n_dec

  shopt -s nullglob
  for f in "issues/$issue_id/comments/"*; do
    [[ $f =~ ^issues/"$issue_id"/comments/$rid-([0-9]+)$ext$ ]] || continue
    n="${BASH_REMATCH[1]}"
    n_dec=$((10#$n)) # force decimal, strips padding safely
    ((n_dec > max)) && max="$n_dec"
  done
  shopt -u nullglob

  printf "%0*d" "$pad" $((max + 1))
}

new_filename_comment() {
  if [[ $# -lt 2 ]]; then
    echo "new_comment_file <ext> <issue_id>"
  fi

  ext=$1
  issue_id=$2
  

  if [[ -f $id_file ]]; then
    repo_id=$(< "$id_file")
  else
    while :; do
      repo_id=$(gen_repo_id)
      if [[ $(repo_id_in_use "$repo_id") == no ]]; then
        printf '%s\n' "$repo_id" > "$id_file"
        break
      fi
    done
  fi

  seq=$(next_seq_comment "$repo_id" "$ext" "$issue_id")
  filename="$repo_id-$seq$ext"

  printf '%s\n' "$filename"


}

# ---- main ----

new_filename() {
  local ext

  #if [[ -n $1 ]]; then
  #  ext="$1"
  #else
  #  ext=".md"
  #fi
  if [[ $# -eq 0 ]]; then
    ext=".md"
  else
    ext="$1"
  fi

  # if [[ -n $1 ]]; then
  #   ext=""
  # else
  #   ext=$1
  # fi

  #echo $ext

  if [[ -f $id_file ]]; then
    repo_id=$(< "$id_file")
  else
    while :; do
      repo_id=$(gen_repo_id)
      if [[ $(repo_id_in_use "$repo_id") == no ]]; then
        printf '%s\n' "$repo_id" > "$id_file"
        break
      fi
    done
  fi

  seq=$(next_seq "$repo_id" "$ext")
  filename="$repo_id-$seq$ext"

  printf '%s\n' "$filename"
}
