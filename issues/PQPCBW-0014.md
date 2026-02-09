---
title: test if git pad push/fetch/merge works all right
type: test
priority: P2
status: open
---

## Description

fetch and git pad status

merge has four different situations.
1. local ahead : git push okay, git fetch okay, git fetch&merge -> rebase or merge
2. remote ahead : git push fail, git fetch okay, git fetch&merge -> ff
3. local and remote both ahead : 
4. local=remote

## Steps to Reproduce

## Expected Behavior

## Notes
