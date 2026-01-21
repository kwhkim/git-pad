---
title: function new_filename - UID(Unique Identifier) for local repo
type: feature
priority: high
status: closed
---

## Description

issue file naming
* needs to be unique while run in a distributed environment(no central repo)
  * sequential numbering would result in conflicts
  * merging the files with the other file with same name(but contents is totally different) would be pain in the ass
* still needs to be UX-friendly but full hash, ULID, UUID is not friendly
* sequential numbering is UX-friendly
* 6 random characters + sequential numbering
  * 6 random characters for local repository UID
    * I avoided hash, ULID, UUID because they are composed of numbers and alphabets 
    * It would be easier to deal with all alphabets(local repo UID) and numbers.
    * Crockford Base32 was chosen for better UX(I,L,O are excluded becasue they can be confused with each other).
  * sequential numbering for multiple files in a repo
  * for display purpose, 6 characters could be shortened if there is no ambiguity(no other files starts with A or AE) 

## Steps to Reproduce

* function `new_filename ""` for file ID(just without extensions like .md)
* modify other functions to replace "4 digits.md" to "local-repo-uid-4digits.md"

## Expected Behavior

* New issue filename almost never conflicts.
  * Using 6 Crockford Base32 alphabets(23 letters), there are 23^6=148035889 possibilities.
  * birthday problem : for 1000 local repos, collision prob is ~ 0.001%


## Notes

* Other ways to garauntee the uniqueness of the filename would be allocate through central repository 
  * Given only fast-forward push is allowed to the central repo, keep a file named "reserved-numbers.txt"
  * When a user wants to create a new file, pull and add a number to "reserved-numbers.txt" and push
  * If it works, you get the number which is unique over all repositories.
  * If push is failed, pull again and add a number to "reserved-numbers.txt" and push and repeat the process until the push is successful

