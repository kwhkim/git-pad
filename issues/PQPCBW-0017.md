---
title: git issue merge, resolve conflict
type: feature
priority: P1
status: open
---

## Description

`git issue merge` for merging remote issues with local issues.
merge with ff if possible.
merge with rebase if no conflict.
stop if conflict, edit manually, and do `git issue merge --continue`, `git issue commit` or `git issue merge --abort`

## Steps 

Testing suites?

```{bash}
git issue init
git issue new --title $TITLE --type $TYPE --priority $PRIORITY --status $STATUS --body $BODY
git issue commit

git issue new --title $TITLE --type $TYPE --priority $PRIORITY --status $STATUS --body $BODY
git issue commit
git issue push

git issue new --title $TITLE --type $TYPE --priority $PRIORITY --status $STATUS --body $BODY
git issue commit

git issue new --title $TITLE --type $TYPE --priority $PRIORITY --status $STATUS --body $BODY
git issue commit
```

```{bash}
git issue clone




## Expected Behavior

## Notes

Imported from 0006.md
