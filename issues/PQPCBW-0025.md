---
title: extensions.worktreeConfig true necessary?
type: enhancement
priority: P2
status: open
---

## Description

`git config --local extensions.worktreeConfig true` requires a setup for `core.bare` and `core.worktree`.
In short, local configuration for `core.bare` and `core.worktree` will be shared across worktrees,
when `git config --local extensions.worktreeConfig true` is done,
if there is no `core.bare` and `core.worktree` in `"$(git rev-parse --git-path config.worktree)"`(done in a linked worktree).

* Reasons for setting `extensions.worktreeConfig` to `true`
  * `advice.detachedHead`
  * `core.hooksPath`
    * to evade hooks,
      * `git commit --no-verify` : pre-commit, commit-msg, etc.
      * `git push --no-verify` : pre-push
      * `git merge --no-verify` : pre-merge-commit, commit-msg
      * `git rebase --no-verify` : pre-rebase
      * `git am --no-verify` : pre-applypatch

* How to migrate `core.bare` and `core.worktree` to `config.worktree` for main worktree.
  * If there were no linked worktrees, set up before creating one.
  * If there were already linked worktrees, sequence is important(in one script, 1. worktreeConfig true, 2. migrate to main worktree's config.worktree, 3. set linked worktree's config.worktree)

* Scripts for migrating config

```{bash}
#!/bin/bash

# 1. Enable the extension
echo "Enabling extensions.worktreeConfig..."
git config extensions.worktreeConfig true

# 2. Identify paths
MAIN_DOT_GIT=$(git rev-parse --git-common-dir)
MAIN_WORKTREE_CONFIG="$MAIN_DOT_GIT/config.worktree"

# 3. Migrate Main Worktree settings
# We extract core.worktree and core.bare from the shared config 
# and move them to the main worktree's private config file.
echo "Migrating main worktree settings..."

WORKTREE_PATH=$(git config --get core.worktree)
BARE_SETTING=$(git config --get core.bare)

if [ ! -z "$WORKTREE_PATH" ]; then
    git config --file "$MAIN_WORKTREE_CONFIG" core.worktree "$WORKTREE_PATH"
    git config --unset core.worktree
fi

if [ ! -z "$BARE_SETTING" ]; then
    git config --file "$MAIN_WORKTREE_CONFIG" core.bare "$BARE_SETTING"
    git config --unset core.bare
fi

# 4. Loop through all linked worktrees and set their local core.worktree
echo "Configuring linked worktrees..."

git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2- | while read -r wt_path; do
    # Skip the main worktree (already handled)
    if [ "$wt_path" == "$(git rev-parse --show-toplevel)" ]; then
        continue
    fi
    
    echo "Processing worktree: $wt_path"
    
    # Enter the worktree and set its specific path in its private config
    (
        cd "$wt_path" || exit
        git config --worktree core.worktree "$wt_path"
        git config --worktree core.bare false
    )
done

echo "Done! Your worktrees are now isolated."
``` 

* Script for creating a first worktree(set up first and then create)

```{bash}
#!/bin/bash

# Usage: ./git-add-worktree-w-config.sh <path> <branch>

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <path> [<branch>]"
    exit 1
fi

TARGET_PATH=$1
BRANCH=$2
MAIN_DOT_GIT=$(git rev-parse --git-common-dir)
MAIN_WORKTREE_CONFIG="$MAIN_DOT_GIT/config.worktree"

# 1. Check if extensions.worktreeConfig is already enabled
IS_ENABLED=$(git config --get extensions.worktreeConfig)

if [ "$IS_ENABLED" != "true" ]; then
    echo "Initializing worktreeConfig extension..."
    
    # Enable the extension
    git config extensions.worktreeConfig true
    
    # 2. Migrate Main Worktree settings BEFORE adding new ones
    # We grab the current core settings from the shared config
    OLD_WORKTREE=$(git config --get core.worktree)
    OLD_BARE=$(git config --get core.bare)

    echo "Migrating main repository settings to config.worktree..."
    
    # If core.worktree isn't set, the default is usually the parent of .git
    if [ -z "$OLD_WORKTREE" ]; then
        OLD_WORKTREE=$(git rev-parse --show-toplevel)
    fi

    # Write to the private main config
    git config --file "$MAIN_WORKTREE_CONFIG" core.worktree "$OLD_WORKTREE"
    git config --file "$MAIN_WORKTREE_CONFIG" core.bare "${OLD_BARE:-false}"
    
    # Remove from the shared config so linked worktrees don't inherit them
    git config --unset core.worktree
    git config --unset core.bare
    echo "Main repository isolated."
fi

# 3. Now safely add the new worktree
echo "Adding new worktree at $TARGET_PATH..."
if [ -z "$BRANCH" ]; then
    git worktree add "$TARGET_PATH"
else
    git worktree add "$TARGET_PATH" "$BRANCH"
fi

# 4. Final Touch: Ensure the NEW worktree also has its own core settings
# git worktree add usually handles this, but we force it to be absolute 
# to avoid any 'relative path' confusion.
(
    cd "$TARGET_PATH" || exit
    ABS_PATH=$(pwd)
    git config --worktree core.worktree "$ABS_PATH"
    git config --worktree core.bare false
    echo "Success: Worktree at $ABS_PATH is fully isolated."
)
```

## Steps to Reproduce

## Expected Behavior

## Notes

* reference
  * [git-worktree](https://git-scm.com/docs/git-worktree)
  * [git-config](https://git-scm.com/docs/git-config)

* terms
  * main worktree
  * linked worktree
