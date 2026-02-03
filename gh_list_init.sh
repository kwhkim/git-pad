#!/bin/bash

# shellcheck source=/dev/null
source gh_list_vars.sh

cat > "$DB_STATE_FILE" <<'EOF'
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
