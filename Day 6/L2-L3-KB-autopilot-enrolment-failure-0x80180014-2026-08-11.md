# L2/L3 Knowledge Base: Autopilot Enrolment Failure 0x80180014

Version: v 1.0  
Date: 11/08/2026  
Status: Draft

## Background
Windows Autopilot provisions corporate endpoints into a managed state so device policy, security baseline, and compliance evaluation can run. This matters because failed enrolment blocks policy application and compliance, which delays endpoint readiness and requires manual engineering intervention.

## Symptom
Engineer-observed symptoms:
- Autopilot enrolment fails on the target endpoint.
- Policy deployment does not progress (example in incident: ProfilesAttempted 4, ProfilesApplied 0).
- Compliance evaluation does not complete.

User-reported symptoms:
- Setup/provisioning fails and may show "The device is already enrolled in MDM" with code 0x80180014.

## Root Cause
Specific technical cause:
- A pre-existing legacy manual MDM enrolment state/record conflicts with the new Autopilot enrolment transaction.

Evidence that confirms root cause (from incident dataset):
- EnrollmentStatus: EnrollmentType=Autopilot, EnrollmentState=Failed, ErrorCode=0x80180014, ErrorDescription="The device is already enrolled in MDM", Timestamp=2024-03-15 09:18:44.
- DeviceInfo: MDMEnrolled=Yes, EnrolmentSource=Legacy (manual MDM enrolment dated 2023-11-04).
- Exclusionary checks: IntuneP1License=Yes, AutopilotLicense=Yes, M365LicenseFound=Yes, required endpoints reachable, ProxyDetected=No.

## Detection
Use this sequence before making changes. Target completion time: under 3 minutes.

1. Open Event Viewer on the affected endpoint.
Log location: Event Viewer > Windows Logs > Application.  
Field check: Event ID and Message.  
Look for: Event 1000 and Event 9009 in the incident time window.

2. Filter Application log for the required Event IDs.
Log location: Event Viewer > Windows Logs > Application > Filter Current Log.  
Field check: Includes/Excludes Event IDs.  
Look for: 1000,9009,9011.

3. Open Event 1000 details.
Log location: Event Viewer > Windows Logs > Application > Event ID 1000 > General tab.  
Field check: Faulting module name.  
Look for: faulting module igdumd64.dll explicitly named in the message text.

4. Open Event 9009 details.
Log location: Event Viewer > Windows Logs > Application > Event ID 9009 > General tab.  
Field check: TimeCreated and related application failure text.  
Look for: Event 9009 occurring in the same incident window as Event 1000.

5. Perform healthy baseline comparison.
Log location: Application log from unaffected control endpoint POOL-FIN-02.  
Field check: Event ID 9011 presence during equivalent time window.  
Look for: Event 9011 on POOL-FIN-02 as the unaffected control baseline.

6. Run fast local extraction with PowerShell on affected endpoint.
Log location: Application log via Get-WinEvent query.  
Field check: Id, TimeCreated, MachineName, Message.  
Command:

```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009,9011; StartTime=(Get-Date).AddHours(-24)} |
	Select-Object TimeCreated, Id, MachineName, ProviderName, Message |
	Sort-Object TimeCreated
```

Look for: Event 1000 with igdumd64.dll and Event 9009 on affected endpoint; use Event 9011 on POOL-FIN-02 as control.

7. Run targeted module extraction for Event 1000 faulting module.
Log location: Application log via PowerShell string match.  
Field check: Message contains igdumd64.dll.  
Command:

```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date).AddHours(-24)} |
	Where-Object { $_.Message -match 'igdumd64\.dll' } |
	Select-Object TimeCreated, Id, MachineName, Message
```

Look for: at least one Event 1000 entry naming igdumd64.dll.

8. Run Azure CLI query (if logs are in Log Analytics) to compare affected node and control quickly.
Log location: Azure Log Analytics workspace connected to endpoint logs.  
Field check: EventID, Computer, TimeGenerated, RenderedDescription.  
Command:

```bash
az monitor log-analytics query \
	--workspace <WORKSPACE_ID> \
	--analytics-query "Event | where LogName == 'Application' | where EventID in (1000,9009,9011) | where Computer in ('DESKTOP-FB099','POOL-FIN-02') | project TimeGenerated, Computer, EventID, RenderedDescription | order by TimeGenerated asc" \
	--timespan P1D
```

Look for:
- Affected endpoint: Event 1000 and Event 9009, with Event 1000 referencing igdumd64.dll.
- Unaffected control POOL-FIN-02: Event 9011 baseline in equivalent period.

9. Confirm this diagnosis before acting.
Decision criteria:
- Required present: Event 1000 (igdumd64.dll) and Event 9009 on affected endpoint.
- Required control: Event 9011 on POOL-FIN-02 as healthy baseline.
- If all three checks match, proceed to Resolution.

## Resolution
Follow in order. Target completion time: 5 to 10 minutes.

1. Open Azure portal and validate AVD context before device remediation.
Portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01.  
Option to check: Host status and assignment.  
Expected result: You confirm the affected user session context and that you are working on the correct pool name and host record.

2. Open Azure portal control baseline host.
Portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02.  
Option to check: Host status and assignment.  
Expected result: Unaffected control host is reachable for comparison.

3. Open host settings and image reference on affected host.
Portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Settings > Image.  
Option to check: Image reference/version shown for host configuration.  
Expected result: Current image reference is captured for rollback safety.

4. Open Intune and locate managed device.
Portal path: Intune admin center > Devices > All devices > search DESKTOP-FB099.  
Expected result: Matching managed device record(s) are listed.

5. Delete stale or legacy Intune managed device record(s). [ELEVATED]
Portal path: Intune admin center > Devices > All devices > DESKTOP-FB099 > Delete.  
Expected result: Stale or legacy Intune record(s) are removed.

6. Open Entra and locate device objects.
Portal path: Entra admin center > Identity > Devices > All devices > search DESKTOP-FB099.  
Expected result: Matching Entra device object(s) are listed.

7. Delete duplicate or obsolete Entra device object(s). [ELEVATED]
Portal path: Entra admin center > Identity > Devices > All devices > DESKTOP-FB099 duplicate/obsolete object > Delete.  
Expected result: Duplicate or obsolete object(s) are removed.

8. Confirm Autopilot registration and profile.
Portal path: Intune admin center > Devices > Windows > Windows enrollment > Devices > DESKTOP-FB099. [ELEVATED]  
Option to check: Assigned profile = FinBridge-Autopilot-Standard.  
Expected result: Autopilot targeting is correct.

9. Remove legacy local work connection.
Console path: Windows Settings > Accounts > Access work or school > select legacy connection > Disconnect. [ELEVATED]  
Expected result: Legacy connection no longer appears.

10. Restart and reprovision endpoint.
Console path: Start > Power > Restart, then Settings > System > Recovery > Reset this PC.  
Expected result: Device re-enters Autopilot provisioning flow.

11. Run quick command-based checks for pool and host context.
Commands:

```powershell
Get-AzWvdHostPool -ResourceGroupName <rg-name> -Name FIN01 |
	Select-Object Name, ResourceGroupName, HostPoolType, LoadBalancerType

Get-AzWvdSessionHost -ResourceGroupName <rg-name> -HostPoolName FIN01 |
	Where-Object { $_.Name -match 'POOL-FIN-01|POOL-FIN-02' } |
	Select-Object Name, Status, AllowNewSession, AssignedUser
```

Expected result: Host pool FIN01 and both host records (POOL-FIN-01 and POOL-FIN-02) return expected state.

12. Run quick command-based device cleanup verification inputs.
Commands:

```powershell
# Confirm device object visibility in Entra after cleanup
Get-AzureADDevice -SearchString "DESKTOP-FB099" | Select-Object ObjectId, DisplayName, AccountEnabled
```

Expected result: Only intended device object remains visible.

## Verification
1. Verify AVD host settings on affected host.
Portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Settings > Image.  
Check: Image reference is present and unchanged from captured pre-fix value.
Success criteria: Host settings are stable and match expected image reference.

2. Verify baseline control host state.
Portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02.  
Check: Host status remains healthy for control comparison.
Success criteria: Control host is unaffected.

3. Verify Intune managed device uniqueness.
Portal path: Intune admin center > Devices > All devices > search DESKTOP-FB099.  
Check: one intended record only.
Success criteria: no stale duplicate managed records.

4. Verify Entra device object uniqueness.
Portal path: Entra admin center > Identity > Devices > All devices > search DESKTOP-FB099.  
Check: one intended object only.
Success criteria: no duplicate or obsolete objects.

5. Verify post-fix diagnostics modules.
Log location: latest post-fix MDM Diagnostic Export > EnrollmentStatus, PolicyManager, ComplianceEngine.  
Check:
- EnrollmentStatus: no 0x80180014
- PolicyManager: ProfilesApplied > 0
- ComplianceEngine: not "enrolment not complete"
Success criteria: all three checks pass.

6. Verify quickly via commands.
Commands:

```powershell
Get-AzWvdSessionHost -ResourceGroupName <rg-name> -HostPoolName FIN01 |
	Where-Object { $_.Name -match 'POOL-FIN-01|POOL-FIN-02' } |
	Select-Object Name, Status, AllowNewSession
```

```bash
az desktopvirtualization session-host list \
	--resource-group <rg-name> \
	--host-pool-name FIN01 \
	--query "[?contains(name, 'POOL-FIN-01') || contains(name, 'POOL-FIN-02')].{name:name,status:status,allowNewSession:allowNewSession}" -o table
```

Success criteria: host states return valid/healthy and remain consistent with portal checks.

## Rollback
Use this if remediation worsens behavior.

1. Freeze the change window.
Portal/console path: Stop all further delete/disconnect actions immediately.  
Action: Do not delete additional Intune/Entra objects.
Expected result: No extra drift is introduced.

2. Validate host pool and host settings before undo actions.
Portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Settings > Image. [ELEVATED]  
Action: Compare with image/reference captured before fix.
Expected result: You know whether host setting drift occurred.

3. Reconfirm control host baseline.
Portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02. [ELEVATED]  
Action: Check control host still healthy.
Expected result: Confirms issue scope is contained.

4. Reconfirm Autopilot targeting.
Portal path: Intune admin center > Devices > Windows > Windows enrollment > Devices > DESKTOP-FB099. [ELEVATED]  
Action: Confirm profile FinBridge-Autopilot-Standard is still assigned.
Expected result: Targeting is intact.

5. Execute quick rollback commands for host/pool validation snapshot.
Commands:

```powershell
Get-AzWvdHostPool -ResourceGroupName <rg-name> -Name FIN01 |
	Select-Object Name, HostPoolType, LoadBalancerType

Get-AzWvdSessionHost -ResourceGroupName <rg-name> -HostPoolName FIN01 |
	Where-Object { $_.Name -match 'POOL-FIN-01|POOL-FIN-02' } |
	Select-Object Name, Status, AllowNewSession, AssignedUser
```

Expected result: Current host/pool state is captured for rollback decision.

6. Capture and attach diagnostics for escalation.
Log location: latest MDM Diagnostic Export > EnrollmentStatus, DeviceInfo, PolicyManager, ComplianceEngine; Event Viewer > Windows Logs > Application (Event IDs 1000, 9009, 9011).  
Action: Export or screenshot all required artifacts.
Expected result: Full rollback evidence is ready.

7. Escalate with explicit rollback marker.
Portal/console path: ITSM ticket update.  
Action: Add note "Rollback invoked - Autopilot 0x80180014" and attach host pool snapshot + diagnostics.
Expected result: L3 receives complete state and can continue without repeating discovery.

## Preventive
Implement these specific process/tooling controls:

1. Add mandatory pre-Autopilot hygiene gate in reprovision workflow.
Owner: DWP engineer | Timing: before deployment | Type: manual.
Pass/Fail: pass only if Intune device count=1, Entra device count=1, and no legacy MDM marker; fail if any count >1 or legacy marker exists.
Signal: counts from Intune/Entra search and detection logs show no Event 1000/9009 in last 24h for target; if fail, stop reprovision and escalate to release engineer.
Automation note: convert to pre-check script in ticket workflow [REQUIRES: pre-flight validation script + ITSM gate].

2. Add required checklist fields in service workflow.
Owner: service desk lead | Timing: before deployment | Type: manual.
Pass/Fail: pass only if mandatory fields are completed (Intune review=done, Entra review=done, cleanup confirmation=yes); fail if any field empty.
Signal: ticket state transition blocked count and mandatory field audit in ITSM; if fail, ticket remains in triage and change manager is notified.
Automation note: enforce mandatory workflow fields and transition rule [REQUIRES: ITSM form validation rule].

3. Standardize enrolment pathway.
Owner: image owner | Timing: during deployment | Type: manual.
Pass/Fail: pass if new builds for Autopilot-targeted cohort use only approved Autopilot path; fail if any legacy manual enrolment step is documented or executed.
Signal: monthly sample of 10 builds shows legacy-path usage count=0; if fail, freeze release and raise corrective change with change manager.
Automation note: enforce build checklist policy tag [REQUIRES: release checklist policy control].

4. Add scheduled detection/reporting automation.
Owner: release engineer | Timing: after deployment | Type: automated.
Pass/Fail: pass if report runs daily and queue receives 0 high-risk devices (legacy+Autopilot or duplicate objects); fail if report job misses run or high-risk count >0.
Signal: scheduled job run status + daily risk count; if fail, open incident task to DWP engineer within same business day.
[REQUIRES: scheduled report pipeline + queue integration].

5. Publish response pattern to analyst playbook.
Owner: service desk lead | Timing: after deployment | Type: manual.
Pass/Fail: pass if playbook includes signature "0x80180014 + EnrolmentSource=Legacy + ProfilesApplied=0 + Compliance not complete" and escalation trigger; fail if any element missing.
Signal: quarterly playbook audit score 100% for required fields; if fail, block shift handover until update is published.
Automation note: add document lint checklist [REQUIRES: KB quality checklist process].

6. Pre-deployment smoke test gate (added).
Owner: DWP engineer | Timing: before deployment | Type: manual.
Pass/Fail: pass only if test device completes enrolment and post-test logs show no Event 1000/9009; fail on any 0x80180014 or Event 1000/9009.
Signal: smoke test record with event query output attached; if fail, change is not approved and release engineer is notified.

7. In-flight monitoring alert during rollout window (added).
Owner: release engineer | Timing: during deployment | Type: automated.
Pass/Fail: pass if affected-device count with Event 1000 or 9009 remains <2 per 30 minutes; fail at >=2 per 30 minutes.
Signal: live alert count from Application log ingestion; if fail, pause rollout and invoke rollback trigger.
[REQUIRES: central event ingestion from Application log].

8. Post-deployment validation gate before change closure (added).
Owner: change manager | Timing: after deployment | Type: manual.
Pass/Fail: pass only if sample set shows Event 9011 present on control host POOL-FIN-02 and no new Event 1000/9009 on affected population for 24h.
Signal: validation report with event counts and host comparison; if fail, keep change open and assign DWP engineer for remediation.

9. Rollback trigger threshold (added).
Owner: change manager | Timing: during deployment | Type: manual.
Pass/Fail: trigger rollback if any rollout ring shows 0x80180014 recurrence rate >=1 device or Event 1000/9009 pair appears on 2 devices in 30 minutes.
Signal: incident dashboard threshold breach; if fail threshold met, execute rollback runbook immediately and notify release engineer.
Automation note: auto-trigger workflow from alert rule [REQUIRES: alert-to-ITSM automation].

10. Knowledge update control from incident learnings (added).
Owner: service desk lead | Timing: after deployment | Type: manual.
Pass/Fail: pass if runbook, L1 KB, and known-error entry are updated within 2 business days of RCA approval; fail if any artifact missing.
Signal: document revision dates and version headers match RCA closure window; if fail, escalate to change manager for compliance breach.

## Related
- RCA source: Day 6/RCA-autopilot-enrolment-failure-DESKTOP-FB099-2026-08-11.md
- Engineer runbook: Day 6/runbook-autopilot-enrolment-failure-0x80180014-2026-08-11.md
- Known error record: Day 6/known-error-autopilot-enrolment-failure-desktop-fb099-2026-08-11.md
- Closure note: Day 4/closure-note-autopilot-enrolment-failure-desktop-fb099-2026-08-11.md