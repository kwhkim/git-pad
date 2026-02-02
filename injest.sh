#!/usr/bin/env bash
set -euo pipefail

OWNER=pandas-dev
REPO=pandas
REPO_KEY="$OWNER/$REPO"
SLICE_MINUTES_FORWARD1=300
SLICE_MINUTES_FORWARD2=30
SLICE_MINUTES_BACKWARD=$((60*24)) # 1 day
SPAN_MINUTES_RECENT=$((60*24*7)) # 7 days
SHARD_SIZE=1000

die() { echo "[!] $*" >&2; exit 1; }

now_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }




echo "- create table if not exists..."
sqlite3 issues.db <<'SQL'
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;

CREATE TABLE IF NOT EXISTS issues (
  id            TEXT PRIMARY KEY,
  number        INTEGER NOT NULL,
  title         TEXT NOT NULL,
  state         TEXT NOT NULL,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  closed_at     TEXT,
  labels        TEXT,
  assignees     TEXT,
  comments      INTEGER NOT NULL
);
SQL




echo "- Defining GQL query..."
GQL_FORWARD=$(cat <<'EOF'
query (
  $owner: String!,
  $repo: String!,
  $since: DateTime!,
  $cursor: String
) {
  repository(owner: $owner, name: $repo) {
    createdAt
    issues(
      first: 100
      after: $cursor
      orderBy: { field: UPDATED_AT, direction: ASC }
      filterBy: { since: $since }
    ) {
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        id
        number
        title
        state
        createdAt
        updatedAt
        closedAt
        labels(first: 50) { nodes { name } }
        assignees(first: 50) { nodes { login } }
        comments(first: 0) { totalCount }
      }
    }
  }
}
EOF
)

GQL_BACKWARD=$(cat <<'EOF'
query (
  $owner: String!,
  $repo: String!,
  $since: DateTime!,
  $cursor: String
) {
  repository(owner: $owner, name: $repo) {
    createdAt
    issues(
      first: 100
      after: $cursor
      orderBy: { field: UPDATED_AT, direction: ASC }
      filterBy: { since: $since }
    ) {
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        id
        number
        title
        state
        createdAt
        updatedAt
        closedAt
        labels(first: 50) { nodes { name } }
        assignees(first: 50) { nodes { login } }
        comments(first: 0) { totalCount }
      }
    }
  }
}
EOF
)

#echo "- GQL: " "$GQL"

while :; do
    echo "===="
    # ---- load state ----
    state=$(jq '.' state.json)

    min_cov=$(jq -r '.updated_at_min' <<<"$state")
    max_cov=$(jq -r '.updated_at_max' <<<"$state")
    repo_created=$(jq -r '.repo_created_at' <<<"$state")

    # ---- fetch repo createdAt once ----
    if [[ "$repo_created" == "" ]]; then
    # shellcheck disable=SC2016
    repo_created=$(gh api graphql -f query='
        query($o:String!,$r:String!){
        repository(owner:$o,name:$r){ createdAt }
        }' -F o="$OWNER" -F r="$REPO" \
        | jq -r '.data.repository.createdAt')

    state=$(jq --arg rc "$repo_created" '.repo_created_at=$rc' <<<"$state")
    fi

    if [[ "$min_cov" == "" && "$max_cov" != "" ]] || \
    [[ "$min_cov" != "" && "$max_cov" == "" ]]; then
      die "Initial coverage problem detected. They should be both null or both non-null.";
    fi

    if [[ "$min_cov" == "" && "$max_cov" == "" ]]; then
    echo "Initial run detected. Setting coverage to a point $((SPAN_MINUTES_RECENT/60/24)) days ago"
    min_cov=$(date -u -d "$(now_utc) - $SPAN_MINUTES_RECENT minutes" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || die "date calc error 0")
    max_cov=$min_cov
    fi
    echo "- Current coverage: $min_cov → $max_cov"
  
    # ---- decide scan direction ----
    # forward scan if forward_t1 < now
    time_ingest=$(now_utc)
    if [[ "$(date -u -d "$max_cov" +%s)" -lt "$(date -u -d "$time_ingest - $SLICE_MINUTES_FORWARD1 minutes" +%s)" ]]; then
        
        direction="forward"
        since="$max_cov"
        SLICE_MINUTES_FORWARD=$SLICE_MINUTES_FORWARD1
        until=$(date -u -d "$since + $SLICE_MINUTES_FORWARD1 minutes" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || die "date calc error 1a")
    elif [[ "$(date -u -d "$max_cov" +%s)" -lt "$(date -u -d "$time_ingest - $((SLICE_MINUTES_FORWARD2*2)) minutes" +%s)" ]]; then
        direction="forward"
        since="$max_cov"
        SLICE_MINUTES_FORWARD=$SLICE_MINUTES_FORWARD2
        until=$(date -u -d "$since + $SLICE_MINUTES_FORWARD2 minutes" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || die "date calc error 1b")
    else
        SLICE_MINUTES_FORWARD=0
        direction="backward"
        until="$min_cov"
        since=$(date -u -d "$until - $SLICE_MINUTES_BACKWARD minutes" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || die "date calc error 2")
    fi

    echo "- Scan $direction : $since → $until"

    # ---- fetch ----
    if [[ "$direction" == "forward" ]]; then
       resp=$(gh api graphql \
    -F owner="$OWNER" \
    -F repo="$REPO" \
    -F since="$since" \
    -F until="$until" \
    -f query="$GQL_FORWARD")
    else
       resp=$(gh api graphql \
    -F owner="$OWNER" \
    -F repo="$REPO" \
    -F since="$since" \
    -F until="$until" \
    -f query="$GQL_BACKWARD")
    fi
   
    echo "- Writing response to resp.txt ..."
    echo "$resp" > resp.txt

# ---- upsert into sqlite ----
# since=2026-01-26T10:58:14Z
# until=2026-01-26T11:28:14Z


# CREATE TABLE IF NOT EXISTS issues (
#   id            TEXT PRIMARY KEY,
#   number        INTEGER NOT NULL,
#   title         TEXT NOT NULL,
#   state         TEXT NOT NULL,
#   created_at    TEXT NOT NULL,
#   updated_at    TEXT NOT NULL,
#   closed_at     TEXT,
#   labels        TEXT,
#   assignees     TEXT,
#   comments      INTEGER NOT NULL,
#   ingested_at   TEXT NOT NULL
# );

# !
# JSON allows ' freely.
# SQL does not allow unescaped ' inside '...'. 


#  | select(.updatedAt > "'"$since"'" and .updatedAt <= "'"$until"'")
# ! special characters like ' is problematic inside single quotes in SQL.'
# echo "- Record response to SQLite."
#     echo "$resp" | jq -c '
#   .data.repository.issues.nodes[]
#   | {
#       number,
#       node_id:.nodeId,
#       updated_at:.updatedAt,
#       title:.title,
#       state:.state,
#       created_at:.createdAt,
#       updated_at:.updatedAt,
#       comments:.comments.totalCount
#     }' | while read -r row; do

#         sqlite3 issues.db <<SQL
#         .parameter init
# .parameter set :row '$row'

# INSERT OR REPLACE INTO issues
# (number,id,title,state,created_at, updated_at, comments)
# VALUES (
#   json_extract('$row','$.number'),
#   json_extract('$row','$.node_id'),
#   json_extract('$row','$.title'),
#   json_extract('$row','$.state'),
#   json_extract('$row','$.created_at'),
#   json_extract('$row','$.updated_at'),
#   json_extract('$row','$.comments')
# );
# SQL
# done


if [ -f insert.sql ]; then rm insert.sql; fi
#i=1
echo "$resp" | jq -c '.data.repository.issues.nodes[]' | while IFS= read -r row; do 
  #echo "$row"
  number="$(jq -r '.number' <<< "$row")" 
  id="$(jq -r '.id' <<< "$row")" 
  title="$(jq -r '.title' <<< "$row")"
  state="$(jq -r '.state' <<< "$row")"
  created_at="$(jq -r '.createdAt' <<< "$row")"
  updated_at="$(jq -r '.updatedAt' <<< "$row")"
  ncomments="$(jq -r '.comments.totalCount' <<< "$row")"
  title=$(sed "s/'/''/g" <(echo "$title"))
  
  #echo "INSERT OR REPLACE INTO issues (number,id,title,state,created_at,updated_at,comments) VALUES($number,'$id', '$title', '$state', '$created_at', '$updated_at', $ncomments);" 
  echo "$number|$id|$updated_at|$title" 

  if [[ "$direction" == "forward" ]]; then
    
    echo "INSERT OR REPLACE INTO issues (number,id,title,state,created_at,updated_at,comments) VALUES($number,'$id', '$title', '$state', '$created_at', '$updated_at', $ncomments);" >> insert.sql
  else
    echo "INSERT OR IGNORE INTO issues (number,id,title,state,created_at,updated_at,comments) VALUES($number,'$id', '$title', '$state', '$created_at', '$updated_at', $ncomments);" >> insert.sql
  fi
  #if [ $i -eq 2 ]; then export title; break; fi
  #i=$((i+1))
done

if [ -f insert.sql ]; then sqlite3 issues.db < insert.sql; echo "- Record response to SQLite. done.";
else echo '- Nothing to SQLite'; fi


    # ---- update coverage ----
    new_min=$(sqlite3 issues.db "SELECT min(updated_at) FROM issues;")
    new_max=$(sqlite3 issues.db "SELECT max(updated_at) FROM issues;")

    echo "  - New coverage in DB: $new_min → $new_max"

    if [[ "$direction" == "forward" ]]; then
      t_new_max=$(date -u -d "$new_max" +"%s")
      t_since=$(date -u -d "$since" +"%s") 
      if [[ "$new_max" == "$max_cov" || "$new_max" == "" || $t_new_max -le $t_since ]]; then
        max_cov=$(date -u -d "$max_cov + $((SLICE_MINUTES_FORWARD*4/5)) minutes" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || die "date calc error 3")
      else  
        max_cov="$new_max"
      fi
    else
      t_new_min=$(date -u -d "$new_min" +"%s")
      t_until=$(date -u -d "$until" +"%s")   
      
      if [[ "$new_min" == "$min_cov" || "$new_min" == "" || $t_new_min -ge $t_until ]]; then
        min_cov=$(date -u -d "$min_cov - $((SLICE_MINUTES_BACKWARD*4/5)) minutes" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || die "date calc error 4")
      else  
        min_cov="$new_min"
      fi
    fi

    echo "  - Updated coverage: $min_cov → $max_cov"

    state=$(jq --arg a "$min_cov" --arg b "$max_cov" \
    '.updated_at_min=$a | .updated_at_max=$b' <<<"$state")

    echo "$state" > state.json

done