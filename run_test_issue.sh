#PATH=$PATH:$(realpath ~/git/git-issue)

# if [ ! -d R1 ]; then git clone git@github.com:kwhkim/git-issue.git R1; fi

# #if [ ! -d bare1.git ]; then git clone --bare git@github.com:kwhkim/git-issue.git bare1.git; fi
# if [ -d bare1.git ]; then rm bare1.git || rm -rf bare1.git; fi
# git clone --bare git@github.com:kwhkim/git-issue.git bare1.git

cd git-issue-test && echo "git-issue-test"

cd R1 && echo "R1"

git issue list 
git issue status 
git issue remote
git issue track

git issue init --no-clone
git issue new --title="first issue" --body="This is for testing"
git issue new --title="second issue" --body="This is second issue"

git issue status
git issue commit -m "R1 first commit"

git issue list
git issue new --title="third issue" --body="This is the third"
git issue status
git issue commit -m "R1 second commit"

git remote add local ../bare1.git
git issue track local
git issue push local

cd ..

if [ ! -d R2 ]; then git clone bare1.git R2; fi
cd R2 && echo R2
git issue clone
git issue list
git issue status

git issue new --title="4th issue" --body="This is 4th" --type="announcement" --priority="P1"
git issue new --title="5th issue" --body="This happens when ..." --type="bug" --priority="P1"
git issue commit -m "R2 issue number 4 and 5"

git issue push
cd ..

if [ ! -d R3 ]; then git clone bare1.git R3; fi
cd R3 && echo R3

git issue init --clone
git issue list
git issue status
git issue pull

pwd
cd ..

if [ ! -d R4 ]; then git clone bare1.git R4; fi

if [ ! -d R5 ]; then git clone bare1.git R5; fi

pwd
cd R5 && git issue init --clone && cd ..

pwd
cd R4
git issue clone

id=$(git issue list | awk '{print $1}' | grep -v ID | head -1)
git issue comment "$id" -m "Looks good. keep it up"

git issue new --title="6th issue" --body="This is 6th" --type="announcement" --priority="P2"
git issue commit -m "R4 commit 1"
git issue new --title="7th issue" --body="This happens when ..." --type="bug" --priority="P2"
git issue commit -m "R4 commit 2"

git issue push
cd ..

cd R3
pwd
git issue pull
cd ..

cd R5
pwd

git issue new --title="6th another issue" --body="This is 6th" --type="announcement" --priority="P2"
git issue commit -m "R5 commit 1b"
git issue new --title="7th another issue" --body="This happens when ..." --type="bug" --priority="P2"
git issue commit -m "R5 commit 2b"

id=$(git issue list | awk '{print $1}' | grep -v ID | head -1)
git issue comment "$id" -m "Let's get rolling."

git issue push || true
git issue pull
git issue list

cd - 


if [ ! -d R6 ]; then git clone bare1.git R6; fi


