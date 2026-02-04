#!/bin/bash
set -euo pipefail
#set -euo
# gh db to markdown text

# shellcheck disable=SC1091
source gh_list_vars.sh

shard() {
  decimal=$((10#$1))
  printf "%02d/%02d/gh%06d.md" "$((decimal / 10000))" "$((decimal / 100 % 100))" "$decimal"
}

# worktree setup
git_project_root() {
  git worktree list --porcelain |
    awk '$1=="worktree" { print $2; exit }'
  # git rev-parse --git-common-dir 2>/dev/null | xargs dirname
  #   returns . in the root directory
}
root=$(git_project_root)
DIR_GITHUB="$root/.issues/github"

if [[ -d "$DIR_GITHUB" ]]; then
  if cd "$DIR_GITHUB" && git rev-parse --git-dir | grep 'worktrees/github$'; then
    echo "- Using existing git worktree at $DIR_GITHUB"
    cd - >/dev/null || exit 1
  else
    echo "- ERROR: $DIR_GITHUB exists and is not a git worktree for github."
    exit 1
  fi
else
  tmp_ref="refs/issues/tmp/$(date +%s)-$$"
  git worktree add --orphan -B "$tmp_ref" "$DIR_GITHUB"
  cd "$DIR_GITHUB" || exit 1
  git commit --allow-empty -m "start github issues" 
  git update-ref refs/issues/github/latest HEAD
  git checkout --detach 
  git branch -D "$tmp_ref"
  echo "- Created new git worktree at $DIR_GITHUB"
fi

# worktrees for shards
#mkdir -p github

echo "- Exporting issues in DB_FILE($DB_FILE) to markdown files in $DIR_GITHUB ..."
last_number=$(sqlite3 $DB_FILE "SELECT max(number) FROM issues;")
echo "- last issue number: $last_number"
# max_shard=$(shard "$last_number")
# maxi=$(dirname "$max_shard" | cut -d'/' -f1)

# to create worktrees for each first two digits
# for i in $(seq 0 $((10#$maxi))); do
#   first_digits=$(printf "%02d" "$i")
#   if [[ ! -d "github/$first_digits" ]]; then
#     git worktree add --orphan -b gh"$first_digits" "github/$first_digits"
#   fi
# done

#for i in {0..9}; do git worktree add --orphan -b gh0"$i" github/0"$i"; done
#for i in {0..9}; do git worktree remove --force github/0"$i"; done


BATCH_SIZE=10000
offset=0

echo "Counting total issues..." >&2
total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM issues;")
echo "Total issues: $total" >&2
echo "" >&2

processed=0

while true; do
    batch_start=$((offset + 1))
    
    echo "Fetching batch: rows $batch_start to $((offset + BATCH_SIZE))..." >&2
    
    count=0
    # Use record separator (0x1E) to separate rows
    while IFS= read -r -d $'\x1E' record; do
        # Skip empty records
        [[ -z "$record" ]] && continue
        #echo 1
        # Parse fields using unit separator (0x1F)
        IFS=$'\x1F' read -r id number title state created_at updated_at closed_at labels assignees comments <<< "$record"
        
        #echo 2
        shard_path=$(shard "$number")
        mkdir -p "$DIR_GITHUB/$(dirname "$shard_path")"
        
        #echo 3
        {
            echo "---"
            echo "gh_issue_number: $number"
            echo "title: $title"
            echo "id: $id"
            echo "created_at: $created_at"
            echo "updated_at: $updated_at"
            echo "closed_at: $closed_at"
            echo "state: $state"
            echo "labels: $labels"
            echo "assignees: $assignees"
            echo "comments: $comments"
            echo "---"
            echo ""
            echo "(body not yet downloaded)"
            echo ""
        } > "$DIR_GITHUB/$shard_path" || {
            echo "ERROR: Failed to write $shard_path" >&2
            continue
        }
        
        #echo 4
        #echo count: $count, processed: $processed
        count=$((count+1))
        processed=$((processed+1))
        
        #echo 5
        if ((processed % 1000 == 0)); then
            percentage=$((processed * 100 / total))
            echo "Progress: $processed/$total ($percentage%) - Issue #$number" >&2
        fi

        #echo 6
    done < <(sqlite3 "$DB_FILE" <<EOF
.separator "\x1F" "\x1E"
SELECT id, number, title, state, created_at, updated_at, closed_at, labels, assignees, comments 
FROM issues 
ORDER BY updated_at DESC 
LIMIT $BATCH_SIZE OFFSET $offset;
EOF
)
    
    echo "Batch complete: processed $count rows in this batch" >&2
    echo "" >&2
    
    [[ $count -lt $BATCH_SIZE ]] && break
    
    ((offset += BATCH_SIZE))
done

echo "====================================" >&2
echo "Completed: $processed/$total issues processed" >&2
echo "====================================" >&2