#!/usr/bin/env bash
set -euo pipefail

# CONFIG
refname="refs/issues-rids"
filename="rids.txt"
remote="origin"
preferred_list="${1:-}"

# ---------- helpers ----------

die() {
  echo "error: $*" >&2
  exit 1
}

gen_random_rid() {
  LC_ALL=C tr -dc 'ABCDEFGHJKMNPQRSTVWXYZ' < /dev/urandom | head -c 6
}

fetch_ref() {
  git fetch "$remote" "$refname" >/dev/null 2>&1
}

read_registry() {
  git show "$remote/$refname:$filename" 2>/dev/null || true
}

rid_exists() {
  local rid="$1"
  grep -Fxq "$rid"
}

try_register_rid() {
  local rid="$1"

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  if git show "$remote/$refname:$filename" >"$tmpdir/$filename" 2>/dev/null; then
    :
  else
    : >"$tmpdir/$filename"
  fi

  if grep -Fxq "$rid" "$tmpdir/$filename"; then
    return 1
  fi

  printf '%s\n' "$rid" >>"$tmpdir/$filename"

  tree=$(git hash-object -w -t tree --stdin <<EOF
100644 blob $(git hash-object -w "$tmpdir/$filename")	$filename
EOF
)

  parent="$(git rev-parse "$remote/$refname" 2>/dev/null || true)"

  if [ -n "$parent" ]; then
    commit=$(echo "register RID $rid" | git commit-tree "$tree" -p "$parent")
  else
    commit=$(echo "initialize RID registry" | git commit-tree "$tree")
  fi

  git push "$remote" "$commit:$refname" >/dev/null 2>&1
}

# ---------- main ----------

fetch_ref || die "cannot fetch $refname (offline or auth failure)"

registry="$(read_registry)"

# Try preferred RIDs
if [ -n "$preferred_list" ] && [ -f "$preferred_list" ]; then
  while IFS= read -r rid; do
    [ -z "$rid" ] && continue
    printf '%s\n' "$registry" | rid_exists "$rid" && continue
    if try_register_rid "$rid"; then
      echo "$rid"
      exit 0
    fi
  done <"$preferred_list"
fi

# Fallback: random RID
for _ in 1 2 3 4 5; do
  rid="$(gen_random_rid)"
  printf '%s\n' "$registry" | rid_exists "$rid" && continue
  if try_register_rid "$rid"; then
    echo "$rid"
    exit 0
  fi
done

die "failed to register RID after multiple attempts"
