---
title: make git-pad worktree folder adjustable
type: enhancement
priority: P3
status: open
---

## Description

Current worktree directory name .issues seem to be too general.
I would prefer .git-pad for explicit usage,
and it differs from issues folder for issue markdown files.

So, .issues/issues/0001.md -> .git-pad/issues/0001.md (or .git_issue/issues/0001.md)

maybe environment variable like DIR_WORKTREE.

reference name can be considered for renaming like refs/issues -> refs/git-pad/
using function `issue_ref`(local reference) and `remote_issue_ref`(remote reference),
and fuction `git_issue_worktree`

ideally,
REF_NAME='git-pad'
WT_NAME='git-pad'
DIR_NAME='issues'

## Steps to Reproduce

## Expected Behavior

## Notes
