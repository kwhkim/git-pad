#!/usr/bin/env bash
set -euo pipefail

OWNER=pandas-dev
REPO=pandas
REPO_KEY="$OWNER/$REPO"
SLICE_MINUTES_FORWARD1=300
SLICE_MINUTES_FORWARD2=30
SLICE_MINUTES_BACKWARD=$((60 * 24 * 30)) # 30 days
SPAN_MINUTES_RECENT=$((60 * 24 * 7))     # 7 days
SHARD_SIZE=1000

die() {
  echo "[!] $*" >&2
  exit 1
}

now_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

echo "- create table if not exists..."
sqlite3 issues.db << 'SQL'
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
GQL_FORWARD=$(
  cat << 'EOF'
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

GQL_BACKWARD=$(
  cat << 'EOF'
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
  state_gh_list=$(jq '.' state.json)

  min_cov=$(jq -r '.updated_at_min' <<< "$state_gh_list")
  max_cov=$(jq -r '.updated_at_max' <<< "$state_gh_list")
  repo_created=$(jq -r '.repo_created_at' <<< "$state_gh_list")

  # ---- fetch repo createdAt once ----
  if [[ "$repo_created" == "" ]]; then
    # shellcheck disable=SC2016
    repo_created=$(gh api graphql -f query='
        query($o:String!,$r:String!){
        repository(owner:$o,name:$r){ createdAt }
        }' -F o="$OWNER" -F r="$REPO" |
      jq -r '.data.repository.createdAt')

    state_gh_list=$(jq --arg rc "$repo_created" '.repo_created_at=$rc' <<< "$state_gh_list")
  fi

  if [[ "$min_cov" == "" && "$max_cov" != "" ]] ||
    [[ "$min_cov" != "" && "$max_cov" == "" ]]; then
    die "Initial coverage problem detected. They should be both null or both non-null."
  fi

  if [[ "$min_cov" == "" && "$max_cov" == "" ]]; then
    echo "Initial run detected. Setting coverage to a point $((SPAN_MINUTES_RECENT / 60 / 24)) days ago"
    min_cov=$(date -u -d "$(now_utc) - $SPAN_MINUTES_RECENT minutes" +"%Y-%m-%dT%H:%M:%SZ" 2> /dev/null || die "date calc error 0")
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
    until=$(date -u -d "$since + $SLICE_MINUTES_FORWARD1 minutes" +"%Y-%m-%dT%H:%M:%SZ" 2> /dev/null || die "date calc error 1a")
  elif [[ "$(date -u -d "$max_cov" +%s)" -lt "$(date -u -d "$time_ingest - $((SLICE_MINUTES_FORWARD2 * 2)) minutes" +%s)" ]]; then
    direction="forward"
    since="$max_cov"
    SLICE_MINUTES_FORWARD=$SLICE_MINUTES_FORWARD2
    until=$(date -u -d "$since + $SLICE_MINUTES_FORWARD2 minutes" +"%Y-%m-%dT%H:%M:%SZ" 2> /dev/null || die "date calc error 1b")
  else
    SLICE_MINUTES_FORWARD=0
    direction="backward"
    until="$min_cov"
    since=$(date -u -d "$until - $SLICE_MINUTES_BACKWARD minutes" +"%Y-%m-%dT%H:%M:%SZ" 2> /dev/null || die "date calc error 2")
  fi

  echo "- Scan $direction : $since → $until"

  # ---- fetch ----

  cursor=""
  has_next_page=true

  n_between=0
  n_outside=0

  while [ "$has_next_page" = "true" ]; do
    echo "- Fetching page with cursor: ${cursor:-null}"

    if [[ "$direction" == "forward" ]]; then
      GQL="$GQL_FORWARD"
    else
      GQL="$GQL_BACKWARD"
    fi

    if [ -z "$cursor" ]; then
      resp=$(gh api graphql \
        -F owner="$OWNER" \
        -F repo="$REPO" \
        -F since="$since" \
        -f query="$GQL")
    else
      resp=$(gh api graphql \
        -F owner="$OWNER" \
        -F repo="$REPO" \
        -F since="$since" \
        -F cursor="$cursor" \
        -f query="$GQL")
    fi

    # Extract page info
    has_next_page=$(echo "$resp" | jq -r '.data.repository.issues.pageInfo.hasNextPage')
    cursor=$(echo "$resp" | jq -r '.data.repository.issues.pageInfo.endCursor')

    echo "- Writing response to resp.txt ..."
    echo "$resp" > resp.txt

    if [ -f insert.sql ]; then rm insert.sql; fi
    #i=1

    while IFS= read -r row; do
      number="$(jq -r '.number' <<< "$row")"
      id="$(jq -r '.id' <<< "$row")"
      title="$(jq -r '.title' <<< "$row")"
      state="$(jq -r '.state' <<< "$row")"
      created_at="$(jq -r '.createdAt' <<< "$row")"
      updated_at="$(jq -r '.updatedAt' <<< "$row")"
      closed_at="$(jq -r '.closedAt' <<< "$row")"
      labels="$(jq -r '[.labels.nodes[].name] | join("|")' <<< "$row")"
      assignees="$(jq -r '[.assignees.nodes[].login] | join("|")' <<< "$row")"
      ncomments="$(jq -r '.comments.totalCount' <<< "$row")"
      title=$(sed "s/'/''/g" <<< "$title")

      echo "$number|$id|$updated_at|$title"

      if [[ "$direction" == "forward" ]]; then
        if [[ "$updated_at" < "$since" || "$updated_at" > "$until" ]]; then
          n_outside=$((n_outside + 1))
          has_next_page=false
        else
          n_between=$((n_between + 1))
        fi
        echo "INSERT OR REPLACE INTO issues (number,id,title,state,created_at,updated_at,closed_at,labels,assignees,comments) VALUES($number,'$id', '$title', '$state', '$created_at', '$updated_at', '$closed_at', '$labels', '$assignees',  $ncomments);" >> insert.sql
      else
        if [[ "$updated_at" < "$since" || "$updated_at" > "$until" ]]; then
          n_outside=$((n_outside + 1))
          has_next_page=false
        else
          n_between=$((n_between + 1))
          echo "INSERT OR IGNORE INTO issues (number,id,title,state,created_at,updated_at,closed_at,labels,assignees,comments) VALUES($number,'$id', '$title', '$state', '$created_at', '$updated_at', '$closed_at', '$labels', '$assignees', $ncomments);" >> insert.sql
        fi
      fi
    done < <(echo "$resp" | jq -c '.data.repository.issues.nodes[]')

    if [ -f insert.sql ]; then
      sqlite3 issues.db < insert.sql
      echo "- Record response to SQLite. done."
    else
      echo '- Nothing to SQLite'
    fi

    echo "- Page summary: $n_between issues within range, $n_outside issues outside range."
    n=$((n_between + n_outside))
    #prop_n=$((n_between*100 /100))
    prop_n=$n_between
    echo "  - Total issues processed in this page: $n ( $prop_n % within first page )"
    echo "  - Has next page: $has_next_page"
    # Break if no more pages or cursor is null
    if [ "$has_next_page" != "true" ] || [ "$cursor" = "null" ]; then
      echo "- Going to next scan slice."
      break
    else
      echo "- Continuing to next page."
    fi
  done

  if [[ $direction == "backward" ]]; then
    # in backward scan, if no issues found in range, we can stop
    if [[ $prop_n -lt 40 ]]; then
      SLICE_MINUTES_BACKWARD=$((SLICE_MINUTES_BACKWARD * 2))
      echo "  - Less than 50 issues found in range during backward scan. Increasing slice to $SLICE_MINUTES_BACKWARD minutes($((SLICE_MINUTES_BACKWARD / 60 / 24)) days) for next scan."
    fi
    if [[ $prop_n -gt 90 ]]; then
      SLICE_MINUTES_BACKWARD=$((SLICE_MINUTES_BACKWARD / 2))
      if [[ $SLICE_MINUTES_BACKWARD -lt 30 ]]; then
        SLICE_MINUTES_BACKWARD=30
      fi
      echo "  - More than 90 issues found in range during backward scan. Decreasing slice to $SLICE_MINUTES_BACKWARD minutes($((SLICE_MINUTES_BACKWARD / 60 / 24)) days) for next scan."
    fi

  elif [[ $direction == "forward" ]]; then
    # in forward scan, if no issues found in range, we can stop
    if [[ $prop_n -lt 40 ]]; then
      SLICE_MINUTES_FORWARD=$((SLICE_MINUTES_FORWARD * 2))
      echo "  - Less than 50 issues found in range during forward scan. Increasing slice to $SLICE_MINUTES_FORWARD minutes($((SLICE_MINUTES_FORWARD / 60 / 24)) days) for next scan."
    fi
    if [[ $prop_n -gt 90 ]]; then
      SLICE_MINUTES_FORWARD=$((SLICE_MINUTES_FORWARD / 2))
      if [[ $SLICE_MINUTES_FORWARD -lt 30 ]]; then
        SLICE_MINUTES_FORWARD=30
      fi
      echo "  - More than 90 issues found in range during forward scan. Decreasing slice to $SLICE_MINUTES_FORWARD minutes($((SLICE_MINUTES_FORWARD / 60 / 24)) days) for next scan."
    fi
  fi

  # ---- update coverage ----
  new_min=$(sqlite3 issues.db "SELECT min(updated_at) FROM issues;")
  new_max=$(sqlite3 issues.db "SELECT max(updated_at) FROM issues;")

  echo "  - New coverage in DB: $new_min → $new_max"

  if [[ "$direction" == "forward" ]]; then
    t_new_max=$(date -u -d "$new_max" +"%s")
    t_since=$(date -u -d "$since" +"%s")
    if [[ "$new_max" == "$max_cov" || "$new_max" == "" || $t_new_max -le $t_since ]]; then
      max_cov=$(date -u -d "$max_cov + $((SLICE_MINUTES_FORWARD * 4 / 5)) minutes" +"%Y-%m-%dT%H:%M:%SZ" 2> /dev/null || die "date calc error 3")
    else
      max_cov="$new_max"
    fi
  else
    t_new_min=$(date -u -d "$new_min" +"%s")
    t_until=$(date -u -d "$until" +"%s")

    if [[ "$new_min" == "$min_cov" || "$new_min" == "" || $t_new_min -ge $t_until ]]; then
      min_cov=$(date -u -d "$min_cov - $((SLICE_MINUTES_BACKWARD * 4 / 5)) minutes" +"%Y-%m-%dT%H:%M:%SZ" 2> /dev/null || die "date calc error 4")
    else
      min_cov="$new_min"
    fi
  fi

  echo "  - Updated coverage: $min_cov → $max_cov"

  echo "  - Current state(gh list):"
  echo "$state_gh_list"
  state_gh_list=$(jq --arg a "$min_cov" --arg b "$max_cov" \
    '.updated_at_min=$a | .updated_at_max=$b' <<< "$state_gh_list")

  echo "$state_gh_list" > state.json

done
