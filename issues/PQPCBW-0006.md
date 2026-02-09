---
title: git pad new or git issue add to create new issue
type: enhancement
priority: P3
status: closed
---

## Description

When the editor launches with git pad new, the template file is copied to $issue_ID.md.
So even when nothing is changed or the user exits the editor immediately, $issue_ID.md is stored.
If nothing changes, we do not need to have the file $issue_ID.md with contents exactly the same as the template file.
The best behavior would be to launch an editor with the contents pre-populated from the template file.

## Expected Behavior

An editor should be launched with the template file's content but the file should not be created yet.
The file should be saved in the editor only with the user's explicit intention of saving the file.

with `tmpfile="$(mktemp)"".md"`, copy template file to `$tmpfile` and save it to new issue file if there is any change.

## Notes

Currently, editor launches with `sh -c "$editor \"$file\""`
with `editor=$(git var GIT_EDITOR) || return 1`.
