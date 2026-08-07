# Runbook: Finance Shared Drive Mapping Failure (SYSTEM Context Script)

Title: Finance Shared Drive Mapping Failure (SYSTEM Context Script)
Version: 1.0
Date: 07/08/2026
Author: Sathishbabu
Reviewed: self
Status: draft
Change: initial version from RCA

## 1) Prerequisites

Pre-start checklist (complete all items before Step 1):

Access and permissions:
- [ ] Intune admin role with rights to edit Windows scripts and assignments in Microsoft Intune admin center (`https://endpoint.microsoft.com`). [ELEVATED]
- [ ] Local Administrator rights on at least one affected endpoint for log collection and validation commands. [ELEVATED]
- [ ] Access to incident ticketing system to update timeline and attach evidence.

Tools and consoles:
- [ ] Browser access to Intune portal: `https://endpoint.microsoft.com`.
- [ ] Event Viewer available on pilot endpoint (`eventvwr.msc`).
- [ ] PowerShell (Run as Administrator) available on pilot endpoint. [ELEVATED]
- [ ] File Explorer access to endpoint logs folder: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`.

Mandatory information from end user / requester:
- [ ] Affected username and UPN.
- [ ] Affected device name (must match `DESKTOP-FB*`).
- [ ] Approximate failure timestamp (local time) and timezone.
- [ ] Exact symptom wording (for example: "S: drive missing" or "cannot open \\finbridge-fs01\Finance").
- [ ] Confirmation whether issue is still active or intermittent.

Mandatory technical scope details:
- [ ] Confirm OU/scope is Finance.
- [ ] Confirm mapped drive letter is `S:`.
- [ ] Confirm UNC target is `\\finbridge-fs01\Finance`.
- [ ] Confirm change reference exists: migration from USER logon mapping to Intune SYSTEM script.
- [ ] Identify one pilot device for first deployment validation.
- [ ] Confirm prior known-good user logon mapping method is available for rollback.

## 2) Procedure
1. Open the incident ticket and set the pilot endpoint hostname in the work notes.
Expected result: One pilot device is explicitly recorded for controlled validation.

2. On the pilot endpoint, open File Explorer and browse to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`.
Expected result: IME log folder is accessible.

3. Open `IntuneManagementExtension.log` in Notepad.
Expected result: Raw IME execution log is visible for timestamped evidence.

4. Search the log file for `Map-FinBridgeDrives.ps1`.
Expected result: Script execution block is located.

5. Capture the line showing `Script context: SYSTEM account` if present.
Expected result: Current execution identity is documented in ticket notes.

6. Capture the line showing UNC failure for `\\finbridge-fs01\Finance` and the line with `Exit code: 1` if present.
Expected result: Pre-change failure evidence is documented in ticket notes.

7. Open Event Viewer by running `eventvwr.msc` on the pilot endpoint.
Expected result: Event Viewer console opens.

8. Navigate to `Event Viewer > Windows Logs > System`.
Expected result: System log stream is displayed.

9. Select `Filter Current Log...` and set `Event IDs` to `7036,1500,98`.
Expected result: System log view is reduced to target incident signals.

10. Record matching events near the failure timestamp in the ticket.
Expected result: Baseline timeline contains service state, GP status, and drive assignment evidence.

11. Open the Intune admin center at `https://endpoint.microsoft.com`. [ELEVATED]
Expected result: Intune portal is accessible with admin permissions.

12. Navigate to `Devices > Scripts and remediations > Platform scripts`. [ELEVATED]
Expected result: List of deployed Windows scripts is displayed.

13. Open the script object that deploys `Map-FinBridgeDrives.ps1`. [ELEVATED]
Expected result: Script details page is open.

14. Select `Edit` and change execution to a user-session-safe mapping method instead of SYSTEM-only execution. [ELEVATED]
Expected result: Mapping design no longer depends on SYSTEM session credentials/timing.

15. Add retry/backoff logic to the mapping script with exactly 3 attempts and a short delay between attempts. [ELEVATED]
Expected result: Transient startup failures can recover without manual intervention.

16. Add a pre-check in script logic that confirms `\\finbridge-fs01\Finance` is reachable before mapping `S:`. [ELEVATED]
Expected result: Mapping is attempted only when target UNC is reachable.

17. Save the script update in Intune. [ELEVATED]
Expected result: Updated script version is published.

18. In the same script object, open `Assignments` and target only the pilot device/user group first. [ELEVATED]
Expected result: Change scope is safely limited to pilot.

19. On the pilot endpoint, open `Settings > Accounts > Access work or school`, select the connected work account, and click `Info`.
Expected result: Device management sync page is displayed.

20. Click `Sync` on the device management page.
Expected result: Endpoint starts policy retrieval from Intune.

21. Sign out and sign back in on the pilot endpoint.
Expected result: Updated mapping flow executes during user session.

22. Open File Explorer and confirm drive `S:` is present.
Expected result: `S:` appears in This PC.

23. Open `S:` and confirm the path resolves to `\\finbridge-fs01\Finance`.
Expected result: Finance share contents open successfully.

24. Reopen `IntuneManagementExtension.log` and search for new `Map-FinBridgeDrives.ps1` entries after sign-in.
Expected result: No new SYSTEM-context UNC failure and no new exit code 1 pattern.

25. In Event Viewer System log, confirm no new Event ID 98 for missing `S:` in the post-fix window.
Expected result: No fresh S: assignment failure after pilot fix.

26. In Event Viewer System log, confirm GroupPolicy Event ID 1500 remains successful post-fix.
Expected result: GP health remains normal.

27. In Intune `Assignments`, expand target from pilot to Finance scope (DESKTOP-FB* / OU=Finance). [ELEVATED]
Expected result: Updated mapping is deployed to affected production scope.

28. Trigger `Sync` on at least three additional affected Finance endpoints.
Expected result: Representative endpoints receive the updated configuration.

29. Validate `S:` presence and open test to `\\finbridge-fs01\Finance` on each sampled endpoint.
Expected result: Service restoration is confirmed across scope.

30. Add final timeline, log excerpts, event IDs, and validation outcomes to the incident ticket.
Expected result: Ticket contains complete closure evidence and audit trail.

## 3) Verification
1. On the pilot endpoint, open File Explorer and verify `This PC > S:` is present.
Expected result: `S:` is visible without delay after sign-in.

2. On the pilot endpoint, open `S:` and confirm it loads `\\finbridge-fs01\Finance`.
Expected result: Finance share folders open successfully.

3. On the pilot endpoint, open File Explorer and browse to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`.
Expected result: IME log folder is accessible.

4. Open `IntuneManagementExtension.log` and search for `Map-FinBridgeDrives.ps1` entries after fix timestamp.
Expected result: New run entries exist for post-fix execution window.

5. In the same log view, verify no post-fix line contains `Script context: SYSTEM account` together with UNC failure for `\\finbridge-fs01\Finance`.
Expected result: No repeated SYSTEM-context UNC failure pattern post-fix.

6. In the same log view, verify no post-fix line contains `Exit code: 1` for `Map-FinBridgeDrives.ps1`.
Expected result: No repeated script failure for the mapping action.

7. Open Event Viewer using `eventvwr.msc`.
Expected result: Event Viewer console opens.

8. Navigate to `Event Viewer > Windows Logs > System`.
Expected result: System log stream is displayed.

9. Select `Filter Current Log...` and enter `1500,98` in Event IDs.
Expected result: Verification-relevant events only are shown.

10. Verify GroupPolicy Event ID 1500 is present and successful in post-fix sign-in window.
Expected result: GP processing remains healthy.

11. Verify no new Ntfs Event ID 98 exists for missing `S:` after fix time.
Expected result: No fresh S: assignment failures in post-fix window.

12. In Intune portal (`https://endpoint.microsoft.com`), open `Devices > Monitor > Device actions` for at least three sampled Finance endpoints and confirm latest `Sync` completed.
Expected result: Sample endpoints have consumed updated policy.

13. On each sampled endpoint, open `S:` once.
Expected result: Share opens successfully on all sampled devices.

14. Update incident ticket with screenshot/snippet evidence from `IntuneManagementExtension.log` and System Event IDs 1500/98.
Expected result: Closure evidence is complete and auditable.

## 4) Rollback
Target: complete containment + restore previous stable mapping path in under 3 minutes.

1. Open `https://endpoint.microsoft.com` and sign in with Intune admin account. [ELEVATED]
Expected result: Intune portal is available for immediate rollback.

2. Navigate to `Devices > Scripts and remediations > Platform scripts` and open `Map-FinBridgeDrives.ps1`. [ELEVATED]
Expected result: Script object used in incident is open.

3. Open `Assignments` and remove Finance production target group from the updated script assignment. [ELEVATED]
Expected result: Updated script is no longer targeted to Finance production users/devices.

4. In the same `Assignments` page, keep pilot target only.
Expected result: Further blast radius is contained immediately.

5. Navigate to the prior known-good user logon mapping object and open `Assignments`. [ELEVATED]
Expected result: Stable rollback object is ready to reapply.

6. Add Finance production target group to the prior known-good assignment and save. [ELEVATED]
Expected result: Finance scope is returned to last known stable mapping path.

7. On one affected endpoint, open `Settings > Accounts > Access work or school > <connected work account> > Info` and click `Sync`.
Expected result: Endpoint immediately requests rollback policy.

8. Sign out and sign back in on that endpoint.
Expected result: Rolled-back mapping method executes at user sign-in.

9. Open File Explorer and verify `S:` opens `\\finbridge-fs01\Finance`.
Expected result: Service is restored on rollback validation endpoint.

10. Open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` and verify latest mapping run has no `Exit code: 1`.
Expected result: No immediate recurrence of script failure on rollback endpoint.

11. Open `eventvwr.msc > Windows Logs > System` and confirm no new Event ID 98 for missing `S:` after rollback sign-in.
Expected result: Drive assignment failure signal is absent post-rollback.

12. Post a Major Incident update: "Rollback completed, Finance restored on stable mapping path," and continue broad sync per incident command.
Expected result: Stakeholders have confirmed rollback state and next actions.

## 5) Notes
- Warning: Do not declare Group Policy as root cause when Event 1500 is successful; in this incident GP was healthy.
- Edge case: A short startup race can still fail first attempt if retry/backoff is missing, even when network becomes available seconds later.
- Edge case: SYSTEM-context execution can fail UNC access at logon even when user-session access works after sign-in.
- Related incident pattern: Overnight execution-context migrations (USER to SYSTEM) without script redesign can create broad scoped impact.
- Related signals to watch: IME mapping script failure at logon, UNC path inaccessible message, Ntfs Event 98 for S: not assigned.
