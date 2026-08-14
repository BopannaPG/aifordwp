# Finalized Resolution: Access Control Misconfiguration Post-Migration

**Hypothesis:** Floor 6 paralegal was accidentally added to unauthorized matter-access group during Win11/Intune migration; migration script or permission sync assigned her to groups matching floor-wide access pattern rather than her actual case assignments.

**Confidence Level:** HIGH (most probable given timing: migration recent + only 1 user reporting + user's claim of "never had access")

---

## Exact Remediation Steps (Execution Order)

### Phase 1: Immediate Containment (5 minutes)

**Step 1.1: Verify actual user permissions** *(Do first; confirms hypothesis)*
```powershell
# Run on admin workstation with Azure AD permissions

$paralegal = Get-AzADUser -Filter "userPrincipalName eq 'paralegal.name@finbridge.com'" -ErrorAction Stop
Write-Host "User: $($paralegal.DisplayName) | UPN: $($paralegal.UserPrincipalName)"

# Get all groups user is member of
$allGroups = Get-AzADGroupMember -GroupId $paralegal.Id -ErrorAction Stop
$matterGroups = $allGroups | Where-Object { $_.DisplayName -match 'Matter-|Client-|Case-' }

Write-Host "Total groups: $($allGroups.Count)"
Write-Host "Matter-related groups: $($matterGroups.Count)"
$matterGroups | Format-Table DisplayName, @{Name="CreatedDateTime"; Expression={$_.CreatedDateTime}}

# Expected result (if hypothesis TRUE):
# - User is member of 2+ matter-access groups
# - Groups were created/user added post-migration date (compare to Win11 migration start date)
# - Groups do NOT match user's actual case assignments
```

**DECISION GATE:** If user has 0 matter-related groups → Hypothesis FALSE; escalate to Cause 2/3. If user has 2+ unauthorized groups → Proceed to Step 1.2

**Step 1.2: Identify which groups are unauthorized** *(Verify with Floor 6 manager)*
```powershell
# Contact Floor 6 manager/case administrator: "Which cases/matters should this paralegal have access to?"
# Compare list against $matterGroups from Step 1.1

# Example expected answer: "She should have access to Matter-CompanyA-Contract-2026 and Matter-CompanyB-Litigation-2024 ONLY"
# If she's member of 15+ other Matter-* groups → those are unauthorized

# Document findings
$unauthorizedGroups = $matterGroups | Where-Object { $_.DisplayName -notmatch 'CompanyA-Contract|CompanyB-Litigation' }
Write-Host "Unauthorized groups to remove: $($unauthorizedGroups.Count)"
$unauthorizedGroups | Select-Object DisplayName, Id | Export-Csv -Path C:\temp\floor6-unauthorized-groups.csv
```

**Step 1.3: Remove user from all unauthorized groups** *(Execute removals)*
```powershell
# CRITICAL: Do NOT remove from authorized groups; only remove from unauthorized

foreach ($group in $unauthorizedGroups) {
    try {
        Remove-AzADGroupMember -GroupId $group.Id -MemberId $paralegal.Id -Confirm:$false -ErrorAction Stop
        Write-Host "✓ Removed from: $($group.DisplayName) [ID: $($group.Id)]"
        
        # Log action for audit
        Add-Content -Path C:\temp\floor6-remediation-log.txt -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Removed $($paralegal.DisplayName) from $($group.DisplayName)"
    } catch {
        Write-Host "✗ FAILED to remove from $($group.DisplayName): $_"
        Add-Content -Path C:\temp\floor6-remediation-log.txt -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | FAILED: $($group.DisplayName) - $_"
    }
}

Write-Host "`nRemediations logged to: C:\temp\floor6-remediation-log.txt"
```

---

### Phase 2: Verify Remediation (2 minutes)

**Step 2.1: Confirm group memberships updated**
```powershell
# Re-query user's current groups (allow 5 min for Azure AD sync)
Start-Sleep -Seconds 300

$updatedGroups = Get-AzADGroupMember -GroupId $paralegal.Id -ErrorAction Stop
$updatedMatterGroups = $updatedGroups | Where-Object { $_.DisplayName -match 'Matter-|Client-|Case-' }

Write-Host "Groups after remediation: $($updatedMatterGroups.Count)"
$updatedMatterGroups | Format-Table DisplayName

# Expected result: Only authorized groups remain (e.g., 2 groups for CompanyA and CompanyB only)
if ($updatedMatterGroups.Count -le 2) {
    Write-Host "✓ PASSED: User membership corrected"
} else {
    Write-Host "✗ FAILED: Still has $($updatedMatterGroups.Count) matter groups; expected ≤2"
}
```

**Step 2.2: Test Copilot access** *(Manual test — 2 min)*
- **Paralegal logs into:** Microsoft 365 portal or Copilot interface
- **Runs search:** Search for the client matter that was previously visible
- **Expected result:** Matter should NO LONGER appear in Copilot search results (permission filtering now enforced)
- **If still visible:** Run Step 2.3; if gone → Remediation successful

**Step 2.3: Force Copilot search index refresh** *(Only if Step 2.2 fails)*
```powershell
# Force update to Azure AD Graph index (Copilot uses this for permission filtering)
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/me/followedSites/recentActivity" -ErrorAction Stop

# Alternative: Clear Copilot cache in user's browser
# Instruct user: "Clear browser cache and cookies for m.365.cloud.microsoft; refresh Copilot page"

Write-Host "Index refresh initiated. User should clear browser cache and retest within 5 minutes."
```

---

### Phase 3: Audit for Scope (10 minutes — parallel with Phase 1/2)

**Step 3.1: Check all Floor 6 users for same misconfiguration**
```powershell
# Get all Floor 6 users
$floor6Group = Get-AzADGroup -Filter "displayName eq 'Floor6-Legal'" -ErrorAction Stop
$floor6Users = Get-AzADGroupMember -GroupId $floor6Group.Id -ErrorAction Stop

# Check each user's matter-group memberships
$auditResults = foreach ($user in $floor6Users) {
    $matterGroups = Get-AzADGroupMember -GroupId $user.Id -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Matter-|Client-|Case-' }
    @{
        UserName = $user.DisplayName
        Email = $user.UserPrincipalName
        MatterGroupCount = $matterGroups.Count
        GroupNames = ($matterGroups.DisplayName -join '; ')
    }
}

# Flag users with unusually high matter-group counts
$suspicious = $auditResults | Where-Object { $_.MatterGroupCount -gt 10 }
Write-Host "Users with >10 matter groups (potential misconfiguration): $($suspicious.Count)"
$suspicious | Format-Table -AutoSize

$auditResults | Export-Csv -Path C:\temp\floor6-audit-results.csv
```

**Step 3.2: Document migration issue**
- Create ticket: "Floor 6 Win11 migration: Permission drift detected post-migration"
- Attach: C:\temp\floor6-audit-results.csv, C:\temp\floor6-unauthorized-groups.csv
- Assign to: DWP Infrastructure Lead
- Root cause: "[Specify which migration script or tool caused broad group assignment]"

---

## Order of Operations (Do in This Sequence)

| Phase | Step | Duration | Blocker? | Notes |
|-------|------|----------|----------|-------|
| 1 | 1.1: Verify hypothesis | 2 min | YES | If user has 0 matter groups, hypothesis is FALSE; escalate to Cause 2/3 |
| 1 | 1.2: Identify unauthorized groups | 5 min | YES | Requires manager confirmation of legitimate access |
| 1 | 1.3: Remove user from unauthorized groups | 2 min | NO | Can execute in parallel with Phase 3 |
| 2 | 2.1: Verify group removals | 5 min (with sync wait) | NO | Wait 5 min for Azure AD sync after removals |
| 2 | 2.2: Test Copilot access | 2 min | YES | If matter still visible, proceed to 2.3 |
| 2 | 2.3: Force index refresh | 1 min | NO | Only if 2.2 fails; manual browser cache clear may take additional 5 min |
| 3 | 3.1: Audit all Floor 6 users | 10 min | NO | Run in parallel with Phases 1/2 while user is verifying Copilot access |
| 3 | 3.2: Document for prevention | 5 min | NO | Create ticket for Infrastructure team |

**Total Execution Time:** 27 minutes (including Azure AD sync wait)

---

## Verification Check (Confirm Resolution Complete)

**V-Check 1: User no longer has unauthorized group memberships** *(PowerShell — 2 min)*
```powershell
$paralegal = Get-AzADUser -Filter "userPrincipalName eq 'paralegal.name@finbridge.com'"
$matterGroups = Get-AzADGroupMember -GroupId $paralegal.Id | Where-Object { $_.DisplayName -match 'Matter-|Client-|Case-' }
$authorizedMatters = @('Matter-CompanyA-Contract-2026', 'Matter-CompanyB-Litigation-2024')

$unauthorizedRemaining = $matterGroups | Where-Object { $_.DisplayName -notin $authorizedMatters }

if ($unauthorizedRemaining.Count -eq 0) {
    Write-Host "✓ PASSED: No unauthorized groups remain"
    exit 0
} else {
    Write-Host "✗ FAILED: $($unauthorizedRemaining.Count) unauthorized groups still present"
    exit 1
}
```
**Expected result:** Exit code 0; no unauthorized groups listed

---

**V-Check 2: Copilot no longer displays unauthorized matter** *(Manual — 3 min)*
- Paralegal logs into Copilot: https://copilot.microsoft.com
- Searches: "[Name of client matter that was visible before remediation]"
- **Expected result:** Search returns "No results" or matter NOT listed in results
- **Failure result:** Matter still appears in results → escalate to Cause 3 (search permission issue)

**V-Check 3: Case management system reflects correct access** *(Manual — 3 min)*
- Open case management system (e.g., SharePoint matter list, case assignment DB)
- Verify paralegal's name is listed for: CompanyA-Contract-2026, CompanyB-Litigation-2024 ONLY
- Verify her name is NOT listed for all other matters
- **Expected result:** Assignments match Step 1.2 "authorized matters" list

---

## Preventive Action: Stop This Recurring

**Preventive Control: Access Control Audit Gate Post-Migration**

**Timing:** Within 5 business days of any large-scale identity/permission migration (Win10→Win11, on-prem→cloud, etc.)

**Owner:** DWP Infrastructure Lead

**Process:**
1. **Run audit script (Step 3.1)** on all affected users → generate report of group memberships vs. expected access matrix
2. **Compare baseline:** Pre-migration access matrix (export from old system) vs. post-migration group memberships (export from Azure AD)
3. **Flag discrepancies:** Identify users with >X extra group memberships or with groups outside their known case assignments (X = median group count + 2 standard deviations)
4. **Remediate:** Remove users from unauthorized groups (Step 1.3 process)
5. **Measure:** Document # of users affected, # of unauthorized groups found, time to remediate
6. **Update migration checklist:** Add "Access Control Audit" as mandatory step before closing migration project

**Automation approach:** Create recurring PowerShell job that runs post-migration, compares baseline vs. current state, and emails Infrastructure Lead with flagged users for manual review/approval

**Target:** Implement by September 15, 2026 (in place before next departmental migration)

