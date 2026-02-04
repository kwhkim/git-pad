---
title: save adjustable `SLICE_MINUTES_FORWARD1`, `SLICE_MINUTES_FORWARD2`, `SLICE_MINUTES_BACKWARD`
type: enhancement
priority: P3
---

## Description

Those variable above determines the scan slice range.
Too large would make long paginattion so interrupted scan ends in loss of data.
Too small would make large proportion of data received useless(out of scan slice range, except for forward range)

There is adjusting mechanism(doubling or halving)
but it is **not stored for later use.**

## Steps to Reproduce

## Expected Behavior

## Notes

* There is no `until` parameter in gh's graphQL 
  * `since` with `ASC`
  * `since` with `DESC` : from now to the old 
