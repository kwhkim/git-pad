#!/bin/bash
# gh db to markdown text

# shellcheck disable=SC1091
source gh_list_vars.sh

shard() { decimal=$((10#$1)); printf "%02d/%02d/gh%06d.md" "$((decimal /10000))" "$((decimal / 100 % 100))" "$decimal"; }

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

# Use ASCII null character as separator (most robust)
sqlite3 -separator $'\x1F' "$DB_FILE" \
    "SELECT * FROM issues ORDER BY updated_at DESC LIMIT 10;" | \
#while IFS=$'\x1F' read -r field1 field2 field3; do
while IFS=$'\x1F' read -r id number title state created_at updated_at closed_at labels assignees comments; do
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
    } > "github/$shard_path"

    echo "gh_issue_number: $number"
done