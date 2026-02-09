# git-pad

## Philosophy

* most commands are just like git commands 
  * status,commit,push,fetch,merge

* No staginag area
  * commit = add + commit (in git) 
  
## Design

* Distributed
  * No 3rd-party service needed -> No vendor lock-in
  * To avoid conflicts between locally generated issue files, we used random filename base on local repository
* Issues are stored in the same repository
  * No another independent repository(main point of git-native issue tracking tool)
* Issues reside in a seperate folder and have different isolated history
  * Using custom ref, issue-ref would not be shown in `git branch`
  * Using worktree, you can do whatever git commands in the linked worktree(eg. .issues/)
  * Issues isolated from codes
* Issue file names are simple and readable
  * Most hash or ULID, UUID are long and hard to read
  * Intentionally choose to use sequence with repo ID(which is random 6 alphabets) (eg. `ABCDEF-000001`)
* Issues, comments are markdown files
  * Easy to create, modify
    * You can add custom fields in addition to `title:`, `status:`, etc.
  * Easy to search and custom advanced search is possible(using other tools of your choice)
    * issues are just markdown files so you can go into the folder and use `grep`, `ag`, `rg`, etc. if you need.
* Commands are just like git
  * most commands work like git(status/commit/push/fetch/merge) except for
    * no staging area, so no add
    * no push --force, push --force-with-lease
      * intentionally no re-writing history
* Minimal dependency
  * in bash scripts
  * No server-side setup required
  * lightweight
* Freedom to customize
  * You can use pre-commit, post-commit hooks.
    * eg. Use AI API to polish issues
  
## Usage

```{bash}
PATH=$PATH:$(pwd)  # replace $(pwd) with the directory name where git-pad, git-pad-func.sh live
git pad init # or git pad clone if there is already remote 
git pad list
# A

git pad show $ISSUE_ID
git pad comment $ISSUE_ID

git pad new # or git pad edit $ISSUE_ID
git pad edit $ISSUE_ID
git pad comment $ISSUE_ID
git pad status
git pad commit

git pad fetch
git pad merge
# When conflicts, git pad edit $ISSUE_ID
git pad push

git pad list
# goes to A
```

## Implementation detail

* Git-Embedded Distributed Issues Management System
  * `git-pad` : dispatcher for commands like `git pad init`, `git pad new`, etc.
    * `git-pad-utils` : functions like `git_pad_init`
    * `new_filename.sh` 
      * `gen_repo_id` : random 6 alphabets
      * `repo_id_in_use $1` : check if `$1` is used in any issue file
      * `next_seq KSTEDF .md` : `KSTEDF-nnnn.md`라는 파일 형식에서 가장 마지막 `nnnn` 다음 
      * `new_filename .md` : `.md` 파일에서 새로운 파일 이름

* GitHub-Issues
  * `gh_list_download.sh` : download github issue list 
    * Forward time slice scan first, then Backward time slice scan.
  * `gh_list_state.json`
    * Stores the coverage of github issues updates

* History
  * Originally named `git-issue`. But there is already another project named `git-issue`(see Related Projects), so it was renamed to **git-pad**. So the filename and functions are all renamed to **pad**(commit `...`).

  
## Related Projects(as-of 2026.02.04)

* [Yona: Project Hosting SW](https://github.com/yona-projects/yona)
  * Git/SVN + MariaDB
  * latest release(1.16.0) : 2023.01.09
* [git-appraise](https://github.com/google/git-appraise)
  * uses Git Notes, a built-in Git feature for attaching metadata to commits without modifying the commits themselves.
    * Not easy to modify, search(use `git grep`) 
  * Implemented in Go, requires Go tools installed.
  * latest release : 2021.04.23
* [BE(Bugs-Everywhere)](https://github.com/aaiyer/bugseverywhere)
  * issues dependent on a branch
  * implemented in python
  * latest release(1.1.1) : 2012.11.17
* [git-issue](https://github.com/dspinellis/git-issue)
  * independent repository
  * implemented in bash
  * latest commit : 4 months ago
* [git-bug](https://github.com/git-bug/git-bug)
  * custom reference 
    * `git log` gets messy as the number of bugs increases
      * IDE git history looks messy(eg. VSCode)
    * `git gc` or `git fsck` gets slower
  * latest release : 2025.05.19
* [git-dit](https://github.com/git-dit/git-dit)
  * issues are represented by empty commits(No file changes)
  * issue-commits using git's ref(`refs/dit`)
  * latest release(0.4.0) : 2017.09.15
* [git-track](https://github.com/dhesse/Git-Track)
  * no git-native, local(cannot be shared using git)
  * latest commit : 15 years ago

## Discussion about git-native issue tracking tools

* [reddit/git](https://www.reddit.com/r/git/)
* [reddit: Decentralized Issue Tracking](https://www.reddit.com/r/programming/comments/4od2ni/decentralized_issue_tracking/)
* [reddit: What is your simple issue tracking system](https://www.reddit.com/r/git/comments/wg6mk6/what_is_your_simple_issue_tracking_system/)
* [StackOverflow: Is possible to store repository issues in the git repository?](https://stackoverflow.com/questions/19938579/is-possible-to-store-repository-issues-in-the-git-repository)
* [StackOverflow: Keeping track of To-Do and issues in Git](https://stackoverflow.com/questions/7060973/keeping-track-of-to-do-and-issues-in-git)
