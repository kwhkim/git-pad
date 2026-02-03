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

BATCH_SIZE=10000
offset=0

# Get total count
echo "Counting total issues..." >&2
total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM issues;")
echo "Total issues: $total" >&2
echo "" >&2


BATCH_SIZE=10000
offset=0

# Get total count
echo "Counting total issues..." >&2
total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM issues;")
echo "Total issues: $total" >&2
echo "" >&2

processed=0

while true; do
    batch_start=$((offset + 1))
    
    echo "Fetching batch: rows $batch_start to $((offset + BATCH_SIZE))..." >&2
    
    # Use process substitution to avoid subshell
    count=0
    while IFS=$'\x1F' read -r id number title state created_at updated_at closed_at labels assignees comments; do
        #echo -n "$number, "
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
        }


        shard_path=$(shard "$number") || echo "ERROR: Failed to compute shard for issue #$number" >&2 
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
        
        # Show progress every 1000 items
        if ((processed % 1000 == 0)); then
            percentage=$((processed * 100 / total))
            echo "Progress: $processed/$total ($percentage%) - Issue #$number" >&2
        fi
    #done < <(sqlite3 -separator $'\x1F' "$DB_FILE" \
    #    "SELECT * FROM issues ORDER BY updated_at DESC LIMIT $BATCH_SIZE OFFSET $offset;")

    # testing with title containing a newline character
    done < <(sqlite3 -separator $'\x1F' "gh_list_ex01.db" \
            'SELECT * FROM issues;')

    echo "Batch complete: processed $count rows in this batch" >&2
    echo "" >&2
    
    # If we processed fewer rows than BATCH_SIZE, we're done
    [[ $count -lt $BATCH_SIZE ]] && break
    
    ((offset += BATCH_SIZE))
done

echo "====================================" >&2
echo "Completed: $processed/$total issues processed" >&2
echo "====================================" >&2