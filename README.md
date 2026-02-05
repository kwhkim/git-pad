# git-pad

## Philosophy

* most commands are just like git commands 
  * status,commit,push,fetch,merge

* No staginag area
  * commit = add + commit (in git) 

## gissue

* Git-Embedded Distributed Issues Management System
  * `git-issue` : dispatcher for commands like `git issue init`, `git issue new`, etc.
    * `git-issue-mvp` : functions like `git_issue_init`
    * `new_filename.sh` 
      * `gen_repo_id` : random 6 alphabets
      * `repo_id_in_use $1` : check if `$1` is used in any issue file
      * `next_seq KSTEDF .md` : `KSTEDF-nnnn.md`라는 파일 형식에서 가장 마지막 `nnnn` 다음 
      * `new_filename .md` : `.md` 파일에서 새로운 파일 이름

* GitHub-Issues
  * `injest.sh`
  * `state.json`
  
## Design

* Distributed
  * No 3rd-party service needed -> No vendor lock-in
  * To avoid conflicts between locally generated issue files, we used random filename base on local repository
* Issues are stored in the same repository
  * No another independent repository(main point of git-native issue tracking tool)
* Issues reside in a seperate folder and have different isolated history
  * Using custom ref, issue-ref would not be shown in `git branch`
  * Issues isolated from codes
* Issues, comments are markdown files
  * Easy to create, modify
  * Easy to search and custom advanced search is possible(using other tools of your choice)
    * issues are just markdown files so you can go into the folder and use `grep`, `ag`, `rg`, etc. if you need.
* Minimal dependency
  * in bash scripts
  * No server-side setup required
  * lightweight
  
## Usage

```
PATH=$PATH:$(pwd)  # replace $(pwd) with the directory name where git-pad, git-pad-func.sh live
git issue init # or git issue clone if there is already remote 
git issue list
# A
git issue new # or git issue edit $ISSUE_ID
git issue comment $ISSUE_ID
git issue status
git issue commit
git issue push
git issue fetch
git issue merge
git issue list
# goes to A
```
  
## Related Projects(as-of 2026.02.04)

* [git-appraise](https://github.com/google/git-appraise)
  * latest release : 2021.04.23
* [BE(Bugs-Everywhere)](https://github.com/aaiyer/bugseverywhere)
  * issues dependent on a branch
  * implemented in python
  * latest release(1.1.1) : 2012.11.17
* [git-issue](https://github.com/dspinellis/git-issue)
  * independent repository
  * implemented in bash
* [git-bug](https://github.com/git-bug/git-bug)
  * custom reference 
    * `git log` gets messy as the number of bugs increases
      * IDE git history looks messy(eg. VSCode)
    * `git gc` or `git fsck` gets slower
* [git-dit](https://github.com/git-dit/git-dit)
  * issues are represented by empty commits(No file changes)
  * issue-commits using git's ref(`refs/dit`)
  * latest release(0.4.0) : 2017.09.15

## Promotion

* 
