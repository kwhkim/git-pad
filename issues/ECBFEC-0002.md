---
title: CJK characters can ruin table columns
type: bug
priority: P2
status: open
---

## Description

## Steps to Reproduce

## Expected Behavior

## Notes

* We can use CHA(Cursor Horizontal Absolute)
  - `ESC [ n G`
    - 1-based : start of line = 1
  - `ESC [ K` : clear to end of line
  - `ESC [ 2K` : clear entire line


```
a="한글을 쓰면 위치 설정이 어긋난다."
b="Hangul makes column width vary"
printf "%-40s %-30s\n" "$a" "$b"
printf "%-40s %-30s\n" "$b" "$b"
printf "\033[1G%s\r\033[42G%s\n" "$a" "$b"
printf "\033[1G%s\r\033[42G%s\n" "$b" "$b"
```
