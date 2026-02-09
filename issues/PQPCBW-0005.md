---
title: preferred repo UID and repo UID publication
type: enhancement
priority: P2
status: open
---

## Description

When running first `git pad new`, git-issue gets preferred local repo UID list so that use it as local repo UID if possible.
If connected to the remote repository, check if any one of preferred repo UID can be registerred(or go public).
If successfully registerred, use it as a repo ID. If not, use auto-generated repo ID or retry with more preferred IDs.

## Steps to Reproduce



## Expected Behavior

repo ID(RID) registerred, preferred RIDs all failed, (optionally) auto-generated RID registerred, or failure of all other sorts(like disconnection) 

## Notes

