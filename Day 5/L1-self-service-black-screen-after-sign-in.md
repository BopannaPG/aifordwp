# KB: AVD Black Screen After Login on POOL-FIN-01 (L2/L3)

## Version Header

- Version: v 1.0
- Date: 07/08/2026
- Status : Draft
- Audience: DWP L2/L3 Engineers
- Source: Runbook - AVD Black Screen After Login on POOL-FIN-01

## Background

Azure Virtual Desktop (AVD) host pools POOL-FIN-01 and POOL-FIN-02 provide multi-session desktops for finance users. Users authenticate through AVD, land on a session host, and Desktop Window Manager (DWM) renders the interactive desktop.

This matters because if DWM crashes during or immediately after sign-in, users may authenticate successfully but never reach a usable desktop. In production, that causes immediate business impact: users appear "logged in" but cannot work.

## Symptom

### What the engineer observes

1. In Azure portal at Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, affected hosts show active connection attempts but unstable session behavior (rapid disconnect/reconnect churn).
2. In the affected POOL-FIN-01 host Event Viewer logs, Application errors and DWM operational failures cluster around user sign-in times.
3. In POOL-FIN-02 (comparison pool), equivalent hosts remain stable with no matching crash signature.

### What the user reports

1. "I can sign in to AVD, but I only see a black screen."
2. "It may disconnect me or force reconnect shortly after login."
3. Issue started after morning usage window (around 07:00) following overnight image update activity.

## Root Cause

### Technical cause

POOL-FIN-01 hosts were running an updated image state that introduced a failing graphics stack component. During user logon, DWM process dwm.exe crashed in module igdumd64.dll, preventing normal desktop rendering and causing black screen plus disconnect loop behavior.

### Evidence that confirms root cause

1. Affected host log evidence: Event ID 1000 in Application log with fields Faulting application name = dwm.exe and Faulting module name = igdumd64.dll.
2. Affected host log evidence: Event ID 9009 in Desktop Window Manager Operational log near the same sign-in timestamps.
3. Affected host session evidence: TerminalServices-LocalSessionManager Operational Event ID 21 (logon) followed quickly by Event ID 40 (disconnect).
4. Comparison host evidence (POOL-FIN-02): Event ID 9011 (DWM start success) present, with no matching Event ID 1000 dwm.exe/igdumd64.dll signature in the same time window.

## Detection

Target time: under 3 minutes. Run command checks first, then validate in Event Viewer only if needed.

1. Identify one affected host and one healthy control host.
Portal path: Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts.
Optional Azure CLI (faster host pick):

```powershell
az desktopvirtualization hostpool session-host list --resource-group <RG_FIN_01> --host-pool-name POOL-FIN-01 --query "[].{SessionHost:name,Status:status,AllowNewSession:allowNewSession}" -o table
az desktopvirtualization hostpool session-host list --resource-group <RG_FIN_02> --host-pool-name POOL-FIN-02 --query "[].{SessionHost:name,Status:status,AllowNewSession:allowNewSession}" -o table
```

Expected result: one suspect host from POOL-FIN-01 and one healthy host from POOL-FIN-02 are selected.

2. On the affected POOL-FIN-01 host, query Application log for Event ID 1000 and the exact crash signature.
Exact log location: Event Viewer > Windows Logs > Application (LogName = Application).

```powershell
Invoke-Command -ComputerName <FIN01_HOST> -ScriptBlock {
	$start = (Get-Date).AddHours(-6)
	Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000; StartTime = $start } |
		Where-Object {
			$_.Message -match 'Faulting application name:\s*dwm\.exe' -and
			$_.Message -match 'Faulting module name:\s*igdumd64\.dll'
		} |
		Select-Object -First 10 TimeCreated, Id, MachineName, Message
}
```

Look for fields in message: Faulting application name = dwm.exe and Faulting module name = igdumd64.dll.
Expected result: matching Event 1000 entries are present on POOL-FIN-01.

3. On the affected POOL-FIN-01 host, query DWM Operational log for Event ID 9009.
Exact log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational (LogName = Microsoft-Windows-Desktop Window Manager/Operational).

```powershell
Invoke-Command -ComputerName <FIN01_HOST> -ScriptBlock {
	$start = (Get-Date).AddHours(-6)
	Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Desktop Window Manager/Operational'; Id = 9009; StartTime = $start } |
		Select-Object -First 20 TimeCreated, Id, MachineName, Message
}
```

Expected result: Event 9009 appears around sign-in times.

4. On the affected POOL-FIN-01 host, confirm logon-disconnect loop with Event IDs 21 and 40.
Exact log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational (LogName = Microsoft-Windows-TerminalServices-LocalSessionManager/Operational).

```powershell
Invoke-Command -ComputerName <FIN01_HOST> -ScriptBlock {
	$start = (Get-Date).AddHours(-6)
	Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id = 21,40; StartTime = $start } |
		Select-Object -First 30 TimeCreated, Id, MachineName, Message
}
```

Expected result: repeated 21 then 40 sequence for affected sessions.

5. On healthy POOL-FIN-02 control host, confirm unaffected DWM baseline Event ID 9011.
Exact log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational (LogName = Microsoft-Windows-Desktop Window Manager/Operational).

```powershell
Invoke-Command -ComputerName <FIN02_HOST> -ScriptBlock {
	$start = (Get-Date).AddHours(-6)
	Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Desktop Window Manager/Operational'; Id = 9011; StartTime = $start } |
		Select-Object -First 20 TimeCreated, Id, MachineName, Message
}
```

Expected result: Event 9011 appears on POOL-FIN-02 as healthy control behavior.

6. On healthy POOL-FIN-02 control host, confirm absence of Event 1000 dwm.exe/igdumd64.dll signature.
Exact log location: Event Viewer > Windows Logs > Application (LogName = Application).

```powershell
Invoke-Command -ComputerName <FIN02_HOST> -ScriptBlock {
	$start = (Get-Date).AddHours(-6)
	Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000; StartTime = $start } |
		Where-Object {
			$_.Message -match 'Faulting application name:\s*dwm\.exe' -and
			$_.Message -match 'Faulting module name:\s*igdumd64\.dll'
		} |
		Select-Object -First 10 TimeCreated, Id, MachineName, Message
}
```

Expected result: no matching Event 1000 crash signature on POOL-FIN-02.

Decision gate: Confirm this incident only when POOL-FIN-01 shows Event 1000 (dwm.exe + igdumd64.dll) and Event 9009 with 21->40 loop, while POOL-FIN-02 shows Event 9011 baseline and no matching Event 1000 signature.

## Resolution

Target time: 5-10 minutes for containment and service redirection.

Set variables once (CLI/PowerShell quick path):

```powershell
$rgFin01 = '<RG_FIN_01>'
$rgFin02 = '<RG_FIN_02>'
$hpFin01 = 'POOL-FIN-01'
$hpFin02 = 'POOL-FIN-02'
$fin01Hosts = @('<FIN01_HOST1>', '<FIN01_HOST2>')
$fin02Hosts = @('<FIN02_HOST1>', '<FIN02_HOST2>')
```

1. Contain affected FIN01 hosts.
Portal path and option: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select host(s) > Allow new sessions > set to No.
Azure CLI:

```powershell
foreach ($h in $fin01Hosts) {
	az desktopvirtualization hostpool session-host update `
		--resource-group $rgFin01 `
		--host-pool-name $hpFin01 `
		--session-host-name $h `
		--allow-new-session false
}
```

PowerShell (Az.DesktopVirtualization):

```powershell
foreach ($h in $fin01Hosts) {
	Update-AzWvdSessionHost -ResourceGroupName $rgFin01 -HostPoolName $hpFin01 -Name $h -AllowNewSession:$false
}
```

Expected result: new sessions stop landing on impacted POOL-FIN-01 hosts.

2. Ensure unaffected FIN02 capacity is open.
Portal path and option: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts > select capacity hosts > Allow new sessions > set to Yes.
Azure CLI:

```powershell
foreach ($h in $fin02Hosts) {
	az desktopvirtualization hostpool session-host update `
		--resource-group $rgFin02 `
		--host-pool-name $hpFin02 `
		--session-host-name $h `
		--allow-new-session true
}
```

PowerShell:

```powershell
foreach ($h in $fin02Hosts) {
	Update-AzWvdSessionHost -ResourceGroupName $rgFin02 -HostPoolName $hpFin02 -Name $h -AllowNewSession:$true
}
```

Expected result: new sessions are redirected to healthy POOL-FIN-02 hosts.

3. Correct image baseline for FIN01.
Portal path and option: image pipeline console > POOL-FIN-01 image definition > Versions > select corrected version (or last known-good pre-2024-03-15 02:00) > Promote or Set as current.
If using Azure Compute Gallery image versions, optional CLI check:

```powershell
az sig image-version list --resource-group <RG_IMAGE> --gallery-name <GALLERY_NAME> --gallery-image-definition <FIN01_IMAGE_DEF> --query "[].name" -o table
```

Expected result: corrected/known-good image is active deployment baseline.

4. Redeploy FIN01 hosts from corrected image.
Portal path and option: Azure portal > Resource groups > <RG_FIN_01_COMPUTE> > Virtual machine scale sets (or host VMs) > select FIN01 compute object > Instances > Reimage (or replace via approved pipeline).
Optional CLI for VMSS-based hosts:

```powershell
az vmss reimage --resource-group <RG_FIN_01_COMPUTE> --name <FIN01_VMSS> --instance-ids <ID1> <ID2>
```

Expected result: replacement hosts register and appear Available in Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.

5. Controlled sign-in validation.
Tool path: AVD client > Workspace > POOL-FIN-01 desktop > sign in with test account.
Expected result: desktop renders without persistent black screen or immediate disconnect.

6. Re-open intake host-by-host.
Portal path and option: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select remediated host > Allow new sessions > set to Yes.
CLI:

```powershell
foreach ($h in $fin01Hosts) {
	az desktopvirtualization hostpool session-host update `
		--resource-group $rgFin01 `
		--host-pool-name $hpFin01 `
		--session-host-name $h `
		--allow-new-session true
}
```

Expected result: POOL-FIN-01 returns safely to normal intake.

## Verification

Complete all checks before closure.

1. Host state verification.
Portal path and options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Verify columns: Status = Available, Allow new sessions = Yes, Session count stable.
CLI:

```powershell
az desktopvirtualization hostpool session-host list --resource-group $rgFin01 --host-pool-name $hpFin01 --query "[].{Host:name,Status:status,AllowNewSession:allowNewSession,Sessions:session}" -o table
```

Expected result: remediated POOL-FIN-01 hosts are healthy and accepting sessions.

2. Application log verification (Event 1000 signature absent).
Exact log location: Event Viewer > Windows Logs > Application.
PowerShell:

```powershell
Invoke-Command -ComputerName <REMEDIATED_FIN01_HOST> -ScriptBlock {
	$start = (Get-Date).AddHours(-1)
	Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000; StartTime = $start } |
		Where-Object {
			$_.Message -match 'Faulting application name:\s*dwm\.exe' -and
			$_.Message -match 'Faulting module name:\s*igdumd64\.dll'
		} |
		Select-Object TimeCreated, Id, Message
}
```

Expected result: no new Event 1000 entries with dwm.exe and igdumd64.dll.

3. DWM operational verification (Event 9009 absent).
Exact log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational.
PowerShell:

```powershell
Invoke-Command -ComputerName <REMEDIATED_FIN01_HOST> -ScriptBlock {
	$start = (Get-Date).AddHours(-1)
	Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Desktop Window Manager/Operational'; Id = 9009; StartTime = $start } |
		Select-Object TimeCreated, Id, Message
}
```

Expected result: no recurring Event 9009 after test sign-ins.

4. Session flow verification (21 not immediately followed by 40).
Exact log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational.
PowerShell:

```powershell
Invoke-Command -ComputerName <REMEDIATED_FIN01_HOST> -ScriptBlock {
	$start = (Get-Date).AddHours(-1)
	Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id = 21,40; StartTime = $start } |
		Select-Object -First 30 TimeCreated, Id, Message
}
```

Expected result: no immediate 21 -> 40 loop for validation sessions.

5. User-path verification.
Tool path: AVD client > Workspace > POOL-FIN-01 desktop.
Run 3 consecutive logins (disconnect and reconnect between attempts).
Expected result: all 3 attempts load and keep a usable desktop.

6. Unaffected control verification on FIN02.
Portal path and options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts > select control host.
Exact log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational.
PowerShell:

```powershell
Invoke-Command -ComputerName <CONTROL_FIN02_HOST> -ScriptBlock {
	$start = (Get-Date).AddHours(-1)
	Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Desktop Window Manager/Operational'; Id = 9011; StartTime = $start } |
		Select-Object TimeCreated, Id, Message
}
```

Expected result: Event 9011 baseline remains present on unaffected POOL-FIN-02 host.

## Rollback

If remediation increases impact, execute immediately (fast rollback sequence).

1. Stop FIN01 intake immediately.
Portal path and option: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select all impacted hosts > Allow new sessions = No.
CLI:

```powershell
foreach ($h in $fin01Hosts) {
	az desktopvirtualization hostpool session-host update --resource-group $rgFin01 --host-pool-name $hpFin01 --session-host-name $h --allow-new-session false
}
```

Expected result: new user sessions stop on POOL-FIN-01.

2. Shift intake to FIN02.
Portal path and option: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts > select capacity hosts > Allow new sessions = Yes.
CLI:

```powershell
foreach ($h in $fin02Hosts) {
	az desktopvirtualization hostpool session-host update --resource-group $rgFin02 --host-pool-name $hpFin02 --session-host-name $h --allow-new-session true
}
```

Expected result: new sessions are routed to healthy POOL-FIN-02 capacity.

3. Restore last known-good image.
Portal path and option: image pipeline console > POOL-FIN-01 image definition > Versions > choose version before 2024-03-15 02:00 > Promote or Set as current.
If using Azure Compute Gallery, optional CLI reference:

```powershell
az sig image-version list --resource-group <RG_IMAGE> --gallery-name <GALLERY_NAME> --gallery-image-definition <FIN01_IMAGE_DEF> --query "[].name" -o table
```

Expected result: known-good baseline is active.

4. Rebuild/reimage affected FIN01 compute.
Portal path and option: Azure portal > Resource groups > <RG_FIN_01_COMPUTE> > Virtual machine scale sets (or host VMs) > Instances > Reimage or Replace.
Optional VMSS CLI:

```powershell
az vmss reimage --resource-group <RG_FIN_01_COMPUTE> --name <FIN01_VMSS> --instance-ids <ID1> <ID2>
```

Expected result: failing image state is removed from service.

5. Post-rollback verification before re-open.
Exact log locations:
- Event Viewer > Windows Logs > Application (Event ID 1000, check no dwm.exe + igdumd64.dll).
- Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational (Event ID 9009, check no repeat exits).
PowerShell:

```powershell
Invoke-Command -ComputerName <ROLLED_BACK_FIN01_HOST> -ScriptBlock {
	$start = (Get-Date).AddHours(-1)
	$e1000 = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000; StartTime = $start } |
		Where-Object { $_.Message -match 'dwm\.exe' -and $_.Message -match 'igdumd64\.dll' }
	$e9009 = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Desktop Window Manager/Operational'; Id = 9009; StartTime = $start }
	[PSCustomObject]@{Crash1000=$e1000.Count; Dwm9009=$e9009.Count}
}
```

Expected result: Crash1000 = 0 and no repeating 9009 pattern before re-opening intake.

6. Controlled return-to-service.
Portal path and option: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > set Allow new sessions = Yes one host at a time.
CLI:

```powershell
az desktopvirtualization hostpool session-host update --resource-group $rgFin01 --host-pool-name $hpFin01 --session-host-name <ONE_VALIDATED_HOST> --allow-new-session true
```

Expected result: rollback completes safely with measurable host-by-host recovery.

## Preventive

Implement all controls below to prevent recurrence.

1. Image promotion gate with graphics validation:
Owner: image owner. Timing: before deployment. Mode: automated. [REQUIRES: image pipeline test gate + synthetic AVD login runner]
Pass: 0 matches of Application Event 1000 (dwm.exe + igdumd64.dll), 0 repeating 21->40 loops, and Event 9009 count = 0 during 30-minute test.
Fail action: release engineer blocks promotion and returns image to image owner; no rollout starts until a clean rerun passes.

2. Ringed deployment process for host pools:
Owner: release engineer. Timing: during deployment. Mode: automated for halt, manual for ring approval. [REQUIRES: phased rollout workflow]
Pass: canary (about 10 percent hosts) runs 60 minutes with Event 1000 (dwm.exe + igdumd64.dll) count = 0 and Event 9009 rate <= 1 per host per hour.
Fail action: auto-halt wider rollout; DWP engineer sets FIN01 Allow new sessions = No on canary hosts and opens rollback workflow.

3. Cross-pool baseline monitor:
Owner: DWP engineer. Timing: during deployment and first 24 hours after deployment. Mode: automated. [REQUIRES: Log Analytics workspace + alert rule]
Pass: POOL-FIN-01 stays within threshold (Event 1000 signature count = 0 and Event 9009 delta vs POOL-FIN-02 <= 2 per host per hour).
Fail action: Sev2 alert triggers; on-call DWP engineer executes containment (FIN01 Allow new sessions = No, FIN02 = Yes) within 10 minutes.

4. Change record hard requirement:
Owner: change manager. Timing: before deployment CAB approval. Mode: manual.
Pass: ticket contains known-good image version, target version, rollback command set, and owner sign-off checklist complete.
Fail action: CAB status = Rejected/On Hold; automation approach: enforce mandatory fields and approval policy in change template. [REQUIRES: change template policy]

5. Intake safety policy automation:
Owner: service desk lead. Timing: during deployment and incident response window. Mode: automated. [REQUIRES: AVD containment runbook automation]
Pass: when trigger condition is met, FIN01 impacted hosts flip to Allow new sessions = No and FIN02 capacity hosts remain/set to Yes in one run.
Fail action: if script fails or partial state detected, DWP engineer performs manual CLI containment and records exception in incident timeline.

6. Post-deployment validation gate:
Owner: DWP engineer. Timing: after deployment and before change closure. Mode: manual (can be automated). [REQUIRES: post-deploy checklist]
Pass: 3 consecutive AVD logins to FIN01 succeed, Event 1000 signature count = 0, Event 9009 count = 0, and no 21->40 loop in last 60 minutes.
Fail action: change remains open, rollback trigger is evaluated immediately; automation approach: schedule verification script and attach output to change record.

7. Rollback trigger threshold:
Owner: release engineer. Timing: during deployment. Mode: automated with manual override. [REQUIRES: rollback orchestration rule]
Pass: no trigger breach during rollout window.
Fail action: automatic rollback starts if any FIN01 host logs >=1 Event 1000 (dwm.exe + igdumd64.dll) or >=3 Event 9009 within 15 minutes, then notify DWP engineer and change manager.

8. Knowledge update control:
Owner: service desk lead. Timing: after deployment (within 1 business day of incident/near-miss closure). Mode: manual.
Pass: runbook, detection checklist, and L1 article are updated with new thresholds/commands and version/date changed; peer review completed.
Fail action: change cannot be marked "lessons learned complete"; automation approach: workflow task in ticketing tool with mandatory document links. [REQUIRES: knowledge workflow task]

## Related

1. RCA: outlook app crash pattern is a separate application-layer failure and should not be conflated with DWM graphics crash workflow.
2. RCA: print spooler crash loop is service-specific and unrelated to AVD graphics stack failure.
3. RCA: user lockout incidents (Security Event IDs 4625/4740) are authentication workflows and must use lockout runbooks, not this KB.
4. Closure note: AVD black-screen closure for POOL-FIN-01 provides incident evidence and timeline reference for this KB.
