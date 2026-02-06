#!/usr/bin/bash
#set -euo pipefail

id_file=".local-repo-id"
alphabet="ABCDEFGHJKMNPQRSTVWXYZ"
id_len=6
pad=4

gen_repo_id() {
  local result
  
  # Method 1: Try /dev/urandom with LC_ALL=C to handle binary data
  if [ -c /dev/urandom ]; then
    result=$(LC_ALL=C tr -dc "$alphabet" < /dev/urandom 2>/dev/null | head -c "$id_len" 2>/dev/null) || result=""
    if [ -n "$result" ] && [ ${#result} -eq "$id_len" ]; then
      printf '%s' "$result"
      return 0
    fi
  fi
  
  # Method 2: Try openssl
  if command -v openssl >/dev/null 2>&1; then
    result=$(openssl rand -base64 48 2>/dev/null | tr -dc "$alphabet" 2>/dev/null | head -c "$id_len" 2>/dev/null) || result=""
    if [ -n "$result" ] && [ ${#result} -eq "$id_len" ]; then
      printf '%s' "$result"
      return 0
    fi
  fi
  
  # Method 3: Try /dev/random (slower but more portable on some systems)
  if [ -c /dev/random ]; then
    result=$(LC_ALL=C tr -dc "$alphabet" < /dev/random 2>/dev/null | head -c "$id_len" 2>/dev/null) || result=""
    if [ -n "$result" ] && [ ${#result} -eq "$id_len" ]; then
      printf '%s' "$result"
      return 0
    fi
  fi
  
  # Method 4: Use jot (available on macOS and BSD)
  if command -v jot >/dev/null 2>&1; then
    # Generate random characters using jot
    result=$(jot -r -c "$id_len" 0 127 2>/dev/null | tr -dc "$alphabet" 2>/dev/null | head -c "$id_len" 2>/dev/null) || result=""
    if [ -n "$result" ] && [ ${#result} -eq "$id_len" ]; then
      printf '%s' "$result"
      return 0
    fi
  fi
  
  # Method 5: Last resort - use date, PID, and hash
  if command -v md5 >/dev/null 2>&1; then
    # macOS
    result=$(printf '%s%s%s' "$(date +%s%N 2>/dev/null || date +%s)" "$$" "${RANDOM:-$(awk 'BEGIN{srand();print int(rand()*32768)}')}" | \
      md5 2>/dev/null | tr -dc "$alphabet" 2>/dev/null | head -c "$id_len" 2>/dev/null) || result=""
  elif command -v md5sum >/dev/null 2>&1; then
    # Linux
    result=$(printf '%s%s%s' "$(date +%s%N 2>/dev/null || date +%s)" "$$" "${RANDOM:-$(awk 'BEGIN{srand();print int(rand()*32768)}')}" | \
      md5sum 2>/dev/null | cut -d' ' -f1 | tr -dc "$alphabet" 2>/dev/null | head -c "$id_len" 2>/dev/null) || result=""
  fi
  
  if [ -n "$result" ] && [ ${#result} -ge "$id_len" ]; then
    printf '%s' "$result" | head -c "$id_len"
    return 0
  fi
  
  # Absolute fallback: generate from timestamp and PID
  printf '%s%s' "$(date +%s)" "$$" | head -c "$id_len"
  return 0
}

repo_id_in_use() {
  local rid="$1"
  # Use find with -print and check if output is non-empty
  if [ -n "$(find . -maxdepth 1 -name "${rid}-*.md" -print -quit 2>/dev/null)" ]; then
    wc_rid=$(cat "$id_file" | wc -c)
    if [ $wc_rid -lt $id_len ]; then
      echo '!'"E: id_file $id_file seems broken"
      return 1
    fi
    echo "yes"
  else
    echo "no"
  fi
}

secure_repo_id() {
  if [ -f "$id_file" ]; then
    repo_id=$(cat "$id_file")
    echo "$repo_id"
  else
    while :; do
      repo_id=$(gen_repo_id)
      if [ "$(repo_id_in_use "$repo_id")" = "no" ]; then
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
  local n n_dec f filename temp tmp_max

  # Create a temporary file to store the max value
  tmp_max=$(mktemp)

  echo "0" > "$tmp_max"

  if [ -d "issues" ]; then
    find "issues" -maxdepth 1 -name "${rid}-*${ext}" -type f -print0 2>/dev/null | \
    while IFS= read -r -d '' f; do
      filename=$(basename "$f")
      temp="${filename#${rid}-}"
      n="${temp%${ext}}"
      
      case "$n" in
        ''|*[!0-9]*) continue ;;
      esac
      
      n_dec=$((10#$n))
      max=$(cat "$tmp_max")
      
      if [ "$n_dec" -gt "$max" ]; then
        echo "$n_dec" > "$tmp_max"
      fi
    done
    
    max=$(cat "$tmp_max")
  fi

  # Clean up and return result
  local result
  result=$(printf "%0*d" "$pad" $((max + 1)))
  rm -f "$tmp_max"
  printf '%s' "$result"
}

next_seq_comment() {
  local rid="$1"
  local ext="$2"
  local issue_id="$3"
  local max=0

  if [ -d "issues/$issue_id/comments" ]; then
    # Get all matching files and extract the max sequence
    for f in "issues/$issue_id/comments/${rid}-"*"${ext}"; do
      # Check if glob matched anything (file exists)
      [ -f "$f" ] || continue
      
      # Extract filename
      filename=$(basename "$f")
      # Remove prefix and suffix
      temp="${filename#${rid}-}"
      n="${temp%${ext}}"
      
      # Validate it's a number
      case "$n" in
        ''|*[!0-9]*) continue ;;
      esac
      
      # Convert to decimal
      n_dec=$((10#$n))
      
      # Update max
      [ "$n_dec" -gt "$max" ] && max="$n_dec"
    done
  fi

  printf "%0*d" "$pad" $((max + 1))
}

new_filename_comment() {
  if [ $# -lt 2 ]; then
    echo "new_comment_file <ext> <issue_id>"
    return 1
  fi

  ext="$1"
  issue_id="$2"
  
  if [ -f "$id_file" ]; then
    repo_id=$(cat "$id_file")
  else
    while :; do
      repo_id=$(gen_repo_id)
      if [ "$(repo_id_in_use "$repo_id")" = "no" ]; then
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

  #if [ -n "$1" ]; then
  #  ext="$1"
  #else
  #  ext=".md"
  #fi
  if [ $# -eq 0 ]; then
    ext=".md"
  else
    ext="$1"
  fi

  # if [ -n "$1" ]; then
  #   ext=""
  # else
  #   ext="$1"
  # fi

  #echo "$ext"

  if [ -f "$id_file" ]; then
    # echo nf1
    wc_rid=$(cat "$id_file" | wc -c)
    if [ $wc_rid -lt $id_len ]; then
      echo '!'"E: id_file $id_file seems broken"
      return 1
    fi
    repo_id=$(cat "$id_file")
  else
    while :; do
      repo_id=$(gen_repo_id)
      if [ "$(repo_id_in_use "$repo_id")" = "no" ]; then
        printf '%s\n' "$repo_id" > "$id_file"
        break
      fi
    done
  fi

  seq=$(next_seq "$repo_id" "$ext")
  filename="$repo_id-$seq$ext"

  printf '%s\n' "$filename"
}