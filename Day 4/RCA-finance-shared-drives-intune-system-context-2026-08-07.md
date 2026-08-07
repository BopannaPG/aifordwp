# RCA - Finance Shared Drives Access Failure (Intune Script Context Regression)

## Document Control
- Incident date: 2026-08-07
- RCA created: 2026-08-07
- Affected scope: Finance users (~45 users), DESKTOP-FB* devices, OU=Finance
- Primary symptom: Finance users could not access mapped shared drive (S:) / `\\finbridge-fs01\Finance`
- Resolution status: Resolved
- Resolution verification time: 07:40:05 AM (issue resolved and validated)

## Executive Summary
An overnight change migrated Finance drive mapping from a GPO logon script (USER context) to an Intune PowerShell script executed in SYSTEM context. The script was not redesigned for SYSTEM execution timing and credential semantics. At user sign-in, the script attempted UNC access before dependency readiness and without user-session credentials, then failed on first attempt with no retry. This prevented assignment of S: for affected Finance users. Group Policy processing was healthy and not causal.

## Business Impact
- Impacted users: Approx. 45 Finance users.
- User impact: Inability to access Finance shared drives at start of workday.
- Service impact: Reduced productivity and delayed access to critical Finance file shares.
- Blast radius: OU-scoped / naming-scoped endpoints (DESKTOP-FB*), broad but bounded to Finance estate.

## Technical Scope and Systems
- Endpoint management path: Intune Management Extension (PowerShell script delivery/execution).
- Endpoint OS evidence source: Windows System Log.
- File service target: `\\finbridge-fs01\Finance`.
- Drive letter involved: S:.

## Supporting Evidence

### Intune Management Extension Log (execution path)
- [08:00:01] ScriptRunner Info: Executing `Map-FinBridgeDrives.ps1`
- [08:00:02] ScriptRunner Info: Script context: SYSTEM account
- [08:00:03] ScriptRunner Warning: Network path `\\finbridge-fs01\Finance` not accessible from SYSTEM context at execution time
- [08:00:03] ScriptRunner Error: Script failed, Exit code 1, Error: Network name cannot be found
- [08:00:04] ScriptRunner Info: No retry configured

### System Log - DESKTOP-FB041 (dependency and outcome signals)
- 08:00:05 Service Control Manager Event 7036: Workstation service entered running state
- 08:00:06 GroupPolicy Event 1500: Group Policy processed successfully (rules out GP processing failure)
- 08:00:07 Ntfs Event 98 Warning: Could not map drive letter S: / drive letter not assigned

### Change Record Evidence (causal change)
- 2024-03-14 23:30 migration note:
  - Mapping moved from GPO logon script (USER) to Intune PowerShell script (SYSTEM)
  - Script not updated for SYSTEM context behavior
  - UNC access dependency on Workstation readiness and user-mapped credentials not available to SYSTEM at login time
  - Source reference: DESKTOP-FB022

## Incident Timeline (Evidence-Based)
- 2024-03-14 23:30 - Change implemented: mapping migration USER -> SYSTEM execution model.
- 07:40:05 - Suggested resolution applied and service restored (confirmed).
- 08:00:01 - Intune script execution starts.
- 08:00:02 - Script confirmed running as SYSTEM account.
- 08:00:03 - UNC path inaccessible in SYSTEM context; script fails with network name cannot be found.
- 08:00:04 - No retry path invoked/configured.
- 08:00:05 - Workstation service reaches running state (after script failure point).
- 08:00:06 - Group Policy processing successful (non-causal).
- 08:00:07 - NTFS reports S: not assigned.

## Root Cause Statement
The primary root cause was an execution-context design regression introduced by change: a user-session drive mapping workflow was moved to SYSTEM-context Intune execution without adapting script logic for SYSTEM identity, user credential/session availability, and startup dependency timing. A contributing design gap (no retry/backoff) converted early failure into persistent user-visible impact.

## Contributing Factors
- Script identity mismatch (SYSTEM vs USER-session semantics).
- Early execution relative to network/provider readiness window.
- No retry/backoff or delayed second attempt.
- Broad scope targeting (Finance OU/endpoints), increasing blast radius.

## What Was Ruled Out
- Group Policy processing failure ruled out by GroupPolicy Event 1500 at 08:00:06.
- No evidence in provided logs of GP engine failure during incident window.

## 5 Whys Analysis
1. Why could Finance users not access shared drives?
- Because mapped drive S: was not assigned on affected endpoints.
- Evidence: Ntfs Event 98 at 08:00:07.

2. Why was S: not assigned?
- Because `Map-FinBridgeDrives.ps1` failed during login-time execution.
- Evidence: ScriptRunner failure at 08:00:03, exit code 1.

3. Why did the mapping script fail?
- Because UNC path `\\finbridge-fs01\Finance` was not accessible in SYSTEM context at execution time.
- Evidence: ScriptRunner warning/error at 08:00:03.

4. Why was it running in SYSTEM context with inaccessible UNC/session prerequisites?
- Because the mapping was migrated from USER logon script to Intune SYSTEM script without redesign for identity/session/timing constraints.
- Evidence: change note from 2024-03-14 23:30.

5. Why did this design issue become a broad user outage?
- Because there was no retry/delay safety net and change controls did not catch context incompatibility before broad rollout.
- Evidence: ScriptRunner no retry configured at 08:00:04; broad scope impact to Finance devices.

## Corrective Actions Implemented (Incident Recovery)
- Applied suggested resolution and restored service by 07:40:05 AM.
- Verified Group Policy processing healthy post-fix (no GP issues reported).
- Confirmed user-impact symptom cleared (Finance shared drive access restored).

## Preventive Actions (CAPA)

### Immediate (0-7 days)
- Revert mapping execution to USER-context method for Finance endpoints, or execute mapping in user session (not SYSTEM-only).
- Add retry/backoff and delayed execution guard for any network-dependent startup script.
- Add pre-check: verify Workstation service/network readiness and UNC reachability before mapping call.
- Add explicit failure telemetry and alerting for script exit code != 0.

### Near Term (1-4 weeks)
- Introduce change gate requiring context-compatibility review when moving scripts between USER and SYSTEM contexts.
- Pilot changes on a small Finance subset before broad OU deployment.
- Add automated validation test: SYSTEM vs USER UNC access behavior on representative endpoint images.
- Standardize script patterns for idempotent drive mapping with safe retries and structured logging.

### Long Term (1-2 quarters)
- Move drive mapping to a supported user-context modern management pattern (for example, user-targeted policy/mechanism) with formal design standards.
- Implement deployment ring strategy for endpoint management changes (canary -> pilot -> broad).
- Establish operational SLO and alert thresholds for login-time script failure rates.

## Verification and Closure Criteria
- No new drive-mapping incidents reported by Finance users after 07:40:05.
- Endpoint telemetry shows successful mapping completion across DESKTOP-FB* sample set.
- No recurring ScriptRunner errors for `Map-FinBridgeDrives.ps1` in post-fix window.
- Group Policy health remains green (Event 1500 success during logon cycles).

## Residual Risk
- Medium until preventive engineering controls (context gate + pilot rings + retry standards) are fully implemented.
- Low once user-context-safe architecture and deployment safeguards are institutionalized.

## Lessons Learned
- Script context changes are architectural changes, not only deployment changes.
- Startup timing dependencies must be treated as first-class reliability risks.
- No-retry designs are unsafe for boot/logon network-dependent workflows.
