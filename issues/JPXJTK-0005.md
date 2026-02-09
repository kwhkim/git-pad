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



## Steps to Reproduce

## Expected Behavior

## Notes
