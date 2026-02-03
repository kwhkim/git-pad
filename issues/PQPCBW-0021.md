---
title: mirror of gihub issues
type: enhancement
priority: P2
status: open
---

## Description

Another custom ref for github(possibly other git-servers like gitlab).
This custom ref tracks github issues using API(possibly gh).

It downloads github issues as they are, so no conflict is possible.
Users can copy a github issue to draft folder, edit there, and upload it if possible(when one is the original author of the github issue).
Users can also promote it to embedded issues(maybe just copying it to embedded folder?)

If the list of github issues is long, we might use .db for list
(fields like number, unique-id, title, body, author, # of comments, updatedAt, createdAt),
based on local data, or using github API.

For 100000 issues, downloading issues will take approx.    based on 5000 API calls/hour.

* Directories structure

```
.git-issues/embedded/

.git-issues/github/00/00/000001.md, 000002.md, ...
.git-issues/github/00/01/000101.md, 000102.md, ...
...
.git-issues/github/draft/

.git-issues/gitlab/00/00/000001.md, 000002.md, ...
```

* 

## Steps to Reproduce

## Expected Behavior

## Notes
