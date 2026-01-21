---
title: Selecting possible statuses(lifecycle of issues)
type: enhancement
priority: low
status: open
---

## Description

Status needs to have well-defined terms to describe the current status in the life-cycle of issues.
The meaning of "Open" can be confusing. Is it "open for review" or "work in progress"?

## Steps to Reproduce

## Expected Behavior

Selection of terms to describe the current status in the life-cycle of issues. 

For example:

*  **pending**(open for review), **accepted**(reviewed and approved), **wontfix**(valid but won't be addressed)
   **in-progress**(currently being worked on), **resolved**(work complete, awaiting verification), 
   **closed**(verified complete), **invalid**(created by mistake), **duplicate**, **splitted**, **replaced**
   
Or, we might be better off having another field like review-status and verification-status.
For example, reviewed=not yet|accepted|duplicate|wontfix, status=open|wip|paused|in-verification|closed, verfication=...

Or, the user might be better off choosing one of different issue-life-cycle models or proposing their own.


## Notes

* Github : open | draft | closed

