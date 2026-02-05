---
title: seperate issue-hook
type: feature
priority: P2
status: closed
---

## Description

.issues worktree에서 커밋 등을 할 때, 훅이 실행되는 것은 문제이다. 일반적인 훅과 구별되는 훅을 운영해야 한다.

예)
```
GIT_COMMON_DIR=$(git rev-parse --git-common-dir)
git -c core.hooksPath="$GIT_COMMON_DIR/hooks-issue" -C $(basename "$GIT_COMMON_DIR")/.issues commit -m "seperate issue hook testing"
```

근데 `git rev-parse --git-common-dir`은 전혀 다른 곳에 있을 수도 있으므로 `git worktree list` 등을 활용해야 되는 거 아님?

참고

```
git_project_root() {
    git worktree list --porcelain |
    awk '$1=="worktree" { print $2; exit }'
}
```

Or possibly, `dirname "$(git rev-parse --git-common-dir)"`

Testing,

```
if [ "$(git_project_root)" != "$(realpath $(dirname $(git rev-parse --git-common-dir)))" ]; then echo "alarm!"; fi
```

## Steps to Reproduce

## Expected Behavior

* 훅을 아예 제거하는 방법 : worktree마다 다른 hook(core.hooksPath)

```
cd $root
git config --local extensions.worktreeConfig true
cd $wt
git config --worktree core.hooksPath /dev/null 
```

* 혹은 commit의 경우는

```
git commit --no-verify 
```

## Notes


