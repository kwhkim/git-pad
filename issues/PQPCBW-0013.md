---
title: automatically reflect issue resolution by commit(eg. resolves #...)
type: enhancement
priority: P2
status: open
---

## Description

github supports automatic status change by commit messages like resolves #(issue-number), fixes #(issue-number).

## Steps to Reproduce

## Expected Behavior

A commit with a message include "close/close/fix... #ABCDEF-0000" automatically change the status of the issue by
1. post-commit hooks?
2. `git pad auto-close` : automatically change the status of the issues reference in **the last commit message**
  - what if no status in yaml?
 

## Notes

Github supports automatic closing an issue by reference in commit message(ex. Closes #10, Fixes octo-org/octo-repo#100).

```
    close
    closes
    closed
    fix
    fixes
    fixed
    resolve
    resolves
    resolved
```

Following types are also supported.

```
    Resolves #10, resolves #123
    Closes: #10
    CLOSES: #10
```


* Reference
  - [GitHub Docs: Using keywords in issues and pull requests](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/using-keywords-in-issues-and-pull-requests)

