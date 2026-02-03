#!/bin/bash

# shellcheck source=/dev/null
source gh_list_vars.sh

gh_repo_createdAt() {
  # shellcheck disable=SC2016
  gh api graphql -f query='
    query($o:String!,$r:String!){
    repository(owner:$o,name:$r){ createdAt }
    }' -F o="$1" -F r="$2" | jq -r '.data.repository.createdAt'
}

echo "- repo created at: $(gh_repo_createdAt "$OWNER" "$REPO")"

sqlite3 -box "$DB_FILE" << EOF
SELECT
  MIN(updated_at) AS min_updated_at,
  MAX(updated_at) AS max_updated_at,
  COUNT(*)        AS row_count
FROM issues;
EOF

read -p "- Press Y to initialize database $DB_FILE and state file $DB_STATE_FILE ..." ans

if [[ "$ans" != "Y" && "$ans" != "y" ]]; then
  echo "- Aborted."
  exit 1
fi

cat > "$DB_STATE_FILE" << 'EOF'
{
  "updated_at_min": "",
  "updated_at_max": "",
  "repo_created_at": "",
  "processing": "false"
}
EOF
echo "- Initialized state file $DB_STATE_FILE."

if [[ -f "$DB_FILE" ]]; then
  echo "- remove existing database file $DB_FILE ..."
  rm "$DB_FILE"
fi
