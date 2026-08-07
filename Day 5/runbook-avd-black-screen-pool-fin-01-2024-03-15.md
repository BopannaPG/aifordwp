# Runbook: AVD Black Screen After Login on POOL-FIN-01

## Runbook Version Header

- Title: AVD Black Screen After Login on POOL-FIN-01
- Version: 1.0
- Date: 07/08/2026
- Author: Sathishbabu
- Reviewed: self
- Status: draft
- Change: initial version from RCA

## 1) Prerequisites

Complete this pre-flight checklist before starting investigation.

1. [ ] Confirm Azure portal access to `Azure Virtual Desktop > Host pools > POOL-FIN-01` and `POOL-FIN-02`. [Elevated permission required]
2. [ ] Confirm permission to change session host `Allow new sessions` state in both pools. [Elevated permission required]
3. [ ] Confirm permission to deploy or roll back the POOL-FIN-01 golden image through your image pipeline. [Elevated permission required]
4. [ ] Confirm local administrator access (or equivalent) to open Event Viewer on one affected POOL-FIN-01 host and one unaffected POOL-FIN-02 host. [Elevated permission required]
5. [ ] Confirm RDP or remote management access to those two session hosts. [Elevated permission required]
6. [ ] Confirm known-good image reference ID or version used before the 02:00 update.
7. [ ] Confirm affected host name in POOL-FIN-01 and comparison host name in POOL-FIN-02.
8. [ ] Confirm mandatory end-user intake details are captured:
	- impacted user UPN and display name
	- symptom wording (black screen after login)
	- first seen time and timezone
	- pool name and host name if shown in AVD client
	- screenshot or exact error text if visible
	- whether reconnect was attempted and result
9. [ ] Confirm incident time window to filter logs: start around `07:00` on `2024-03-15`.
10. [ ] Confirm tools are ready: Azure portal, Event Viewer, and AVD client test account.

## 2) Procedure

Follow these steps in order. Each step has one action and one expected result.

1. Action: In Azure portal, open `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`, then identify one host with reported black-screen behavior.
Expected result: One affected POOL-FIN-01 session host is selected for evidence collection.

2. Action: In Azure portal, open `Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`, then identify one healthy comparison host.
Expected result: One unaffected POOL-FIN-02 session host is selected for comparison.

3. Action: Connect to the affected POOL-FIN-01 host and open `Event Viewer > Windows Logs > Application`, then run `Filter Current Log...` for `Event ID: 1000`.
Expected result: Application Error entries are visible for the incident window.

4. Action: In the filtered Application results, find entries where `Faulting application name` is `dwm.exe` and `Faulting module name` is `igdumd64.dll`.
Expected result: Matching crash signature is confirmed on the affected host.

5. Action: On the affected host, open `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational`, then filter for `Event ID: 9009`.
Expected result: DWM exit events are visible near user logon times.

6. Action: On the affected host, open `Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`, then filter for `Event IDs: 21, 40`.
Expected result: Successful session logon events followed by disconnect events are visible in sequence.

7. Action: On the POOL-FIN-02 comparison host, open `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational`, then filter for `Event ID: 9011`.
Expected result: DWM start success events are present on the unaffected host.

8. Action: On the POOL-FIN-02 comparison host, open `Event Viewer > Windows Logs > Application`, then filter for `Event ID: 1000` during the same window.
Expected result: No matching `dwm.exe` and `igdumd64.dll` crash signature is found.

9. Action: In Azure portal at `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`, set `Allow new sessions` to `No` on affected hosts. [Elevated permission required]
Expected result: New sessions stop landing on impacted hosts.

10. Action: In Azure portal at `Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`, confirm sufficient hosts are set to `Allow new sessions = Yes`. [Elevated permission required]
Expected result: New user sessions can continue on unaffected capacity.

11. Action: In your image management pipeline, roll back or correct the POOL-FIN-01 image by replacing the failing graphics component state. [Elevated permission required]
Expected result: A corrected image version is published and available for deployment.

12. Action: Redeploy affected POOL-FIN-01 session hosts from the corrected image version. [Elevated permission required]
Expected result: Replacement hosts register and show as available in `POOL-FIN-01 > Session hosts`.

13. Action: Perform one controlled sign-in to a remediated POOL-FIN-01 host using a test or affected user account.
Expected result: Desktop opens without persistent black screen and without immediate disconnect.

14. Action: Recheck `Application` (Event ID `1000`) and `Desktop Window Manager/Operational` (Event ID `9009`) on the remediated host for the test period.
Expected result: No recurring `dwm.exe` / `igdumd64.dll` crash pattern appears.

15. Action: In Azure portal at `POOL-FIN-01 > Session hosts`, set remediated hosts to `Allow new sessions = Yes`. [Elevated permission required]
Expected result: POOL-FIN-01 is safely returned to normal intake.

## 3) Verification

Confirm all checks below before closure.

1. Action: In Azure portal, go to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`, then confirm remediated hosts show `Status = Available`, `Allow new sessions = Yes`, and no abnormal session churn.
Expected result: Remediated POOL-FIN-01 hosts are healthy and actively accepting sessions.

2. Action: RDP to one remediated POOL-FIN-01 host, open `Event Viewer > Windows Logs > Application`, click `Filter Current Log...`, set `Event IDs` to `1000`, set `Logged` to the last 1 hour, and inspect entries for `Faulting application name: dwm.exe` and `Faulting module name: igdumd64.dll`.
Expected result: No new Event 1000 entries with `dwm.exe` + `igdumd64.dll` in the verification window.

3. Action: On the same remediated host, open `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational`, click `Filter Current Log...`, set `Event IDs` to `9009`, set `Logged` to the last 1 hour, and review events after test sign-ins.
Expected result: No recurring DWM exit Event 9009 after successful logon.

4. Action: On the same remediated host, open `Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`, click `Filter Current Log...`, set `Event IDs` to `21,40`, then verify sequence after each test sign-in.
Expected result: Event 21 (session logon) occurs without immediate Event 40 disconnect loop.

5. Action: Perform 3 consecutive test logins using AVD client to POOL-FIN-01 (disconnect and reconnect between attempts), then confirm desktop loads each time within normal time and remains usable.
Expected result: No black screen, no forced reconnect, and no immediate disconnect on all 3 attempts.

6. Action: In Azure portal, go to `Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`, pick one healthy comparison host, then check `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational` for `Event ID 9011` in same time window.
Expected result: POOL-FIN-02 continues normal DWM start behavior, confirming baseline remains healthy.

7. Action: Record evidence in incident notes: portal screenshot of POOL-FIN-01 host health, and screenshots/exported views for Event 1000, 9009, and 21/40 checks.
Expected result: Closure package contains reproducible proof of fix and can pass audit review.

## 4) Rollback

If symptoms worsen after correction or redeployment, execute rollback immediately.

Use this 3-minute containment sequence exactly in order.

1. Action (00:00-00:45): In Azure portal, go to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`, multi-select all active impacted hosts, click `Allow new sessions`, set to `No`, and confirm the update toast.
Expected result: New user connections stop landing on POOL-FIN-01 immediately.

2. Action (00:45-01:30): In Azure portal, go to `Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`, verify enough hosts show `Status = Available` and `Allow new sessions = Yes`; if any are `No`, select them and set `Allow new sessions = Yes`.
Expected result: New sessions are redirected to healthy POOL-FIN-02 capacity.

3. Action (01:30-02:00): In Azure portal, go to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`, open one affected host, check `Sessions` count, and send active users the approved comms before forced sign-out if required by policy.
Expected result: User impact is controlled and communication is completed before deeper rollback tasks.

4. Action (02:00-02:30): In image pipeline console, select POOL-FIN-01 image definition, choose `Versions`, pick the last known-good version from before `2024-03-15 02:00`, and click `Promote` or `Set as current`.
Expected result: Known-good image is restored as deployment baseline.

5. Action (02:30-03:00): Trigger host redeployment for POOL-FIN-01 from the restored image baseline (pipeline job, ARM/Bicep, or autoscale replacement path used by your team).
Expected result: Replacement workflow starts and failing graphics state is being removed from service.

6. Action (post-containment validation): On one rolled-back host, open `Event Viewer > Windows Logs > Application` and filter `Event ID 1000`; then open `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational` and filter `Event ID 9009` for the latest sign-in test window.
Expected result: No new `dwm.exe` + `igdumd64.dll` Event 1000 and no repeating Event 9009 before returning POOL-FIN-01 to intake.

7. Action (return-to-service gate): Keep `Allow new sessions = No` on POOL-FIN-01 until one successful test sign-in and clean log checks are confirmed, then re-enable intake host by host.
Expected result: Rollback is controlled, measurable, and safe for production users.

## 5) Notes

1. Edge case: If a user can log on but sees an intermittent black screen that clears after about 30 seconds, treat it as the same incident class and continue with the same evidence checks.
2. Warning: Do not close based only on one successful login; confirm absence of repeat Event 1000 and Event 9009 patterns first.
3. Related incident pattern: A different incident class can present as authentication failure (for example Security Events 4625 or 4740); do not mix that workflow with this graphics crash workflow.
4. Incident signature from this case: Affected pool POOL-FIN-01 after a 02:00 image update, impact beginning around 07:00, with POOL-FIN-02 unaffected.