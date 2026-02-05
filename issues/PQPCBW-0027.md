---
title: How to store github issue list
type: enhancement
priority: P2
---

## Description

Completed `gh_list_download.sh` to download full list of issues(without body and comments).
- Test data : pandas-dev/pandas
- as-of 2026-02-04, 28072 issues.
- The latest issue number is larger than 64000.

If exported to markdown files, it amounts to 113M.
If stored in git object, it amounts to 64+M.
sqlite3 db file amounts to only 6.1M! (if dumped, the same)
- Dumping: `sqlite3 gh_list.db .dump > gh_list_dump.sql`


* Options
  - Use sqlite3 db for list, body, and comments for small size.
    - Use git-lfs?
  - Use git commits with markdown files -> huge data?
    - Possbily sharding references and directories?
    - Independent repository?




## Steps to Reproduce

## Expected Behavior

## Notes

* github's space limit
  * Individual files: Hard limit of 100 MB (50 MB warning). Use Git LFS for larger files. 
  * Recommended repo size: <1 GB (ideal), <5 GB (strongly advised). 
  * Push size: Enforced at 2 GB per push operation.
  * Over 5 GB: GitHub may restrict operations, throttle performance, or ask you to archive/reduce. 
