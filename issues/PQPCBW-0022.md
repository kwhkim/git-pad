---
title: download github issue list
type: enhancement
priority: P1
status: open
relevant: PQPCBW-0021
---

## Description

Download list of all issues


## Steps to Reproduce

## Expected Behavior

* commands(list)
  * `git gh list-init` 
    * new `$DB_STATE_FILE`(`gh_list_state.json`)
    * new `$DB_FILE`(`gh_list.db`)
  * `git gh list-download`
    * start or resume download the list
  * `git gh list-download-reset`
    * in case `git gh list-download` does not start
  * `git gh list-export` : .db to .md files

* commands(body/comments)
  * `git gh body-donwload $1 $2` : download body 
  * `git gh comment-download $1 $2` : download comments

* `git gh push/pull`


* `git gh list-download`
  * Recently updated issues first, then older ones
  * respect RATELIMIT
    * sleep if needed
  * write to db and then update to .issues/github/$SHARDING/gh-000001.md
  * you can edit via `git gh edit 000001` -> .issues/github/draft/gh-copy-000001.md
  * you can create new one via `git gh new` -> `.issues/github/draft/gh-$LOCAL_REPO_ID-000001.md`
  * you can upload the issue via `git gh upload`

## Notes
