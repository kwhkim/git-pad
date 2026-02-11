#PATH=$PATH:$(realpath ~/git/git-pad)

# if [ ! -d R1 ]; then git clone git@github.com:kwhkim/git-pad.git R1; fi

# #if [ ! -d bare1.git ]; then git clone --bare git@github.com:kwhkim/git-pad.git bare1.git; fi
# if [ -d bare1.git ]; then rm bare1.git || rm -rf bare1.git; fi
# git clone --bare git@github.com:kwhkim/git-pad.git bare1.git

cd git-pad-test && echo "git-pad-test"

cd R1 && echo "R1"
git pad list 
git pad status 
git pad remote
git pad track

git pad init --no-clone
git pad new --title="first issue" --body="This is for testing"
git pad new --title="second issue" --body="This is second issue"

git pad status
git pad commit -m "R1 first commit"

git pad list
git pad new --title="third issue" --body="This is the third"
git pad status
git pad commit -m "R1 second commit"

git remote add local ../bare1.git
git pad track local
git pad push local

cd ..

if [ ! -d R2 ]; then git clone bare1.git R2; fi
cd R2 && echo R2
git pad clone
git pad list
git pad status

git pad new --title="4th issue" --body="This is 4th" --type="announcement" --priority="P1"
git pad new --title="5th issue" --body="This happens when ..." --type="bug" --priority="P1"
git pad commit -m "R2 issue number 4 and 5"

git pad push
cd ..

if [ ! -d R3 ]; then git clone bare1.git R3; fi
cd R3

git pad init --clone
git pad list
git pad status
git pad pull

pwd
cd ..

if [ ! -d R4 ]; then git clone bare1.git R4; fi

if [ ! -d R5 ]; then git clone bare1.git R5; fi

pwd
cd R5 && git pad init --clone && cd ..

pwd
cd R4
git pad clone

id=$(git pad list | awk '{print $1}' | grep -v ID | head -1)
git pad comment "$id" -m "Looks good. keep it up"

git pad new --title="6th issue" --body="This is 6th" --type="announcement" --priority="P2"
git pad commit -m "R4 commit 1"
git pad new --title="7th issue" --body="This happens when ..." --type="bug" --priority="P2"
git pad commit -m "R4 commit 2"

git pad push
cd ..

cd R3
pwd
git pad pull
cd ..

cd R5
pwd

git pad new --title="6th another issue" --body="This is 6th" --type="announcement" --priority="P2"
git pad commit -m "R5 commit 1b"
git pad new --title="7th another issue" --body="This happens when ..." --type="bug" --priority="P2"
git pad commit -m "R5 commit 2b"

id=$(git pad list | awk '{print $1}' | grep -v ID | head -1)
git pad comment "$id" -m "Let's get rolling."

git pad push || true
git pad pull
git pad list

cd - 


if [ ! -d R6 ]; then git clone bare1.git R6; fi



