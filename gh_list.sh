#!/bin/bash

# shellcheck source=/dev/null
source gh_list_vars.sh

sqlite3 -box "$DB_FILE" "SELECT id,number,state,title,updated_at,labels,assignees FROM issues ORDER BY number DESC LIMIT 5;"
sqlite3 -box "$DB_FILE" "SELECT id,number,state,title,updated_at,labels,assignees FROM issues ORDER BY updated_at DESC LIMIT 5;"
sqlite3 -box "$DB_FILE" "SELECT * FROM issues ORDER BY updated_at DESC LIMIT 1;"