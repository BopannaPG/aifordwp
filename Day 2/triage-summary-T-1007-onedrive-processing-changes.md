# Structured Triage Summary

## Summary (one line)
Ticket T-1007 reports OneDrive is stuck on "processing changes" since migration and files are missing locally.

## Impact (who/how many/business urgency)
- Who is affected: Reported user (to-verify).
- How many affected: One reported case (to-verify if wider post-migration).
- Business urgency: Local file access may be reduced where files are missing, impacting productivity (urgency to-verify).

## known facts
- Ticket reference: T-1007.
- OneDrive status is reported as "processing changes".
- Condition reported since migration.
- Files are reported missing locally.

## Missing information to gather
- Whether files are missing only locally or also missing in OneDrive web view.
- Approximate number/types of missing files and affected folders.
- Current OneDrive sync status details and any visible warnings.
- Available local disk space and Files On-Demand state.
- Whether issue affects one device only or multiple devices for same user.
- Migration timing and whether initial sync ever completed.
- Whether pausing/resuming sync or sign-out/sign-in was attempted and result.

## likely catagory
- File Sync / OneDrive Post-Migration Sync Degradation (to-verify).

## First diagnostic step
- Compare affected folders in OneDrive web versus local File Explorer to confirm whether data exists in cloud but is not syncing locally, which separates sync-client issues from potential data-location issues (to-verify result).
