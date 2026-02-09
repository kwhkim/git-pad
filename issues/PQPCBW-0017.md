---
title: git pad merge, resolve conflict
type: feature
priority: P1
status: closed
---

## Description

`git pad merge` for merging remote issues with local issues.
merge with ff if possible.
merge with rebase if no conflict.
stop if conflict, edit manually, and do `git pad merge --continue`, `git pad commit` or `git issue pad --abort`

`git pad merge --rebase` for rebase, or merge by default

## Steps 

Testing suites?

```{bash}
git pad init
git pad new --title $TITLE --type $TYPE --priority $PRIORITY --status $STATUS --body $BODY
git pad commit

git pad new --title $TITLE --type $TYPE --priority $PRIORITY --status $STATUS --body $BODY
git pad commit
git pad push

git pad new --title $TITLE --type $TYPE --priority $PRIORITY --status $STATUS --body $BODY
git pad commit

git pad new --title $TITLE --type $TYPE --priority $PRIORITY --status $STATUS --body $BODY
git pad commit
```

```{bash}
git pad clone
```



## Expected Behavior

## Notes

Imported from 0006.md
