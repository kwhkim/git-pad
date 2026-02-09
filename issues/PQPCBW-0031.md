---
title: enable tab-completion
type: enhancement
priority: P2
---

## Description

Enable the following usage.

```
git pad <tab-completion>
git pad edit <tab-completion> # for issue ID, possibly respect .local-repo-id
```

## Steps to Reproduce

## Expected Behavior

## Notes

### The "Native" Way (Bash)

Git looks for a bash function named _git_<commandname> to provide completions. If you have a custom command git-appraise, you can create a completion script.

For git-appraise: The developers actually provide a completion script in the repository. To enable it:

1. Locate the `assets/bash_completion` file in the git-appraise source.

2. Source it in your `.bashrc`:

```
source /path/to/git-appraise/assets/bash_completion
```

For a DIY Command: If you wrote your own script called git-hello, you would add this to your `.bashrc`:

```
_git_hello() {
  __gitcomp "world sun moon"
}
```

Now, typing git hello <TAB> will suggest world, sun, and moon.

### How Git Locates Completions

Git's own completion script (usually found at `/usr/share/bash-completion/completions/git`) is the "master" controller. Here is how the logic flow works:

1. You type git app <TAB>.

2. The shell hits the main Git Completion Script.

3. It looks for a function named _git_appraise.

4. If found, it executes that function to populate the suggestions.

5. If not found, it simply attempts to complete filenames in your current directory.
