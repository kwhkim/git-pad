#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# RID (Random ID) Registration Script
# ============================================================================
# Generates and registers unique 6-character IDs in a Git ref-based registry.
# Usage: ./script.sh [preferred_rids_file]
# ============================================================================

# ---------- Configuration ----------
readonly REFNAME="refs/issues-rids"
readonly FILENAME="rids.txt"
readonly REMOTE="origin"
readonly RID_LENGTH=6
readonly MAX_RETRY_ATTEMPTS=10
readonly PREFERRED_LIST="${1:-}"

# ---------- Helper Functions ----------

# Print error message and exit
die() {
  echo "error: $*" >&2
  exit 1
}

# Generate a random RID (excludes ambiguous characters: I, L, O, U, 0-9)
gen_random_rid() {
  local rid
  rid=$(LC_ALL=C tr -dc 'ABCDEFGHJKMNPQRSTVWXYZ' < /dev/urandom | head -c "$RID_LENGTH")
  
  # Validate length (defense against truncation issues)
  if [ ${#rid} -ne "$RID_LENGTH" ]; then
    die "generated RID has incorrect length: $rid"
  fi
  
  echo "$rid"
}

# Fetch the registry ref from remote
fetch_ref() {
  if ! git fetch "$REMOTE" "$REFNAME" 2>&1; then
    return 1
  fi
  return 0
}

# Read the current registry contents
read_registry() {
  git show "$REMOTE/$REFNAME:$FILENAME" 2>/dev/null || echo ""
}

# Check if RID exists in registry (via stdin)
rid_exists() {
  local rid="$1"
  grep -Fxq "$rid"
}

# Validate RID format
validate_rid() {
  local rid="$1"
  
  # Check length
  if [ ${#rid} -ne "$RID_LENGTH" ]; then
    echo "warning: invalid RID length: $rid (expected $RID_LENGTH chars)" >&2
    return 1
  fi
  
  # Check characters (only allowed chars)
  if ! [[ "$rid" =~ ^[ABCDEFGHJKMNPQRSTVWXYZ]+$ ]]; then
    echo "warning: invalid RID characters: $rid" >&2
    return 1
  fi
  
  return 0
}

# Attempt to register a RID atomically
try_register_rid() {
  local rid="$1"
  local tmpdir
  local tree parent commit
  
  # Validate before attempting registration
  validate_rid "$rid" || return 1
  
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  
  # Fetch current registry content
  if git show "$REMOTE/$REFNAME:$FILENAME" >"$tmpdir/$filename" 2>/dev/null; then
    :  # File exists
  else
    # Initialize empty registry
    touch "$tmpdir/$filename"
  fi
  
  # Check for collision (double-check even if we checked before)
  if grep -Fxq "$rid" "$tmpdir/$filename"; then
    echo "info: RID $rid already exists (race condition)" >&2
    return 1
  fi
  
  # Append new RID
  printf '%s\n' "$rid" >>"$tmpdir/$filename"
  
  # Create Git tree object
  local blob_hash
  blob_hash=$(git hash-object -w "$tmpdir/$filename")
  tree=$(git hash-object -w -t tree --stdin <<EOF
100644 blob $blob_hash	$FILENAME
EOF
)
  
  # Create commit with parent if ref exists
  parent="$(git rev-parse "$REMOTE/$REFNAME" 2>/dev/null || echo "")"
  if [ -n "$parent" ]; then
    commit=$(echo "register RID $rid" | git commit-tree "$tree" -p "$parent")
  else
    commit=$(echo "initialize RID registry" | git commit-tree "$tree")
  fi
  
  # Atomically push to remote (may fail due to race condition)
  if git push "$REMOTE" "$commit:$REFNAME" 2>&1; then
    return 0
  else
    echo "info: push failed for RID $rid (likely race condition), retrying..." >&2
    # Fetch updated ref for next attempt
    fetch_ref >/dev/null 2>&1 || true
    return 1
  fi
}

# Try to register a RID with exponential backoff
try_register_with_retry() {
  local rid="$1"
  local attempt=1
  local max_attempts=3
  local delay=1
  
  while [ $attempt -le $max_attempts ]; do
    if try_register_rid "$rid"; then
      return 0
    fi
    
    if [ $attempt -lt $max_attempts ]; then
      echo "info: registration failed, retrying in ${delay}s (attempt $attempt/$max_attempts)..." >&2
      sleep "$delay"
      delay=$((delay * 2))  # Exponential backoff
    fi
    
    attempt=$((attempt + 1))
  done
  
  return 1
}

# ---------- Main Logic ----------

main() {
  local registry rid
  
  # Validate Git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    die "not in a git repository"
  fi
  
  # Validate remote exists
  if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
    die "remote '$REMOTE' does not exist"
  fi
  
  # Fetch registry
  if ! fetch_ref; then
    die "cannot fetch $REFNAME from $REMOTE (check network/auth)"
  fi
  
  registry="$(read_registry)"
  
  # Try preferred RIDs first
  if [ -n "$PREFERRED_LIST" ]; then
    if [ ! -f "$PREFERRED_LIST" ]; then
      echo "warning: preferred list file not found: $PREFERRED_LIST" >&2
    else
      echo "info: trying preferred RIDs from $PREFERRED_LIST" >&2
      
      while IFS= read -r rid || [ -n "$rid" ]; do
        # Skip empty lines and comments
        [[ -z "$rid" || "$rid" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        rid="$(echo "$rid" | tr -d '[:space:]')"
        
        # Validate format
        if ! validate_rid "$rid"; then
          continue
        fi
        
        # Check if already exists
        if printf '%s\n' "$registry" | rid_exists "$rid"; then
          echo "info: preferred RID $rid already exists, skipping" >&2
          continue
        fi
        
        echo "info: attempting to register preferred RID: $rid" >&2
        if try_register_with_retry "$rid"; then
          echo "$rid"
          return 0
        fi
      done < "$PREFERRED_LIST"
      
      echo "info: no preferred RIDs available, falling back to random generation" >&2
    fi
  fi
  
  # Fallback: generate random RIDs
  echo "info: generating random RID..." >&2
  
  for attempt in $(seq 1 "$MAX_RETRY_ATTEMPTS"); do
    rid="$(gen_random_rid)"
    
    # Check if already exists
    if printf '%s\n' "$registry" | rid_exists "$rid"; then
      echo "info: collision detected for $rid (attempt $attempt), regenerating..." >&2
      continue
    fi
    
    echo "info: attempting to register random RID: $rid (attempt $attempt)" >&2
    if try_register_with_retry "$rid"; then
      echo "$rid"
      return 0
    fi
    
    # Refresh registry after failed attempt
    registry="$(read_registry)"
  done
  
  die "failed to register RID after $MAX_RETRY_ATTEMPTS attempts"
}

# ---------- Entry Point ----------
main "$@"