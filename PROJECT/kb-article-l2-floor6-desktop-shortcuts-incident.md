# L2 KB: Floor 6 Desktop Shortcuts Hidden After Policy Assignment

Version: v 1.0  
Date: 14/08/2026  
Status: Draft

## Background

DWP endpoints receive desktop behavior settings from Microsoft Intune configuration profiles. One profile can hide all desktop icons for users in assigned groups. This matters because Floor 6 Legal relies on desktop shortcuts for case tools and matter folders. If the wrong group is assigned, many users lose visible shortcuts at once and productivity drops immediately.

## Symptom

What users report:
- "My desktop shortcuts disappeared after update/restart."
- Multiple Floor 6 Legal users report the same issue within the same time window.

What engineer observes:
- Shortcut files still exist in `C:\Users\<user>\Desktop`.
- Desktop display is blank or missing expected icons.
- `gpresult` shows a hide-desktop policy as Applied.

## Root Cause

A desktop-hide Intune configuration profile was assigned to `Floor 6 Legal` instead of intended target group.

Evidence that confirms root cause:
- Intune assignment includes `Floor 6 Legal`.
- `gpresult` on affected endpoint shows hide-desktop setting as Applied.
- Group Policy events show successful policy processing after assignment window.

## Detection

Run this exact sequence. Target completion: under 3 minutes.

### 1) Fast event pull by command (primary method)

Run from PowerShell on admin workstation (replace `<AFFECTED_HOST>`):

```powershell
$affected = "<AFFECTED_HOST>"
$control = "POOL-FIN-02"

# Application log, required events on affected host
Get-WinEvent -ComputerName $affected -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddHours(-24)} |
  Sort-Object TimeCreated -Descending |
  Select-Object -First 20 TimeCreated, Id, ProviderName, MachineName, Message | Format-List

# Healthy baseline check on control host
Get-WinEvent -ComputerName $control -FilterHashtable @{LogName='Application'; Id=9011; StartTime=(Get-Date).AddHours(-24)} |
  Sort-Object TimeCreated -Descending |
  Select-Object -First 5 TimeCreated, Id, ProviderName, MachineName, Message | Format-List
```

### 2) Exact log location and required IDs

- Log location (must use): `Event Viewer (Local) > Windows Logs > Application`
- Required IDs to find on affected host:
  - `Event ID 1000`
  - `Event ID 9009`
- Healthy comparison on control host:
  - `Event ID 9011` on `POOL-FIN-02`

### 3) Exact field checks in Event 1000

Open Event ID 1000 and confirm these fields:
- `Faulting module name` = `igdumd64.dll` (required)
- `Faulting application name` = target app/session process tied to user report
- `TimeCreated` aligns with incident window

If `Faulting module name` is not `igdumd64.dll`, treat as different issue path.

### 4) Event 9009 confirmation (same window)

In the same `Application` log and time window, confirm Event ID 9009 exists on affected host.

Required checks:
- `Id` = `9009`
- `MachineName` = affected host
- `TimeCreated` close to Event 1000 occurrence

### 5) Healthy baseline comparison (required)

Use unaffected control `POOL-FIN-02`.

Expected baseline:
- `Application` log contains `Event ID 9011`
- No matching crash pattern with `Faulting module name = igdumd64.dll` in same interval

Decision rule:
- Affected host has `1000 + 9009` pattern and Event 1000 module `igdumd64.dll`
- Control host `POOL-FIN-02` shows `9011` healthy baseline
- If both true, confirm this incident signature.

### 6) Intune scope confirmation by command (fast, no portal clicking)

If Azure CLI is available and authenticated:

```powershell
az account show --output table
az rest --method get --url "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?$filter=contains(displayName,'Hide')" --output json
```

Use output to identify candidate hide policy, then confirm assignment via API object fields (`assignments`, group IDs/names).

If Azure CLI is unavailable, use portal fallback:
- `https://intune.microsoft.com > Devices > Configuration > Profiles > <Hide policy> > Assignments`

## Resolution

Target runtime: 5 to 10 minutes for first-device remediation.

Before running commands:

```powershell
az login
az account set --subscription "<subscription-name-or-id>"
az extension add --name desktopvirtualization --upgrade
New-Item -Path C:\temp -ItemType Directory -Force | Out-Null
```

### Step 1: Open the exact Azure and Intune locations

Use both paths in parallel:
- Azure host path: `Azure Portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts`
- Intune policy path: `https://intune.microsoft.com > Devices > Configuration > Profiles`

In `Host pools > FIN01 > Session hosts`, identify:
- Affected host: `POOL-FIN-01` (or active affected host)
- Unaffected control: `POOL-FIN-02`

Expected result:
- Both hosts visible with status and session count.
- Candidate hide-desktop policy visible in Intune Profiles.

### Step 2: Remove wrong assignment by command (fast path)

Run in PowerShell on admin workstation:

```powershell
$policyNameMatch = "Hide"
$groupName = "Floor 6 Legal"

$policyResp = az rest --method get --url "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?$filter=contains(displayName,'$policyNameMatch')" | ConvertFrom-Json
$policyId = $policyResp.value[0].id

$groupId = (az ad group show --group "$groupName" | ConvertFrom-Json).id
$assignResp = az rest --method get --url "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyId/assignments" | ConvertFrom-Json

$assignResp | ConvertTo-Json -Depth 20 | Out-File C:\temp\assignments-before.json -Encoding ascii

$newAssignments = @()
foreach ($a in $assignResp.value) {
  if (-not ($a.target.groupId -and $a.target.groupId -eq $groupId)) {
    $newAssignments += @{ target = $a.target }
  }
}

$body = @{ assignments = $newAssignments } | ConvertTo-Json -Depth 20
$body | Out-File C:\temp\assign-body-remove-floor6.json -Encoding ascii

az rest --method post --url "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyId/assign" --headers "Content-Type=application/json" --body "@C:\temp\assign-body-remove-floor6.json"
```

Expected result:
- Command returns success.
- `C:\temp\assignments-before.json` created for rollback.
- `Floor 6 Legal` removed from active assignments.

Portal cross-check (fallback/confirm):
- `https://intune.microsoft.com > Devices > Configuration > Profiles > <Hide policy> > Assignments`

### Step 3: Force refresh on affected host from Azure path

Exact Azure host path:
- `Azure Portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01`

Quick command path (no RDP required):

```powershell
$rg = "<session-host-resource-group>"
$vm = "POOL-FIN-01"

az vm run-command invoke -g $rg -n $vm --command-id RunPowerShellScript --scripts "gpupdate /force"
az vm restart -g $rg -n $vm
```

Expected result:
- gpupdate command completes.
- Host restarts.
- Users can sign back in after host is available.

### Step 4: Check host settings and image reference (required path)

Exact Azure VM path:
- `Azure Portal > Virtual machines > POOL-FIN-01 > Settings > Configuration`

Check:
- Image reference is expected and matches control baseline image family.

Control compare path:
- `Azure Portal > Virtual machines > POOL-FIN-02 > Settings > Configuration`

Expected result:
- Affected and control hosts show expected image configuration.

### Step 5: Cohort rollout

Portal path:
- `https://intune.microsoft.com > Devices > All devices`

Action:
- Filter Floor 6 devices.
- Track `Last check-in` column.
- Send restart instruction through team lead.

Expected result:
- Majority of devices check in within 30 minutes.
- Remaining devices update on next restart/check-in cycle.

## Verification

Run all checks from exact paths below.

### V-1 Assignment removed

Path:
- `https://intune.microsoft.com > Devices > Configuration > Profiles > <Hide policy> > Assignments`

Verify option/field:
- `Included groups` does not contain `Floor 6 Legal`.

Command verification:

```powershell
$policyId = ((az rest --method get --url "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?$filter=contains(displayName,'Hide')" | ConvertFrom-Json).value[0].id)
az rest --method get --url "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyId/assignments" --output json
```

Pass if group is absent.

### V-2 Affected host recovered

Path:
- `Azure Portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01`

Verify option/field:
- Host status available.
- User can sign in and desktop icons are visible.

Command verification:

```powershell
az desktopvirtualization session-host show -g <hostpool-rg> --host-pool-name FIN01 --name POOL-FIN-01 --output json
```

### V-3 Event signature cleared on affected host

Command verification:

```powershell
Get-WinEvent -ComputerName POOL-FIN-01 -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddMinutes(-30)} |
  Select-Object TimeCreated, Id, ProviderName, Message | Format-List
```

Pass if no new matching failure pattern after fix window.

### V-4 Healthy control remains normal

Path:
- `Azure Portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02`

Command verification:

```powershell
Get-WinEvent -ComputerName POOL-FIN-02 -FilterHashtable @{LogName='Application'; Id=9011; StartTime=(Get-Date).AddHours(-4)} |
  Select-Object -First 5 TimeCreated, Id, ProviderName, Message | Format-List
```

Pass if Event 9011 baseline remains present on POOL-FIN-02.

### V-5 Host image comparison

Path:
- `Azure Portal > Virtual machines > POOL-FIN-01 > Settings > Configuration`
- `Azure Portal > Virtual machines > POOL-FIN-02 > Settings > Configuration`

Verify option/field:
- Image reference fields are expected and comparable.

Command verification:

```powershell
az vm show -g <session-host-resource-group> -n POOL-FIN-01 --query "storageProfile.imageReference" --output table
az vm show -g <session-host-resource-group> -n POOL-FIN-02 --query "storageProfile.imageReference" --output table
```

## Rollback

Use these exact rollback paths and commands.

### RB-1 Revert assignment immediately

Path:
- `https://intune.microsoft.com > Devices > Configuration > Profiles > <Hide policy> > Assignments`

Command rollback (uses backup from Step 2):

```powershell
az rest --method post --url "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyId/assign" --headers "Content-Type=application/json" --body "@C:\temp\assignments-before.json"
```

Expected rollback result:
- Original assignment set restored.

### RB-2 Host-level rollback on FIN01

Path:
- `Azure Portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01`

Actions/options:
- Set affected host to Drain mode if user impact continues.
- Move users to healthy host `POOL-FIN-02`.

Command rollback:

```powershell
az desktopvirtualization session-host update -g <hostpool-rg> --host-pool-name FIN01 --name POOL-FIN-01 --allow-new-session false
```

Expected rollback result:
- New sessions stop landing on affected host.

### RB-3 Re-apply previous known-good VM image path

Path:
- `Azure Portal > Virtual machines > POOL-FIN-01 > Settings > Configuration`

Action:
- Compare image with `POOL-FIN-02`.
- If mismatch exists, rebuild/redeploy POOL-FIN-01 from known-good image version.

Command rollback (validation step):

```powershell
az vm show -g <session-host-resource-group> -n POOL-FIN-01 --query "storageProfile.imageReference" --output json
az vm show -g <session-host-resource-group> -n POOL-FIN-02 --query "storageProfile.imageReference" --output json
```

### RB-4 Fast evidence capture before escalation

Paths:
- `Azure Portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts`
- `Event Viewer > Windows Logs > Application`

Commands:

```powershell
Get-WinEvent -ComputerName POOL-FIN-01 -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddHours(-4)} |
  Select-Object TimeCreated, Id, ProviderName, Message | Export-Csv C:\temp\pool-fin-01-events.csv -NoTypeInformation

Get-WinEvent -ComputerName POOL-FIN-02 -FilterHashtable @{LogName='Application'; Id=9011; StartTime=(Get-Date).AddHours(-4)} |
  Select-Object TimeCreated, Id, ProviderName, Message | Export-Csv C:\temp\pool-fin-02-baseline.csv -NoTypeInformation
```

Expected rollback result:
- Evidence package ready for L3 escalation and rapid decision.

## Preventive

Implement all controls below to prevent recurrence:

1. Assignment Guardrail Matrix
- Owner: DWP engineer | Timing: Before deployment | Type: Manual (can automate with policy-as-code validation).
- Pass/Fail signal: `unauthorized_assignment_count = 0` when comparing policy targets to matrix; fail if count >= 1.
- Failure action: Change manager blocks rollout and returns change to release engineer for reassignment fix.
- [REQUIRES: Version-controlled policy-to-group matrix]

2. Mandatory Policy Metadata Gate
- Owner: Release engineer | Timing: Before deployment | Type: Automated (CI lint) or manual checklist fallback.
- Pass/Fail signal: Description matches `Purpose|Intended Group|Change Ticket|Owner`; fail if any field empty.
- Failure action: Build/release gate fails; change manager rejects promotion ticket until metadata is corrected.
- [REQUIRES: CI linter or release checklist policy]

3. Pre-Deployment Scope Diff Check
- Owner: Change manager | Timing: Before deployment | Type: Manual (can automate via Graph diff script).
- Pass/Fail signal: `new_group_additions = 0` OR dual approval recorded; fail if additions >= 1 without second approval.
- Failure action: Freeze deployment and require second approver sign-off in change record.
- [REQUIRES: Two-person approval workflow]

4. Pilot Ring Enforcement
- Owner: Release engineer | Timing: During deployment | Type: Manual + automated telemetry readout.
- Pass/Fail signal (30-minute window): Event 1000 count with `igdumd64.dll` on pilot = 0 and Event 9009 count = 0.
- Failure action: Stop promotion, keep production unassigned, trigger rollback path and incident review.
- [REQUIRES: Pilot group and timed rollout window]

5. Automated Drift Alert
- Owner: DWP engineer | Timing: After deployment (daily) | Type: Automated.
- Pass/Fail signal: scheduled query returns `drift_count = 0`; fail if restricted policy targets unauthorized group (count >= 1).
- Failure action: Auto-create service ticket, page service desk lead, and open corrective change within 1 business hour.
- [REQUIRES: Scheduled Graph query + alerting channel]

6. Incident Template Standard
- Owner: Service desk lead | Timing: During deployment incidents and post-incident closure | Type: Manual.
- Pass/Fail signal: ticket contains 3 required artifacts (Assignments, gpresult, Application log events); fail if artifact_count < 3.
- Failure action: ticket cannot be closed until evidence completeness check passes.

7. Pre-Deployment Smoke Test Gate
- Owner: Release engineer | Timing: Before deployment | Type: Automated preferred, manual acceptable.
- Pass/Fail signal: on pilot host, `gpresult` shows hide policy only for intended group and Application log has no new Event 1000/9009 in 15 minutes.
- Failure action: cancel deployment window and route to image owner + DWP engineer for correction.

8. In-Flight Monitoring Alert Window
- Owner: DWP engineer | Timing: During deployment (first 60 minutes) | Type: Automated.
- Pass/Fail signal: alert if affected-host Event 1000 or 9009 count >= 1 OR if impacted user ticket count >= 3 in 30 minutes.
- Failure action: auto-trigger rollback decision meeting and pause further assignment changes.
- [REQUIRES: Central event collection and ticket-volume metric]

9. Post-Deployment Validation Gate
- Owner: Change manager | Timing: After deployment, before change closure | Type: Manual checklist with command output.
- Pass/Fail signal: V1-V5 checks pass, Event 9011 present on POOL-FIN-02 baseline, and no new Event 1000/9009 on affected host for 30 minutes.
- Failure action: keep change open, revert assignment, and execute rollback section.

10. Rollback Trigger Threshold
- Owner: Change manager | Timing: During and after deployment | Type: Manual trigger (can be automated).
- Pass/Fail signal: rollback required if Event 1000/9009 appears after rollout OR if >10% of cohort reports missing icons within 30 minutes.
- Failure action: immediate RB-1 assignment restore and host drain on POOL-FIN-01.

11. Knowledge Update Control
- Owner: Service desk lead | Timing: After incident closure (within 2 business days) | Type: Manual.
- Pass/Fail signal: runbook, L1 KB, and L2 KB updated with new evidence/signature; fail if any of 3 docs unchanged.
- Failure action: reopen problem record and assign update tasks to DWP engineer and release engineer.

## Related

- [PROJECT/runbook-floor6-shortcuts-incident.md](PROJECT/runbook-floor6-shortcuts-incident.md)
- [PROJECT/triage-summary-floor6-desktop-shortcuts.md](PROJECT/triage-summary-floor6-desktop-shortcuts.md)
- [PROJECT/analysis-floor6-desktop-shortcuts-3-hypotheses.md](PROJECT/analysis-floor6-desktop-shortcuts-3-hypotheses.md)
- [PROJECT/rca-floor6-desktop-shortcuts-incident.md](PROJECT/rca-floor6-desktop-shortcuts-incident.md)
- [PROJECT/kb-article-l1-desktop-shortcuts-self-service.md](PROJECT/kb-article-l1-desktop-shortcuts-self-service.md)
