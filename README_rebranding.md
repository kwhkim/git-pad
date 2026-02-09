## Rebrand git-issue to git-pad

1. rename filenames
   - `git-issue`, `git-issue-mvp` -> `git-pad`, `git-pad-utils`
     - Replace RE `git([-_ ])issue` to `git$1pad`

2. rename folder name `.issue` to `.git-pad` (in `git-pad-utils`)
   - Replace `.issues` to `$WT_FOLDER` ( with `WT_FOLDER=".git-pad"`)
3. rename function names in `git-pad-utils` and `run_test.sh`
  - Replace RE `git([-_ ])issue` to `git$1pad`