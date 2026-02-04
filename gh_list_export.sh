#!/bin/bash
#set -euo pipefail
#set -euo
# gh db to markdown text

# shellcheck disable=SC1091
source gh_list_vars.sh

shard() {
  decimal=$((10#$1))
  printf "%02d/%02d/gh%06d.md" "$((decimal / 10000))" "$((decimal / 100 % 100))" "$decimal"
}

# worktrees for shards
mkdir -p github
last_number=$(sqlite3 $DB_FILE "SELECT max(number) FROM issues;")
max_shard=$(shard "$last_number")
maxi=$(dirname "$max_shard" | cut -d'/' -f1)

for i in $(seq 1 $((10#$maxi))); do
  first_digits=$(printf "%02d" "$i")
  if [[ ! -d "github/$first_digits" ]]; then
    git worktree add --orphan -b gh"$first_digits" "github/$first_digits"
  fi
done
#for i in {0..9}; do git worktree add --orphan -b gh0"$i" github/0"$i"; done
#for i in {0..9}; do git worktree remove github/0"$i"; done

#!/bin/bash

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
        
        # Parse fields using unit separator (0x1F)
        IFS=$'\x1F' read -r id number title state created_at updated_at closed_at labels assignees comments <<< "$record"
        
        shard_path=$(shard "$number")
        mkdir -p "github/$(dirname "$shard_path")"
        
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
        } > "github/$shard_path" || {
            echo "ERROR: Failed to write $shard_path" >&2
            continue
        }
        
        ((count++))
        ((processed++))
        
        if ((processed % 1000 == 0)); then
            percentage=$((processed * 100 / total))
            echo "Progress: $processed/$total ($percentage%) - Issue #$number" >&2
        fi
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