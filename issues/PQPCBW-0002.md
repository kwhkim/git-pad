---
title: git remote add local 사용시 주의 사항
type: enhancement
priority: P3
status: closed(4d73266476a52336ed94b4e5b319cf9906fb94ba)
---

## Description

git remote add local ../git-pad-local-remote.git
이런 식으로 지정하면 worktree에서 remote를 쓸 수가 없다.

## Steps to Reproduce

## Expected Behavior

만약 git pad push $REMOTE에서 REMOTE가 ../git-issue-local-remote.git과 같이 되어 있다면 삭제 후 다시 등록할 수 있는 방법을 제시한다.
`$(git_project_root)`에서 ../git-pad-local-remote.git까지 path를 구해서 다시 등록할 수 있는 방법을 안내한다.

## Notes

