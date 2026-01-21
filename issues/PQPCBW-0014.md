---
title: test if git issue push/fetch/merge works all right
type: test
priority: P2
---

## Description

fetch and git issue status

merge has four different situations.
1. local ahead : git push okay, git fetch okay, git fetch&merge -> rebase or merge
2. remote ahead : git push fail, git fetch okay, git fetch&merge -> ff
3. local and remote both ahead : 
4. local=remote

## Steps to Reproduce

## Expected Behavior

## Notes
