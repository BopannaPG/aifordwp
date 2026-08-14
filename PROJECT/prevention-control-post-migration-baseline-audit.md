# Prevention Control: Post-Migration Baseline Audit
**Version 1.0 | 14/08/2026 | Bopanna | Status: Recommended Implementation**

---

## The Control (Name)
**Post-Migration Baseline Access Audit** — Automated comparison of user group memberships BEFORE and AFTER migration to detect unauthorized additions within 24 hours.

---

## What This Catches
The Floor 6 incident: Migration script added 630 unauthorized group memberships (45 users × 14 cases each) at 4 PM on Aug 10. This control **would have detected it at 8 AM on Aug 11**, before anyone opened their email Monday morning.

---

## The Process (Executable Steps)

### Prerequisites (Do Once Before Migration)
1. **Export baseline**: Run this PowerShell on Aug 9 (day before migration)
   ```powershell
   Connect-MgGraph -Scopes "DirectoryManagement.ReadWrite.All"
   $users = Get-MgUser -Filter "Department eq 'Legal'" | Select-Object UserPrincipalName, Id
   $baseline = @()
   foreach ($user in $users) {
       $groups = Get-MgUserMemberOf -UserId $user.Id -Filter "resourceType eq 'microsoft.graph.group'"
       foreach ($group in $groups) {
           $baseline += [PSCustomObject]@{
               UserUPN = $user.UserPrincipalName
               GroupId = $group.Id
               GroupName = (Get-MgGroup -GroupId $group.Id).DisplayName
               CaptureDate = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
           }
       }
   }
   $baseline | Export-Csv -Path "C:\audits\floor6-baseline-pre-migration-[DATE].csv" -NoTypeInformation
   ```
2. **Save file**: `C:\audits\floor6-baseline-pre-migration-2026-08-09.csv` (rename with actual date)
3. **Backup location**: Also copy to `\\finbridge\audits\migrations\baseline-floor6-2026-08-09.csv`

### Audit Execution (Run 8 AM Next Business Day After Migration)
**Owner**: Access Control Team Lead  
**Timing**: 8 AM on Aug 11, 2026 (first business day after Aug 10 migration)  
**Duration**: ~10 minutes  
**Executable Step-by-Step**:

1. **Re-query current state**:
   ```powershell
   $current = @()
   foreach ($user in $users) {
       $groups = Get-MgUserMemberOf -UserId $user.Id -Filter "resourceType eq 'microsoft.graph.group'"
       foreach ($group in $groups) {
           $current += [PSCustomObject]@{
               UserUPN = $user.UserPrincipalName
               GroupId = $group.Id
               GroupName = (Get-MgGroup -GroupId $group.Id).DisplayName
               CaptureDate = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
           }
       }
   }
   ```

2. **Compare baseline vs. current**:
   ```powershell
   $baselineIds = $baseline | Select-Object UserUPN, GroupId
   $currentIds = $current | Select-Object UserUPN, GroupId
   $newUnauthorized = Compare-Object $baselineIds $currentIds -Property UserUPN, GroupId | Where-Object { $_.SideIndicator -eq '=>' }
   ```

3. **Export audit report**:
   ```powershell
   $newUnauthorized | Export-Csv -Path "C:\audits\floor6-post-migration-audit-2026-08-11.csv" -NoTypeInformation
   $newUnauthorized | Measure-Object | Select-Object Count > "C:\audits\floor6-audit-summary-2026-08-11.txt"
   ```

4. **Check result**:
   - Open `C:\audits\floor6-audit-summary-2026-08-11.txt`
   - **PASS**: File contains "Count : 0" → All clear, log result, send "PASS" to Change Management
   - **FAIL**: File contains "Count : 630" (or any number > 0) → Immediate escalation (next step)

---

## Success Criteria
**PASS**: Audit report shows exactly 0 new unauthorized group memberships  
**FAIL**: Audit report shows any number > 0 (expected: 630 in Floor 6 scenario)

---

## If Audit FAILS (What Happens Immediately)

1. **Escalation ticket** (Create within 5 minutes):
   - **Severity**: CRITICAL
   - **Title**: "Post-Migration Baseline Audit FAILED — [Count] unauthorized group additions detected"
   - **Assigned to**: Security Engineering Team Lead
   - **Timeline**: Acknowledge within 30 minutes

2. **Pause decision**: If failure count > 100 or unknown root cause → Do NOT proceed with next phase of migration until cleared

3. **Immediate remediation**: Run Floor 6 remediation runbook (reference `runbook-floor6-access-remediation-final.md`) by 10 AM same day

---

## Why This Catches Floor 6

| Event | Time | Normal Detection | This Control |
|-------|------|------------------|--------------|
| Migration runs | Aug 10, 4 PM | — | — |
| Baseline audit scheduled | Aug 11, 8 AM | — | **AUDIT RUNS** |
| Audit result | Aug 11, 8:15 AM | — | **"630 unauthorized additions DETECTED"** |
| Escalation ticket created | Aug 11, 8:20 AM | — | **TICKET CREATED** |
| Actual discovery (current timeline) | Aug 13, Monday morning | **USER REPORTS UNAUTHORIZED CASE** | Would have been caught 48h earlier |

**Impact**: Instead of 45 users exposed for 3 days (72 hours), problem detected and remediated same day (8 hours).

---

## Implementation Requirements

### Who
- **Access Control Team Lead** (specific role; does not require specific person)
- **Change Management** (receives PASS/FAIL notification)
- **Security Engineering** (receives escalation if FAIL)

### When
- Setup: Aug 9 at 2 PM (capture baseline before migration)
- Execution: Aug 11 at 8 AM (or 8 AM next business day after any future migration)
- Recurring: After every group migration or access control migration project

### What You Need
1. PowerShell 7+ with Microsoft Graph module (`Install-Module Microsoft.Graph.Users`)
2. User Administrator or Directory Reader role in Azure AD
3. Network access to Azure AD and `C:\audits\` directory (or shared network path)
4. Pre-migration baseline CSV file (created day before migration)

### Automation Level
- **Capture baseline**: Manual (run once before migration)
- **Audit execution**: Can be automated (scheduled PowerShell task at 8 AM)
- **Report generation**: Automated (PowerShell export to CSV)
- **Escalation**: Manual ticket creation OR automated via webhook integration with ticketing system

### Estimated Cost
- Development: 4 hours (script write, test, document)
- Deployment: 30 minutes (schedule task, update runbooks)
- Recurring effort: 10 minutes per migration execution
- Automation enhancement: 2–4 hours (integrate with change management ticketing)

---

## Risk Mitigation
- **Risk**: Audit false positive (detects legitimate additions)
  - **Mitigation**: Baseline must be captured AFTER prior migration completes; verify baseline count matches expected group assignments
- **Risk**: Audit runs before Azure AD replication complete
  - **Mitigation**: Always wait 2 hours post-migration before running audit (by design: 4 PM migration → 8 AM next day = 16 hours)
- **Risk**: Team forgets to run audit
  - **Mitigation**: Automate as scheduled task; add calendar reminder to Access Control Team Lead calendar

---

## Concrete Success Metric
This control is "done" when:
1. ✅ Baseline capture script tested and working (pre-migration baseline created)
2. ✅ Audit script tested and working (run against historical baseline, produces accurate diff)
3. ✅ Escalation process documented (ticket template created, Access Control → Security Engineering workflow established)
4. ✅ Automated task scheduled (PowerShell task runs at 8 AM on `[event: migration complete]`)
5. ✅ Team trained (Access Control Team Lead runs mock audit and explains PASS/FAIL process)

---

## Timeline
**Target implementation**: By Sept 8, 2026 (before any future migrations)

---

## Acceptance Test
Run mock scenario:
1. Use historical Floor 6 baseline CSV (from before Aug 10 migration)
2. Simulate current state as of Aug 10, 4 PM (add 630 unauthorized groups)
3. Run audit against simulated state
4. Verify audit detects exactly 630 unauthorized additions ✓
5. Verify escalation ticket would have been created ✓
6. **Result**: "If this control had been active, Floor 6 issue caught at 8 AM Aug 11 instead of 8 AM Aug 13" → **PASS**
