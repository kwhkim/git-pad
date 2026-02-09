---
title: aliases for `git pad new`
type: enhancement
priority: P3
status: open
---

## Description

all of `git pad new`, `git issue add` and `git issue create` seem to mean the same thing.

`git pad add` might sound ambiguous in the context of git,
because `git add` is for staging files in the working tree.

We might choose different models for managing issues: 

* A Git-like model where issues should be explicitly committed (even though adding is automatic, current model)
* A model where commits are implicit and any edit is automatically committed, so add cannot mean adding in the context of Git, but rather means adding a new issue
  - Or we might be better off avoiding the term `add`

## Steps to Reproduce

## Expected Behavior

1. `git pad new|add|create` work the same.
2. select modes like git-native mode or issue-centered mode.

## Notes


