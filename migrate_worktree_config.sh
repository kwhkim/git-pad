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
