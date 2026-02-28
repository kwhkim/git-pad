---
title: enable tab-completion
type: enhancement
priority: P2
status: open
---

## Description

Enable the following usage.

```
git pad <tab-completion>
git pad edit <tab-completion> # for issue ID, possibly respect .local-repo-id
```

## Steps to Reproduce

## Solution


* The following works for bash, but not for zsh(MacOS)

```bash
_git_pad ()
{
    local cur prev words cword
    _init_completion || return

    local subcommands="init edit status commit comment log list show search remove clone track remote push pull fetch merge version"

    # First argument after `pad`
    if [[ $cword -eq 2 ]]; then
        __gitcomp "$subcommands"
        return
    fi

    case "${words[2]}" in
        edit)
            #local common_dir="$(__git_common_dir)" || return
            local common_dir="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
            local pad_dir="$common_dir/.git-pad/issues"
            
            [[ -d "$pad_dir" ]] || return
            
            # # Complete filenames from $pad_dir
            # local IFS=$'\n'
            # local files=( $(cd "$pad_dir" && printf '%s\n' *.md) )
            
            local files=()
            while IFS= read -r f; do
                files+=( "${f%.md}" )
            done < <(cd "$pad_dir" && compgen -G "*.md")

            __gitcomp "${files[*]}"
            ;;
    esac
}
```



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
