# End-User Communication - Three Audiences (Finance Shared Drives Incident)

## Shared Fact Set (used unchanged across all three versions)
- Scope: Finance shared drive access issue affected Finance users on DESKTOP-FB* devices (OU=Finance).
- Triggering change: Overnight migration moved drive mapping from a user logon method to an Intune script running as SYSTEM.
- Failure mode: At logon, the script ran in SYSTEM context, could not access `\\finbridge-fs01\Finance`, failed with "network name cannot be found," and had no retry.
- Supporting system signals: Workstation service reached running state after script failure; Group Policy processed successfully (not a GP issue); drive S: was not assigned.
- Resolution: Suggested fix was applied; issue resolved at 07:40:05 AM; Group Policy verified healthy; no ongoing issue reported.

## Audience 1 - Non-Technical Executive (under 80 words)
Your access and data are safe, and this issue has been resolved. This morning, some Finance users could not open the shared Finance drive because an overnight setup change caused the drive to connect too early and fail once without retry. We confirmed this was not a Group Policy problem. The fix was applied, service was restored at 07:40:05 AM, and checks are healthy. You do not need to take any action.

## Audience 2 - Affected End-User Team (10 users, non-technical, under 100 words)
Hi team, your access and data are safe, and the shared drive issue is fixed. What happened: an overnight setup change made the Finance drive connection run at sign-in in a way that failed once too early, so S: did not appear for affected Finance devices. We verified this was not a Group Policy problem, applied the fix, and restored service at 07:40:05 AM; health checks are good now. If you see the same issue again, sign out and sign back in once, then contact the Service Desk and mention the Finance shared drive incident.

## Audience 3 - Engineer-to-Engineer Internal Note
Incident: Finance shared drive access failure (DESKTOP-FB* / OU=Finance), broad Finance impact.

Root cause:
- Execution-context regression introduced by overnight change: mapping moved from user logon method to Intune PowerShell in SYSTEM context without redesign for SYSTEM identity/session behavior and startup timing.

Observed failure path:
- IME ScriptRunner 08:00:01 started `Map-FinBridgeDrives.ps1`.
- 08:00:02 script context confirmed SYSTEM.
- 08:00:03 UNC `\\finbridge-fs01\Finance` inaccessible from SYSTEM context; script exit code 1, "network name cannot be found."
- 08:00:04 no retry configured.
- System log DESKTOP-FB041: 08:00:05 SCM Event 7036 Workstation service running (after script failure); 08:00:06 GroupPolicy Event 1500 success (not GP); 08:00:07 Ntfs Event 98 S: not assigned.

Exact action taken:
- Applied the suggested resolution to restore drive mapping behavior for affected Finance scope.

Config/detail note:
- Prior change record (2024-03-14 23:30) documents migration from USER-context GPO logon mapping to SYSTEM-context Intune script, with script not updated for SYSTEM constraints and no retry logic.

Verification:
- Recovery confirmed at 07:40:05 AM.
- Group Policy re-verified healthy.
- No ongoing issue reported after fix.

Preventive action required:
- Keep mapping in user-session-safe execution path (or equivalent user-context mechanism) for Finance drive mapping.
- Add startup dependency checks plus retry/backoff for network-dependent mappings.
- Enforce change gate for USER->SYSTEM script context moves and pilot before broad OU rollout.
