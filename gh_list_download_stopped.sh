#!/usr/bin/env bash

# shellcheck source=/dev/null
source gh_list_vars.sh

state_gh_list=$(jq '.' "$DB_STATE_FILE")
state_gh_list=$(jq '.processing="false"' <<< "$state_gh_list")
echo "$state_gh_list" > "$DB_STATE_FILE"