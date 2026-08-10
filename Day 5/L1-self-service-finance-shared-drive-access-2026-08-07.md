# KB - L2/L3: Finance Shared Drive Mapping Failure (Intune SYSTEM Context Regression)
Version: v 1.0
Date: 07/08/2026
Status : Draft

## Background: what the system does and why it matters
Finance users depend on mapped drive S: to access \\finbridge-fs01\Finance at sign-in. This mapping was historically delivered in user logon context. During the incident, the mapping moved to an Intune-delivered PowerShell script (`Map-FinBridgeDrives.ps1`) executed by Intune Management Extension (IME).

Why it matters:
- If S: is not assigned at sign-in, Finance users lose access to critical operational files.
- A USER to SYSTEM context change can break UNC access behavior even when file services are healthy.
- A no-retry startup script can convert a short timing issue into broad user impact.

## Symptom: what the engineer observes and what the user reports
Engineer observes:
- IME script run for `Map-FinBridgeDrives.ps1` in SYSTEM context.
- UNC access failure to `\\finbridge-fs01\Finance` during startup window.
- Script exits with code 1 and no retry.
- System log shows successful Group Policy processing but S: remains unassigned.

User reports:
- "S: Finance drive is missing"
- "S: opens but contents do not load"
- "Cannot open \\finbridge-fs01\Finance"
- Often starts right after sign-in.

## Root cause: the specific technical cause with the evidence that confirms it
Specific technical cause:
- Drive mapping was migrated from a USER-context logon method to Intune SYSTEM-context execution.
- Script logic was not adapted for SYSTEM identity/session timing.
- Mapping attempt ran before dependency readiness, failed once, and did not retry.

Evidence that confirms it:
- IME log shows `Script context: SYSTEM account` for `Map-FinBridgeDrives.ps1`.
- IME log shows UNC inaccessible for `\\finbridge-fs01\Finance` and `Exit code: 1`.
- IME log shows `No retry configured` after failure.
- System Event ID 7036 (Service Control Manager) indicates Workstation service entered running state after script failure timestamp.
- System Event ID 1500 (GroupPolicy) is successful, ruling out GP failure as root cause.
- System Event ID 98 (Ntfs) shows S: drive letter not assigned.

## Detection: exactly how to confirm this is the issue before acting
Goal: confirm in under 3 minutes whether this is the AVD graphics regression signature.

1. Check impacted host pool first (POOL-FIN-01) from Application log
- Exact log location: `Event Viewer > Windows Logs > Application`
- Required Event IDs: `1000` and `9009`
- Required Event 1000 signature:
  - `Faulting application name: dwm.exe`
  - `Faulting module name: igdumd64.dll`
- Fields to read in each event:
  - `TimeCreated`
  - `Event ID`
  - `Source` (ProviderName)
  - `Level`
  - `Faulting application name` (Event 1000)
  - `Faulting module name` (Event 1000)
  - `Message`
- Confirm condition on POOL-FIN-01 host:
  - Event 1000 for `dwm.exe` faulting in `igdumd64.dll`, plus Event 9009 in same incident window.

2. Compare with unaffected control pool baseline (POOL-FIN-02)
- Exact log location on control host: `Event Viewer > Windows Logs > Application`
- Required healthy baseline event: `Event ID 9011` (Desktop Window Manager start/healthy path)
- Fields to read:
  - `TimeCreated`
  - `Event ID`
  - `Source` (ProviderName)
  - `Level`
  - `Message`
- Healthy control expectation on POOL-FIN-02:
  - Event 9011 present, with no matching Event 1000 (`dwm.exe` + `igdumd64.dll`) in same window.

3. Fast extraction with PowerShell (local or remote session host)
- Run on a session host in POOL-FIN-01:
```powershell
$start = (Get-Date).AddHours(-2)

Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$start } |
Where-Object { $_.Message -match 'dwm\.exe' -and $_.Message -match 'igdumd64\.dll' } |
Select-Object TimeCreated, MachineName, Id, ProviderName, LevelDisplayName, Message

Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9009; StartTime=$start } |
Select-Object TimeCreated, MachineName, Id, ProviderName, LevelDisplayName, Message
```
- Run on a session host in POOL-FIN-02 (healthy baseline check):
```powershell
$start = (Get-Date).AddHours(-2)

Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9011; StartTime=$start } |
Select-Object TimeCreated, MachineName, Id, ProviderName, LevelDisplayName, Message

Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$start } |
Where-Object { $_.Message -match 'dwm\.exe' -and $_.Message -match 'igdumd64\.dll' } |
Select-Object TimeCreated, MachineName, Id, ProviderName, LevelDisplayName, Message
```

4. Fast pool comparison with Azure CLI
- Use these commands to quickly identify candidate hosts in both pools for event checks:
```bash
az desktopvirtualization hostpool session-host list --resource-group <RG_FIN_01> --host-pool-name POOL-FIN-01 --query "[].{SessionHost:name,Status:status,AllowNewSession:allowNewSession}" -o table
az desktopvirtualization hostpool session-host list --resource-group <RG_FIN_02> --host-pool-name POOL-FIN-02 --query "[].{SessionHost:name,Status:status,AllowNewSession:allowNewSession}" -o table
```

5. Decision rule (act only if true)
- Confirmed incident signature:
  - POOL-FIN-01 host(s): Event 1000 (`dwm.exe` + `igdumd64.dll`) and Event 9009 present in same window.
  - POOL-FIN-02 control host(s): Event 9011 present as healthy baseline and no matching Event 1000 signature.
- If this differential is present, proceed with resolution.

## Resolution: step-by-step fix with expected result after each step
1. Contain affected hosts in POOL-FIN-01 immediately
- Exact Azure portal path: `portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`
- Option to set: `Allow new sessions = No` on impacted hosts.
- Expected result: New user sessions stop landing on failing hosts.
- Fast command:
```bash
az desktopvirtualization hostpool session-host list --resource-group <RG_FIN_01> --host-pool-name POOL-FIN-01 --query "[].{Host:name,Status:status,AllowNewSession:allowNewSession}" -o table
az desktopvirtualization hostpool session-host update --resource-group <RG_FIN_01> --host-pool-name POOL-FIN-01 --name <session_host_name> --allow-new-session false
```

2. Ensure healthy intake path on POOL-FIN-02 (control pool)
- Exact Azure portal path: `portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`
- Option to confirm/set: `Allow new sessions = Yes` on healthy hosts.
- Expected result: New connections are redirected to unaffected capacity.
- Fast command:
```bash
az desktopvirtualization hostpool session-host list --resource-group <RG_FIN_02> --host-pool-name POOL-FIN-02 --query "[].{Host:name,Status:status,AllowNewSession:allowNewSession}" -o table
az desktopvirtualization hostpool session-host update --resource-group <RG_FIN_02> --host-pool-name POOL-FIN-02 --name <session_host_name> --allow-new-session true
```

3. Confirm image baseline and identify known-good version for FIN01
- Exact Azure portal path: `portal.azure.com > Azure Compute Gallery > <GalleryName> > Images > <POOL-FIN-01-image-definition> > Versions`
- Option to use: select version prior to the `2024-03-15 02:00` rollout and set as current in your image pipeline.
- Expected result: Known-good image is selected as rollout source.
- Fast command (if gallery image versions are used):
```bash
az sig image-version list --resource-group <RG_IMAGE> --gallery-name <GALLERY_NAME> --gallery-image-definition <FIN01_IMAGE_DEF> --query "[].{Version:name,Published:publishingProfile.publishedDate}" -o table
```

4. Redeploy or replace FIN01 session hosts from corrected image
- Exact Azure portal path (VMSS-backed hosts): `portal.azure.com > Virtual machine scale sets > <FIN01_VMSS> > Instances`
- Option to use: `Reimage` instances or roll instances after image update.
- Expected result: Replaced hosts register healthy in `POOL-FIN-01 > Session hosts`.
- Fast commands (VMSS path):
```bash
az vmss list-instances --resource-group <RG_FIN_01> --name <FIN01_VMSS> --query "[].{Id:instanceId,Provisioning:provisioningState}" -o table
az vmss reimage --resource-group <RG_FIN_01> --name <FIN01_VMSS> --instance-ids <INSTANCE_ID>
```

5. Open remediated hosts for controlled intake
- Exact Azure portal path: `portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`
- Option to set: `Allow new sessions = Yes` only on remediated hosts.
- Expected result: FIN01 resumes service without reintroducing failures.
- Fast command:
```bash
az desktopvirtualization hostpool session-host update --resource-group <RG_FIN_01> --host-pool-name POOL-FIN-01 --name <remediated_session_host_name> --allow-new-session true
```

## Verification: how to confirm the fix worked
1. Verify host-pool health and intake settings
- Exact Azure portal path: `portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`
- Options to verify per host: `Status = Available`, `Allow new sessions = Yes`, stable session count.
- Expected result: Remediated FIN01 hosts are healthy and accepting sessions normally.
- Fast command:
```bash
az desktopvirtualization hostpool session-host list --resource-group <RG_FIN_01> --host-pool-name POOL-FIN-01 --query "[].{Host:name,Status:status,AllowNewSession:allowNewSession,Sessions:session}" -o table
```

2. Verify event signatures are cleared on remediated FIN01 host
- Exact log locations:
  - `Event Viewer > Windows Logs > Application` (Event ID `1000`, check for `dwm.exe` + `igdumd64.dll`)
  - `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational` (Event ID `9009`)
- Expected result: No new Event 1000 crash signature and no repeated Event 9009 after fix.
- Fast commands:
```powershell
$start = (Get-Date).AddHours(-1)
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$start } | Where-Object { $_.Message -match 'dwm\.exe' -and $_.Message -match 'igdumd64\.dll' } | Select-Object TimeCreated, Id, ProviderName, Message
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$start } | Select-Object TimeCreated, Id, ProviderName, Message
```

3. Verify healthy control baseline remains normal in POOL-FIN-02
- Exact log location on control host: `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational`
- Option to verify: Event ID `9011` present in same verification window.
- Expected result: POOL-FIN-02 remains healthy and unchanged.
- Fast command:
```powershell
$start = (Get-Date).AddHours(-1)
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9011; StartTime=$start } | Select-Object TimeCreated, Id, ProviderName, Message
```

4. Verify user experience gate
- Path: `AVD client > Workspace > Finance desktop/app in POOL-FIN-01`
- Action: Perform 3 consecutive sign-ins.
- Expected result: No black screen and no immediate disconnect loop.

## Rollback: what to do if the fix makes things worse
Rollback triggers:
- New Event 1000 (`dwm.exe` + `igdumd64.dll`) reappears on remediated FIN01 hosts.
- Event 9009 resumes in post-login loops.
- Users continue black-screen behavior after remediation.

1. Re-drain FIN01 immediately
- Exact Azure portal path: `portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`
- Option to set: `Allow new sessions = No` on all impacted FIN01 hosts.
- Expected result: New sessions are prevented from landing on unstable hosts.
- Fast command:
```bash
az desktopvirtualization hostpool session-host list --resource-group <RG_FIN_01> --host-pool-name POOL-FIN-01 --query "[].name" -o tsv
# Run one update per returned host:
az desktopvirtualization hostpool session-host update --resource-group <RG_FIN_01> --host-pool-name POOL-FIN-01 --name <session_host_name> --allow-new-session false
```

2. Keep POOL-FIN-02 as active intake pool
- Exact Azure portal path: `portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts`
- Option to set: `Allow new sessions = Yes` on healthy capacity hosts.
- Expected result: User sign-ins continue via unaffected pool.
- Fast command:
```bash
az desktopvirtualization hostpool session-host update --resource-group <RG_FIN_02> --host-pool-name POOL-FIN-02 --name <session_host_name> --allow-new-session true
```

3. Roll image for FIN01 back to known-good version
- Exact Azure portal path: `portal.azure.com > Azure Compute Gallery > <GalleryName> > Images > <POOL-FIN-01-image-definition> > Versions`
- Option to use: choose pre-incident version and `Set as current` or `Promote` in image pipeline.
- Expected result: Known-good image becomes source for redeployment.
- Fast command:
```bash
az sig image-version list --resource-group <RG_IMAGE> --gallery-name <GALLERY_NAME> --gallery-image-definition <FIN01_IMAGE_DEF> --query "[].{Version:name,Published:publishingProfile.publishedDate}" -o table
```

4. Reimage or replace FIN01 hosts from known-good image
- Exact Azure portal path (VMSS-backed hosts): `portal.azure.com > Virtual machine scale sets > <FIN01_VMSS> > Instances`
- Option to use: `Reimage` selected instances.
- Expected result: Replaced hosts return without the failing graphics state.
- Fast command:
```bash
az vmss reimage --resource-group <RG_FIN_01> --name <FIN01_VMSS> --instance-ids <INSTANCE_ID>
```

5. Rollback verification gate before reopening FIN01
- Exact log/portal checks:
  - `Event Viewer > Windows Logs > Application` Event ID `1000` (no `dwm.exe` + `igdumd64.dll`)
  - `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational` Event ID `9009` (no repeat)
  - `portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts` (`Status = Available`)
- Expected result: Clean telemetry and healthy host state before enabling intake.

6. Re-enable FIN01 intake host-by-host
- Exact Azure portal path: `portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`
- Option to set: `Allow new sessions = Yes` one host at a time after clean checks.
- Expected result: Controlled return to service with minimal re-risk.
- Fast command:
```bash
az desktopvirtualization hostpool session-host update --resource-group <RG_FIN_01> --host-pool-name POOL-FIN-01 --name <clean_session_host_name> --allow-new-session true
```

## Preventive: the specific change to process or tooling that stops this recurring
1. Mandatory change-gate for USER/SYSTEM context migration
- Owner: change manager. Timing: before deployment. Mode: manual with workflow enforcement [REQUIRES: CAB template policy].
- Pass: CAB contains `Execution context changed (USER<->SYSTEM): Yes/No`, compatibility checklist, and rollback ID; Fail: any field missing.
- If fail: change status set to `On Hold` and deployment cannot start; automation approach: mandatory field validation in change workflow.

2. Script quality gate in CI
- Owner: release engineer. Timing: before deployment. Mode: automated [REQUIRES: CI lint job for script controls].
- Pass: CI detects reachability pre-check, retry/backoff, and structured exit-code logging, and pipeline exits `0`; Fail: any control missing or lint exit non-zero.
- If fail: pull request merge blocked; automation approach: branch protection requires successful quality-gate job.

3. Ringed rollout enforcement for Intune script assignments
- Owner: release engineer. Timing: during deployment. Mode: automated gate with manual override [REQUIRES: staged deployment pipeline].
- Pass: progression follows `Pilot -> Ring1 -> Full` only when Event ID 98 count = 0 and mapping script failure count = 0 for each ring window; Fail: threshold breach.
- If fail: halt rollout at current ring and keep expansion blocked until corrective action and re-validation complete.

4. Detection automation and alerting
- Owner: DWP engineer. Timing: during deployment and first 24 hours after deployment. Mode: automated [REQUIRES: scheduled query + ticket integration].
- Pass: Event ID 98 = 0 in sign-in window and IME mapping failures <= 2 endpoints; Fail: Event ID 98 > 0 or IME failures > 2 endpoints.
- If fail: auto-create incident ticket with impacted host list and notify on-call queue.

5. Incident form hardening
- Owner: service desk lead. Timing: after deployment (before incident/change closure). Mode: manual with workflow enforcement [REQUIRES: ticket form validation rules].
- Pass: closure record contains affected-vs-control evidence, log extracts, and command output links; Fail: any mandatory evidence field empty.
- If fail: closure blocked and returned to assignee for completion.

6. Pre-deployment test gate (smoke test before release)
- Owner: image owner. Timing: before deployment. Mode: automated with manual sign-off [REQUIRES: pre-release smoke runner].
- Pass: smoke test on canary host returns Event 1000 (`dwm.exe` + `igdumd64.dll`) count = 0, Event 9009 count = 0, and Event 9011 present on control baseline; Fail: any mismatch.
- If fail: image release blocked and marked `Rejected` until defect fix and rerun pass.

7. In-flight monitoring (alert during rollout window)
- Owner: DWP engineer. Timing: during deployment. Mode: automated [REQUIRES: Log Analytics AVD workbook + alert rule].
- Pass: POOL-FIN-01 keeps Event 1000 signature count = 0 and Event 9009 rate <= 1 per host per hour, with no abnormal delta vs POOL-FIN-02; Fail: threshold exceeded.
- If fail: trigger containment runbook to set `Allow new sessions = No` on affected FIN01 hosts and page release engineer.

8. Post-deployment validation (healthy state before closure)
- Owner: release engineer. Timing: after deployment. Mode: manual checklist (can be automated) [REQUIRES: post-deploy validation task].
- Pass: 3 consecutive user sign-ins on FIN01 succeed, Event 1000 signature count = 0, Event 9009 count = 0, and Event 9011 baseline healthy on FIN02; Fail: any check fails.
- If fail: keep change `Open`, do not close CAB record, and move to rollback decision.

9. Rollback trigger threshold
- Owner: change manager. Timing: during and after deployment. Mode: automated trigger with manual confirmation [REQUIRES: rollback orchestration rule].
- Pass: no rollback trigger hit; Fail trigger: >= 2 hosts in FIN01 show Event 1000 (`dwm.exe` + `igdumd64.dll`) within 15 minutes or repeated 21->40 loops on affected hosts.
- If fail: auto-open rollback task, drain FIN01 hosts, and execute known-good image rollback.

10. Knowledge update from incident learnings
- Owner: service desk lead. Timing: after deployment and incident closure. Mode: manual with workflow gate [REQUIRES: knowledge-review step in closure workflow].
- Pass: runbook, detection checklist, and KB are version-bumped with new thresholds/commands and peer-reviewed within 2 business days; Fail: documents unchanged or unreviewed.
- If fail: incident cannot be marked `Lessons Learned Complete` and is escalated to change manager.

## Related: other incidents or KB articles this connects to
- `runbook-finance-shared-drive-mapping-intune-system-context-2026-08-07.md`
- `RCA-finance-shared-drives-intune-system-context-2026-08-07.md`
- `known-error-finance-shared-drives-intune-system-context-2026-08-07.md`
- `closure-note-finance-shared-drives-intune-system-context-2026-08-07.md`
- Pattern relation: incidents caused by execution context migration without script redesign.