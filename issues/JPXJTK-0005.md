---
title: `git pad status` and etc. do not reflect remote immediately
type: bug
priority: P1
status: open
---

## Description

`git pad status` does not actively reflect the remote's status.
It only reflect the fetched remote status. So there can be some lag.
I think it would be more sensible to check remotes periodically or by default,
because it's related to issues.

Or we might need some configuration or
something like `git pad status --remote`

Then again, this gets me to thinking what should remote be...

What about setting remote to origin???(simple but not configurable?)

Current behavior is
1. there could be multiple remotes and each branch might have different tracking remote.
2. `git pad` defaults to the tracking remote of the checked-out branch in the main worktree.
3. Use `git pad track` to set the tracking remote no matter which branch is checked out in the main worktree.

But it does not tell me about what to do when `git pad status` is run.
Check the remote or check only just local changes?


## Steps to Reproduce

## Expected Behavior

## Notes
