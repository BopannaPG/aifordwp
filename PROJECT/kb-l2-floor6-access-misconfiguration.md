---
# Knowledge Base Article — L2 Engineer Troubleshooting

**Title:** Floor 6 Legal — Unauthorized Matter-Access Group Membership Post-Migration  
**Version:** 1.0  
**Date:** 14/08/2026  
**Status:** Draft  
**Audience:** DWP Engineers (IT operations)  
**Incident Category:** Access Control Misconfiguration  
**Severity:** CRITICAL (attorney-client privilege violation)  

---

## Background

**System Context:**

Floor 6 Legal operates on a **permission-layered data governance model**:
- Users access confidential client matters through **security groups** (Matter-* naming convention)
- Each security group grants access to a specific client matter in Copilot, SharePoint, and case management systems
- Users should belong to **1–3 matter-access groups** based on their assigned cases
- The system enforces **role-based access control (RBAC):** No access to group = no access to matter data

**Why It Matters:**

Legal firms must maintain **attorney-client privilege** and **data governance compliance**. Unauthorized access to client matters violates:
- Legal confidentiality obligations (client trust + liability exposure)
- Regulatory requirements (GDPR, CCPA, state bar associations)
- Incident response timelines (this incident must be reported to compliance)

---

## Symptoms

**User Report (What End Users Say):**
- "I see a client matter in Copilot that I've never worked on"
- "I can search for [case name] and it appears—I swear I don't have that case"
- "When I click the matter, I can open and view the full case details"

**Engineer Observation (What You'll See):**

### Observable in Copilot Search:
- User searches for unauthorized matter name → Matter appears in results
- User clicks result → Matter data loads successfully (confirms actual access, not just search display)
- User reports this via Service Desk

### Observable in Azure AD:
```
User email: jane.doe@finbridge.com
Groups: 
  ✗ Matter-CompanyD-MandatoryVendor-2026 (unauthorized)
  ✗ Matter-CompanyE-Litigation-2024 (unauthorized)
  ✗ Matter-CompanyF-IPTransfer-2025 (unauthorized)
  ✗ ... (14+ unauthorized groups total)
  ✓ Matter-CompanyA-Contract-2026 (authorized)
  ✓ Matter-CompanyB-Litigation-2024 (authorized)
```

**Timeline Indicator:**
- Detection: 3–4 days POST-migration (users gradually discover unauthorized access via search)
- Duration: Until removal from unauthorized groups (27 min to several hours if backlogged)
- Scope: Typically 1–3 initial reports; audit reveals cohort-wide misconfiguration

---

## Root Cause

**Primary Cause: Migration Script Logic Error**

The migration script `Migrate-OnPremGroupsToAzureAD.ps1` executed during Windows 11 + Intune migration committed this error:

```
LOGIC ERROR:
IF (GroupName matches 'notification' OR 'all' OR 'floor')
   THEN Migrate to Azure AD as security group
   AND Add to ALL Matter-* access-control groups
ELSE
   Migrate as distribution group (non-access-control)
```

**What Happened:**
1. On-premises group: `FLOOR6-LEGAL-ALLUSERS` (notification group—intended for broadcast emails, NOT access control)
2. Script identified "ALLUSERS" pattern → Migrated as **security group** to Azure AD
3. Script then added this group to **ALL 14+ Matter-* security groups** as a blanket assignment
4. Result: All 45 Floor 6 users (members of FLOOR6-LEGAL-ALLUSERS) gained access to all 14+ matters

**Evidence Confirming Root Cause:**

### Evidence 1: Azure AD Audit Log Entry
**Location:** Azure Portal > Azure Active Directory > Audit logs  
**Search Filter:** 
- Activity: "Add member to group"
- Date: [Migration date, e.g., Aug 10, 2026]
- User: `Migration-Service-Account@finbridge.com`
- Initiated by: Service account running migration script

**Expected Finding:**
```
Timestamp: Aug 10, 2026 16:15:23 UTC
Activity: Add member to group
Target: Matter-CompanyD-MandatoryVendor-2026
Object: FLOOR6-LEGAL-ALLUSERS group
Result: Success
Modified Properties: members (added 45 users at once)
```

**Repeat Pattern:** Same entry for Matter-CompanyE, Matter-CompanyF, etc. (14+ entries all within 10-minute window)

### Evidence 2: Group Membership Bulk Addition Pattern
**Location:** Azure Portal > Azure Active Directory > Groups > [Select Matter-CompanyD-MandatoryVendor-2026] > Members

**Expected Finding:**
- All 45 Floor 6 users listed as group members
- All added on same timestamp (Aug 10, ~4 PM)
- Expected: Only 3–5 users (actual case team)

### Evidence 3: Migration Script Code Review
**Location:** `\\finbridge\scripts\migrations\Migrate-OnPremGroupsToAzureAD.ps1` (version 2.1)

**Lines 156–187 (The Bug):**
```powershell
foreach ($group in $onPremGroups) {
    IF ($group.Name -match 'ALLUSERS|NOTIFICATION|FLOOR') {
        # MIGRATE AS SECURITY GROUP (WRONG LOGIC)
        New-AzADGroup -DisplayName $group.Name -MailEnabled $false
        
        # ADD TO ALL MATTER-ACCESS GROUPS (BLANKET ASSIGNMENT)
        foreach ($matterGroup in Get-AllMatterGroups) {
            Add-AzADGroupMember -GroupId $matterGroup.Id -MemberId $migratedGroup.Id
        }
    }
}
```

**Issue:** Script does not distinguish between:
- **Notification groups** (should add members individually to specific matters)
- **Access-control groups** (should restrict to assigned case teams only)

---

## Detection

**Step D-1: User Report Correlation**

**When Engineer Gets Ticket:**

1. **Search Service Desk for similar tickets (last 72 hours):**
   - Keywords: "can't access," "see," "matter," "copilot"
   - Group: "Floor 6 Legal"
   - Expected: 1–3 initial reports from same cohort

2. **Interview user:**
   - "What matter did you see?" → Note the matter name (e.g., "Matter-CompanyD-MandatoryVendor-2026")
   - "What date did you first notice?" → Log discovery timestamp
   - "Can you open it?" → Confirms ACTUAL access (not just search display issue)

**Decision Point:** If user can OPEN the matter (not just see it in search), this is access control misconfiguration, NOT search display issue.

---

**Step D-2: Verify User's Authorized Matters (Control Check)**

**Location:** Case Management System (internal legal case tracker)  
**Action:** Query authorized matters for user

Example:
```
User: jane.doe@finbridge.com
Authorized Cases (from case management DB):
  ✓ Matter-CompanyA-Contract-2026
  ✓ Matter-CompanyB-Litigation-2024
Expected Group Count: 2
```

**Log Location:** `\\finbridge\casedb\audits\user-access-audit-[date].log`

---

**Step D-3: Check User's Actual Azure AD Group Membership**

**Location:** Azure Portal → Azure Active Directory → Users → [Search user email]  
**Navigate:** "Groups" tab

**Command (PowerShell alternative):**
```powershell
Connect-MgGraph -Scopes "DirectoryManagement.ReadWrite.All"
$user = Get-MgUser -Filter "userPrincipalName eq 'jane.doe@finbridge.com'"
$groups = Get-MgUserMemberOf -UserId $user.Id -All
$matterGroups = $groups | Where-Object { $_.DisplayName -match '^Matter-' }
$matterGroups | Select-Object DisplayName | Sort-Object DisplayName
```

**Expected Result (Anomaly):**
```
DisplayName
---
Matter-CompanyA-Contract-2026 ✓ (authorized)
Matter-CompanyB-Litigation-2024 ✓ (authorized)
Matter-CompanyD-MandatoryVendor-2026 ✗ (UNAUTHORIZED)
Matter-CompanyE-Litigation-2024 ✗ (UNAUTHORIZED)
Matter-CompanyF-IPTransfer-2025 ✗ (UNAUTHORIZED)
... (12+ unauthorized groups)
```

**Pass/Fail Criteria:**
- ✓ PASS: User member of only authorized matters (2–3 groups)
- ✗ FAIL: User member of 10+ matter groups when authorized is 2–3

---

**Step D-4: Verify Pattern Across Entire Floor 6**

**Location:** PowerShell script query against Azure AD

**Command:**
```powershell
$floor6Group = Get-MgGroup -Filter "displayName eq 'Floor6-Legal'"
$floor6Users = Get-MgGroupMember -GroupId $floor6Group.Id -All

$unauthorizedSummary = @()

foreach ($user in $floor6Users) {
    $userGroups = Get-MgUserMemberOf -UserId $user.Id -All
    $matterGroups = $userGroups | Where-Object { $_.DisplayName -match '^Matter-' }
    
    # Load authorized matters from case management system
    $authorized = Get-AuthorizedMattersForUser $user.UserPrincipalName
    
    $unauthorized = $matterGroups | Where-Object { $_.DisplayName -notin $authorized.DisplayName }
    
    if ($unauthorized.Count -gt 5) {
        $unauthorizedSummary += [PSCustomObject]@{
            User = $user.UserPrincipalName
            UnauthorizedCount = $unauthorized.Count
            ExpectedCount = $authorized.Count
        }
    }
}

$unauthorizedSummary | Export-Csv -Path "C:\temp\floor6-unauthorized-audit.csv" -NoTypeInformation
```

**Expected Finding:**
```
User | UnauthorizedCount | ExpectedCount
jane.doe@finbridge.com | 14 | 2
john.smith@finbridge.com | 14 | 3
...
```

**Scope Determination:**
- If 1–5 users affected: Isolated misconfiguration
- If 40+ users affected: Cohort-wide migration script error

---

**Step D-5: Confirm Migration Timing Correlation**

**Location:** Azure Portal > Azure Active Directory > Audit logs  
**Search Filter:**
- Activity: "Update group"
- Target: "Matter-*" groups
- Date range: [Migration date ± 1 day]

**Expected Finding:**
```
Aug 10, 2026 16:10:00 UTC | Update group | Matter-CompanyA | Added member FLOOR6-LEGAL-ALLUSERS
Aug 10, 2026 16:10:15 UTC | Update group | Matter-CompanyB | Added member FLOOR6-LEGAL-ALLUSERS
Aug 10, 2026 16:10:30 UTC | Update group | Matter-CompanyC | Added member FLOOR6-LEGAL-ALLUSERS
... (all timestamps within 10-minute window)
```

**Timing Signature:** Bulk group membership changes in tight time window = script execution, NOT manual error.

---

**Step D-6: Check Migration Script Logs**

**Location:** `\\finbridge\logs\migrations\Migrate-OnPremGroupsToAzureAD\[date]\migration.log`  
**Search Term:** "FLOOR6-LEGAL-ALLUSERS" OR "added to security groups"

**Expected Log Entry:**
```
2026-08-10 16:10:00 | INFO | Migrating group FLOOR6-LEGAL-ALLUSERS
2026-08-10 16:10:05 | INFO | Detected pattern 'ALLUSERS' - migrating as security group
2026-08-10 16:10:10 | INFO | Adding FLOOR6-LEGAL-ALLUSERS to Matter-CompanyD-MandatoryVendor-2026
2026-08-10 16:10:15 | INFO | Adding FLOOR6-LEGAL-ALLUSERS to Matter-CompanyE-Litigation-2024
2026-08-10 16:10:20 | INFO | Adding FLOOR6-LEGAL-ALLUSERS to Matter-CompanyF-IPTransfer-2025
```

---

**Detection Conclusion:**

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| D-1: User report + can open matter | 1–3 users | ✓ Found | CONFIRMED |
| D-2: User has 2–3 authorized matters | 2–3 | 2 | ✓ Normal |
| D-3: User has 10+ Matter-* groups | 2–3 | 14 | ✗ ABNORMAL |
| D-4: Pattern: 40+ users affected | 40+ | 45 | ✗ Cohort-wide |
| D-5: Bulk additions Aug 10 4 PM | Same timestamp | ✓ Found | ✗ Script error |
| D-6: Migration script log entry | "Added to all Matter groups" | ✓ Found | CONFIRMED |

**Diagnosis: POSITIVE — Access Control Misconfiguration (Root Cause Confirmed)**

---

## Resolution

**Remediation Strategy:** Remove all 45 Floor 6 users from unauthorized matter-access groups while preserving authorized access.

**Prerequisites Before Starting:**
- ⚠️ You must have **Azure AD User Administrator** or **Global Administrator** role
- Backup file must exist: `C:\temp\floor6-group-memberships-before-remediation.csv` (exported before removal)
- Case management system must be accessible to verify authorized matters

---

**Step R-1: Export Pre-Remediation Baseline**

**Location:** PowerShell (run as User Administrator)

```powershell
Connect-MgGraph -Scopes "DirectoryManagement.ReadWrite.All"

$floor6Group = Get-MgGroup -Filter "displayName eq 'Floor6-Legal'"
$floor6Users = Get-MgGroupMember -GroupId $floor6Group.Id -All

$backup = @()
foreach ($user in $floor6Users) {
    $groups = Get-MgUserMemberOf -UserId $user.Id -All | Where-Object { $_.DisplayName -match '^Matter-' }
    foreach ($group in $groups) {
        $backup += [PSCustomObject]@{
            UserEmail = $user.UserPrincipalName
            GroupName = $group.DisplayName
        }
    }
}

$backup | Export-Csv -Path "C:\temp\floor6-group-memberships-before-remediation.csv" -NoTypeInformation
Write-Host "Backup created: $($backup.Count) group memberships"
```

**Expected Result:**
```
C:\temp\floor6-group-memberships-before-remediation.csv
Contains: 14 × 45 = 630 rows (each user × each unauthorized + authorized matter)
```

---

**Step R-2: Load Authorized Matters Matrix**

**Location:** Case Management System (manual export or API query)

**Required Format:** CSV file with columns:
```
ParalegalEmail | AuthorizedMatter1 | AuthorizedMatter2 | AuthorizedMatter3
jane.doe@finbridge.com | Matter-CompanyA-Contract-2026 | Matter-CompanyB-Litigation-2024 | 
john.smith@finbridge.com | Matter-CompanyC-IPTransfer-2025 | |
```

**File Location:** `C:\temp\floor6-remediation-[timestamp]\authorized-matters-matrix.csv`

**Validation:** File must have:
- ✓ All 45 Floor 6 users (rows)
- ✓ Email format: lowercase, @finbridge.com domain
- ✓ Matter names start with "Matter-" prefix

---

**Step R-3: Identify Unauthorized Groups for Removal**

**Location:** PowerShell

```powershell
$csvMatrixPath = "C:\temp\floor6-remediation-[timestamp]\authorized-matters-matrix.csv"
$matrixData = Import-Csv -Path $csvMatrixPath

# Convert to hashtable for lookup
$authorizedMatters = @{}
foreach ($row in $matrixData) {
    $email = $row.ParalegalEmail.Trim()
    $matters = @(
        $row.AuthorizedMatter1,
        $row.AuthorizedMatter2,
        $row.AuthorizedMatter3
    ) | Where-Object { $_ -and $_.Trim() -ne "" }
    $authorizedMatters[$email] = $matters
}

# Scan each Floor 6 user
$unauthorizedReport = @()
foreach ($user in $floor6Users) {
    $userEmail = $user.UserPrincipalName
    $userGroups = Get-MgUserMemberOf -UserId $user.Id -All | Where-Object { $_.DisplayName -match '^Matter-' }
    $authorizedForUser = $authorizedMatters[$userEmail]
    
    $unauthorized = $userGroups | Where-Object { $_.DisplayName -notin $authorizedForUser }
    
    foreach ($group in $unauthorized) {
        $unauthorizedReport += [PSCustomObject]@{
            UserEmail = $userEmail
            UnauthorizedGroup = $group.DisplayName
            GroupId = $group.Id
            UserId = $user.Id
        }
    }
}

$unauthorizedReport | Export-Csv -Path "C:\temp\unauthorized-groups-report.csv" -NoTypeInformation
Write-Host "Found $($unauthorizedReport.Count) unauthorized group memberships"
```

**Expected Result:**
```
Found 630 unauthorized group memberships (14 groups × 45 users)
Report: C:\temp\unauthorized-groups-report.csv
```

---

**Step R-4: Remove Users from Unauthorized Groups (CRITICAL — HIGH-RISK)**

**Location:** PowerShell (run as User Administrator)

⚠️ **CONFIRMATION GATE:** Type 'YES' (all caps) before proceeding. This is permanent until rollback.

```powershell
# FINAL CONFIRMATION GATE
Write-Host "About to remove $($unauthorizedReport.Count) group memberships"
Write-Host "Type 'YES' to proceed, or anything else to CANCEL:"
$confirm = Read-Host

if ($confirm -ne "YES") {
    Write-Host "CANCELLED. No changes made."
    exit 0
}

# Execute removals
$successCount = 0
$failureCount = 0
$logFile = "C:\temp\floor6-access-remediation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

foreach ($item in $unauthorizedReport) {
    try {
        Remove-MgGroupMember -GroupId $item.GroupId -DirectoryObjectId $item.UserId -Confirm:$false -ErrorAction Stop
        $successCount++
        Add-Content -Path $logFile -Value "$(Get-Date -Format 'HH:mm:ss') SUCCESS: $($item.UserEmail) removed from $($item.UnauthorizedGroup)"
    } catch {
        $failureCount++
        Add-Content -Path $logFile -Value "$(Get-Date -Format 'HH:mm:ss') FAILED: $($item.UserEmail) - $($_.Exception.Message)"
    }
}

Write-Host "Successful: $successCount | Failed: $failureCount"
Add-Content -Path $logFile -Value "Removal Phase Complete: $successCount successful, $failureCount failed"
```

**Expected Result After Each User Removal:**
```
✓ Removed: jane.doe@finbridge.com FROM Matter-CompanyD-MandatoryVendor-2026
✓ Removed: jane.doe@finbridge.com FROM Matter-CompanyE-Litigation-2024
...
Successful: 630
Failed: 0
```

**⚠️ If failures occur:** Document which users/groups failed. May indicate permission issue or group doesn't exist. Investigate and retry for failed entries.

---

**Step R-5: Wait for Azure AD Synchronization**

**Duration:** 5 minutes (intentional wait—do NOT skip)

```powershell
Write-Host "Waiting 5 minutes for Azure AD backend to sync..."
Start-Sleep -Seconds 300
Write-Host "Sync complete"
Add-Content -Path $logFile -Value "Azure AD sync wait completed at $(Get-Date -Format 'HH:mm:ss')"
```

**Why:** Azure AD Graph replication takes 2–5 minutes to propagate removal from all backend instances. Copilot search index updates during this window.

---

**Resolution Verification (Immediate):**

After Step R-5, re-query one user to confirm removal:

```powershell
$testUser = Get-MgUser -Filter "userPrincipalName eq 'jane.doe@finbridge.com'"
$currentGroups = Get-MgUserMemberOf -UserId $testUser.Id -All | Where-Object { $_.DisplayName -match '^Matter-' }

Write-Host "User now member of $($currentGroups.Count) matter groups"
$currentGroups | Select-Object DisplayName
```

**Expected Result:**
```
User now member of 2 matter groups
DisplayName
---
Matter-CompanyA-Contract-2026
Matter-CompanyB-Litigation-2024
```

---

## Verification

**Step V-1: Azure AD Verification (Automated)**

**Location:** PowerShell

```powershell
# Re-query all Floor 6 users and verify unauthorized groups removed
$verificationResults = @()
$allPassed = $true

foreach ($user in $floor6Users) {
    $userEmail = $user.UserPrincipalName
    $currentGroups = Get-MgUserMemberOf -UserId $user.Id -All | Where-Object { $_.DisplayName -match '^Matter-' }
    $authorizedForUser = $authorizedMatters[$userEmail]
    
    $unauthorizedRemaining = $currentGroups | Where-Object { $_.DisplayName -notin $authorizedForUser }
    
    if ($unauthorizedRemaining.Count -eq 0) {
        $status = "PASSED"
    } else {
        $status = "FAILED"
        $allPassed = $false
        Write-Host "✗ $userEmail still has $($unauthorizedRemaining.Count) unauthorized groups"
    }
    
    $verificationResults += [PSCustomObject]@{
        UserEmail = $userEmail
        Status = $status
        UnauthorizedRemaining = $unauthorizedRemaining.Count
    }
}

$verificationResults | Export-Csv -Path "C:\temp\verification-azure-ad.csv" -NoTypeInformation

if ($allPassed) {
    Write-Host "✓ V-1 PASSED: All unauthorized groups removed"
} else {
    Write-Host "✗ V-1 FAILED: Some users still have unauthorized groups"
}
```

**Expected Result:** All users show Status=PASSED; no unauthorized groups remain.

**Log File:** `C:\temp\verification-azure-ad.csv`

---

**Step V-2: Copilot Access Verification (Manual User Test)**

**Action:** Contact affected user (original reporter)

**Test Instructions:**
1. Open: https://copilot.microsoft.com
2. Sign out and sign back in
3. Search for unauthorized matter name (e.g., "Matter-CompanyD-MandatoryVendor-2026")
   - Expected: Matter should NOT appear in results
4. Search for authorized matter (e.g., "Matter-CompanyA-Contract-2026")
   - Expected: Matter SHOULD appear in results

**Expected Result:**
- ✓ Unauthorized matter: NOT visible (user cannot search/access)
- ✓ Authorized matter: Visible (user can search/access)

---

**Step V-3: Service Desk Ticket Queue Verification**

**Location:** Service Desk ticketing system (Jira / Zendesk)

**Search:** Last 2 hours, Floor 6 Legal, keywords: "access" OR "permission" OR "matter"

**Expected Result:** 0 new access-related complaints

---

**Step V-4: Audit Trail Verification**

**Location:** Log files

**Files Created During Remediation:**
```
C:\temp\floor6-access-remediation-[timestamp].log
  → All removal actions with timestamps + SUCCESS/FAILED status
  
C:\temp\verification-azure-ad.csv
  → User status post-remediation
```

**Expected Log Entry:**
```
14:35:02 SUCCESS: jane.doe@finbridge.com removed from Matter-CompanyD-MandatoryVendor-2026
14:35:03 SUCCESS: jane.doe@finbridge.com removed from Matter-CompanyE-Litigation-2024
... (630 entries)
14:45:00 Azure AD sync wait completed
14:45:01 VERIFICATION: All users passed unauthorized group check
```

---

**Verification Gate — All Checks Must PASS:**

| Check | Expected | If FAILED → Action |
|-------|----------|-------------------|
| V-1: Azure AD | All users PASSED | Execute Rollback Scenario 1 |
| V-2: Copilot Test | Unauth NOT visible + Auth visible | Execute Rollback Scenario 3 |
| V-3: Service Desk | 0 new tickets | Investigate + escalate if tickets found |
| V-4: Audit Trail | Log file exists + 630 SUCCESS entries | Investigate missing logs |

---

## Rollback

**Execute ONLY if verification fails or if resolution causes unexpected problems.**

---

### Rollback Scenario 1: Azure AD Verification Failed (Unauthorized Groups Remain)

**Trigger:** V-1 shows unauthorized groups still present for one or more users

**Cause:** Network timeout during removal, permission error, or group ID mismatch

**Quick Fix (< 2 minutes):**

```powershell
# Re-attempt removal for failed users only
$failedUsers = Import-Csv "C:\temp\verification-azure-ad.csv" | Where-Object { $_.Status -eq "FAILED" }

foreach ($user in $failedUsers) {
    $u = Get-MgUser -Filter "userPrincipalName eq '$($user.UserEmail)'" -ErrorAction Stop
    $currentGroups = Get-MgUserMemberOf -UserId $u.Id -All | Where-Object { $_.DisplayName -match '^Matter-' }
    $unauthorized = $currentGroups | Where-Object { $_.DisplayName -notin $authorizedMatters[$user.UserEmail] }
    
    foreach ($group in $unauthorized) {
        try {
            Remove-MgGroupMember -GroupId $group.Id -DirectoryObjectId $u.Id -Confirm:$false -ErrorAction Stop
            Write-Host "✓ Re-removed: $($user.UserEmail) from $($group.DisplayName)"
        } catch {
            Write-Host "✗ Still failing: $($_.Exception.Message)"
            Write-Host "ESCALATE: Contact Azure AD team"
        }
    }
}

# Wait 90 seconds and re-verify
Start-Sleep -Seconds 90
# Re-run Step V-1 verification
```

**If still fails after 90 seconds:** Escalate to Azure AD team with error message from log file.

---

### Rollback Scenario 2: User Lost Authorized Access (V-2 Test Shows Authorized Matter NOT Visible)

**Trigger:** User confirms they can NO LONGER access their authorized cases

**Cause:** Authorized matters list was incorrect; too many groups removed

**Quick Fix (< 1 minute):**

```powershell
# Get the user and re-add ONLY authorized groups
$affectedUser = "jane.doe@finbridge.com"  # Update to actual user
$authorizedMatters = $authorizedMatters[$affectedUser]

$u = Get-MgUser -Filter "userPrincipalName eq '$affectedUser'" -ErrorAction Stop

foreach ($matterName in $authorizedMatters) {
    try {
        $g = Get-MgGroup -Filter "displayName eq '$matterName'" -ErrorAction Stop
        New-MgGroupMember -GroupId $g.Id -DirectoryObjectId $u.Id -ErrorAction SilentlyContinue
        Write-Host "✓ Re-added: $affectedUser to $matterName"
    } catch {
        Write-Host "✗ Error re-adding $affectedUser to $matterName"
    }
}

Write-Host "Wait 60 seconds for sync..."
Start-Sleep -Seconds 60
```

**After Completion:** User retests Copilot search → authorized matter should now appear. **Investigation Required:** Determine why authorized matters list was incorrect for this user. Update lookup table and re-run remediation verification.

---

### Rollback Scenario 3: Copilot Still Shows Unauthorized Matter (V-2 Shows Unauth Matter Still Visible)

**Trigger:** User confirms unauthorized matter still appears in Copilot search after removal confirmed

**Cause:** Azure AD Graph replication lag (~2–4 hours) OR Copilot search permission filtering not enforced

**Action (< 30 seconds instruction):**

**For User:**
```
1. Clear your browser cache for copilot.microsoft.com
2. Close browser completely
3. Reopen browser and log into Copilot again
4. Try searching for the unauthorized matter
   - Expected: Matter should no longer appear
```

**For Engineer:**
```powershell
# Check if directory sync is available (cloud-only feature)
$syncStatus = Get-MgBetaDirectorySyncConfiguration -ErrorAction SilentlyContinue

if ($syncStatus) {
    Write-Host "Directory sync available. Sync typically completes within 2-4 hours."
} else {
    Write-Host "Sync not available in this tenant."
}

# If still visible after 4 hours: ESCALATE
Write-Host "If matter still visible after 4 hours, escalate to Microsoft 365 team"
Write-Host "Issue: Copilot search result permissions not enforced"
```

---

### Rollback Scenario 4: Emergency — Multiple Users (5+) Report New Access Issues in 30 Minutes

**Trigger:** Service Desk receives 5+ new "can't access my case" tickets within 30 minutes post-remediation

**Cause:** Authorized matters lookup table was drastically incorrect; too many groups removed across cohort

**Action: Full Restore (< 2 minutes):**

```powershell
# EMERGENCY RESTORE TO PRE-REMEDIATION STATE

$backupFile = "C:\temp\floor6-group-memberships-before-remediation.csv"

if (-not (Test-Path $backupFile)) {
    Write-Host "ERROR: Backup file missing. Cannot execute emergency restore."
    Write-Host "ESCALATE: Contact Azure AD team + Manager"
    exit 1
}

Write-Host "⚠⚠⚠ EMERGENCY RESTORE ⚠⚠⚠"
Write-Host "This will UNDO all removals. Type 'CONFIRM' to proceed:"
$confirm = Read-Host

if ($confirm -ne "CONFIRM") {
    Write-Host "CANCELLED"
    exit 0
}

$backup = Import-Csv $backupFile
$restored = 0
$failed = 0

foreach ($item in $backup) {
    try {
        $u = Get-MgUser -Filter "userPrincipalName eq '$($item.UserEmail)'" -ErrorAction Stop
        $g = Get-MgGroup -Filter "displayName eq '$($item.GroupName)'" -ErrorAction Stop
        New-MgGroupMember -GroupId $g.Id -DirectoryObjectId $u.Id -ErrorAction SilentlyContinue
        $restored++
    } catch {
        $failed++
    }
}

Write-Host "Restored: $restored | Failed: $failed"
Write-Host "Waiting 120 seconds for sync..."
Start-Sleep -Seconds 120

Write-Host "✓ Emergency restore complete"
Write-Host "NEXT: Contact Floor 6 Manager + Schedule RCA"
```

**After Restore:** Users regain full access (including unauthorized). **HALT further remediation.** Schedule post-incident review to correct authorized matters lookup table before re-attempting remediation.

---

## Preventive Controls (Strengthened)

**Six specific preventive controls to prevent recurrence, organized by process timing:**

---

### P-1: Pre-Deployment Smoke Test Gate (Pilot Migration)

**Who:** Release Engineer | **When:** 24 hours post-pilot deployment | **Automation:** Manual (checklist-driven)

**Pass/Fail Criteria:** Run migration script on 10-user pilot cohort → Verify 0 validation failures + group classification accuracy 100% | **If Fails:** Halt broad migration; fix script logic; retest on pilot before proceeding.

**Measurable Signal:** Script validation log must show: `✓ 0 classification errors detected`. Any error blocks progression.

**Action:** Execute `Migrate-OnPremGroupsToAzureAD.ps1` in DRY-RUN mode on pilot Floor 6 subset. Compare output to expected baseline (10 users × 2–3 matters each = 20–30 group assignments). If actual count differs by >10%, stop.

**Log Location:** `\\finbridge\logs\migrations\pilot-run-[date]\migration-validation.log`

[REQUIRES: Case Management System API must be accessible; script validation function built-in]

---

### P-2: Migration Script Validation & Classification Gate (Pre-Deployment)

**Who:** DWP Engineer | **When:** Before broad migration (production) | **Automation:** Automated within script

**Pass/Fail Criteria:** Script detects notification vs. access-control groups; blocks auto-assignment for ALLUSERS pattern; requires manual approval ticket | **If Fails:** Migration halts with error message; ticket escalated to Change Manager.

**Measurable Signal:** Validation log line: `"BLOCKED: Group FLOOR6-LEGAL-ALLUSERS requires manual classification approval (ticket #[ID])"`. 0 blocked groups = data quality issue. >0 blocked groups = normal flow.

**Action:** Modify `\\finbridge\scripts\migrations\Migrate-OnPremGroupsToAzureAD.ps1` (lines 156–187) to classify groups and block suspicious patterns:
```powershell
IF ($group.Name -match 'ALLUSERS|NOTIFICATION') {
    $approvalTicket = New-ApprovalTicket -GroupName $group.Name -Type "ReviewRequired"
    Wait-ManualApproval -TicketId $approvalTicket
}
```

**Expected Validation Output:**
```
✓ Classification gate passed
  - Notification groups found: 3 (require manual review)
  - Access-control groups found: 45 (auto-migrate with Case DB lookup)
  - Unclassified groups: 0 (PASS)
Proceed to step 2.
```

[REQUIRES: Change Management ticketing system; manual approval workflow]

---

### P-3: Post-Migration Daily Access Audit (Days 1–5)

**Who:** Access Control Team Lead | **When:** 1–5 days post-migration, automated daily 6 AM | **Automation:** Fully automated PowerShell scheduled task

**Pass/Fail Criteria:** Audit compares pre-migration baseline vs. post-migration groups for all users. Expected: 0 anomalies detected (100% match). Actual: If >0 anomalies, create HIGH ticket within 60 minutes.

**Measurable Signal:** Audit log entry: `"Anomalies detected: 0 users"` = PASS. Entry: `"Anomalies detected: 45 users"` = FAIL → Escalate immediately.

**Action:** Scheduled task: `C:\automation\daily-access-audit.ps1` (runs 6 AM daily, captures to `\\finbridge\compliance\daily-access-audits\access-audit-[YYYYMMDD].csv`). Compares expected Matter count per user vs. actual count.

**Alert Threshold:** If ANY user's actual count > expected count by 5 or more groups → Create ServiceNow ticket "ACCESS_ANOMALY_POST_MIGRATION" with CSV attachment.

**Pass Confirmation:** Audit log shows zero anomalies for 5 consecutive days = migration successful.

[REQUIRES: Pre-migration baseline CSV (generated before script runs); ServiceNow/Jira API integration]

---

### P-4: Real-Time Suspicious Group Membership Alert (Continuous)

**Who:** Security Operations Team | **When:** Continuous (active during and after migration window) | **Automation:** Fully automated Azure Sentinel alert

**Pass/Fail Criteria:** Alert triggers if 5+ users added to ANY single Matter-* group in 1-hour window (abnormal pattern). Trigger threshold = 5 users/hour. Baseline threshold = 0–2 users/hour (normal).

**Measurable Signal:** Azure Sentinel alert fires → ServiceNow ticket created with severity HIGH. Alert name: "BULK_ACCESS_GROUP_ADD_DETECTED". Incident counts: 0 during normal ops, >0 during migration (expected but monitored).

**Action:** Configure Azure Sentinel KQL rule:
```kusto
AuditLogs
| where TimeGenerated > ago(1h)
| where ActivityDisplayName == "Add member to group" and TargetResources[0].displayName startswith "Matter-"
| summarize UserCount = dcount(tostring(TargetResources[0].modifiedProperties[0].newValue)) 
           by TargetResources[0].displayName
| where UserCount > 5
```

**Failure Response:** If alert triggers outside migration window (post-close), escalate to incident response immediately (indicates unauthorized script execution or privilege abuse).

**Post-Migration Threshold:** Should drop to 0 alerts. If anomalies continue after migration closes, investigate.

[REQUIRES: Azure Sentinel licensing; automated incident response integration (ServiceNow API)]

---

### P-5: Case Management System Integration for Authorized Matters (Before Next Migration)

**Who:** Infrastructure/Database Team | **When:** Before next cohort migration (implement by Sept 30, 2026) | **Automation:** Automated API queries within migration script

**Pass/Fail Criteria:** API integration successfully queries Case DB for each user's authorized matters. Validation: API results match manual lookup 100%. If API unavailable, migration blocks with fallback requirement (manual lookup).

**Measurable Signal:** Pre-migration test report shows: `"Case DB API validation: 45 users × 100% match. PASS: Ready for production."` If mismatch >1%, fail and retest.

**Action:** Modify script to call Case DB API instead of static CSV:
```powershell
$authorizedMatters = Invoke-RestMethod -Uri "https://casedb.finbridge.com/api/users/$userEmail/authorized-matters"
```

**Dry-Run Validation:** Before production migration, run script in DRY-RUN mode comparing API output to manual lookup CSV. Must match 100%.

[REQUIRES: Case Management System REST API (endpoint, authentication, rate limits); API timeout policy; fallback manual review process if API fails]

---

### P-6: Runbook & Knowledge Base Update (Post-Closure)

**Who:** DWP Knowledge Manager / Change Manager | **When:** Within 48 hours of incident closure | **Automation:** Manual (knowledge base management)

**Pass/Fail Criteria:** Update 3 artifacts: (1) Runbook, (2) L1 KB article, (3) L2 troubleshooting guide. Versioning: Increment to v1.1. All changes documented with incident ticket reference.

**Measurable Signal:** Artifacts updated in knowledge base system with timestamp and incident reference. Search for "Floor 6 access control" returns updated articles. Previous version marked "SUPERSEDED BY v1.1 [DATE]".

**Action:** 
1. Update runbook-floor6-access-remediation-final.md → Add lessons learned section
2. Update kb-l1-floor6-access-self-service.md → Add new symptom pattern (bulk Matter visibility)
3. Update kb-l2-floor6-access-misconfiguration.md → Add this preventive control section as reference
4. Add new section to change management process: "Access Control Audits Pre-Migration" (links to P-1, P-2, P-3)

**Verification:** Knowledge base search shows new articles on day 2 post-incident. Training deck for next cohort migration includes link to this KB.

[REQUIRES: Knowledge management system update workflow; change management training checklist update]

---

### Preventive Control Summary Matrix

| Control | Owner | Timing | Pass/Fail | Signal | Automation | Dependency |
|---------|-------|--------|-----------|--------|------------|------------|
| **P-1** | Release Eng | Pre-migration | 0 validation errors | Script log line | Manual + automated checks | Pilot cohort access |
| **P-2** | DWP Engineer | Pre-migration | 0 blocked groups OR manual approvals | Classification gate log | Automated script + manual approval | Change Management tickets |
| **P-3** | Access Control Lead | Post-migration (Days 1–5) | 0 anomalies | Daily audit CSV | Fully automated (scheduled task) | Pre-migration baseline CSV |
| **P-4** | Security Ops | Continuous (during/after migration) | Alert count = baseline (0–1) | Azure Sentinel alert fired | Fully automated alert | Azure Sentinel + ServiceNow |
| **P-5** | Infrastructure/DB Team | Before next migration (by Sept 30) | API match = 100% to manual | DRY-RUN validation report | Automated API + manual DRY-RUN | Case DB REST API + fallback |
| **P-6** | Knowledge Manager | Post-closure (within 48h) | Artifacts v1.1 published | KB search returns new version | Manual + automated workflow | Knowledge management system |

---

### Preventive Control Dependencies & Risks

**P-1 Blocker:** Requires pilot cohort to complete migration 24 hours early. **Mitigation:** Schedule pilot 1 week prior to broad deployment.

**P-2 Blocker:** Change Management ticketing system may have approval delays. **Mitigation:** Pre-approve classification review process; assign escalation owner.

**P-3 Blocker:** Pre-migration baseline CSV must be generated before script runs. **Mitigation:** Build baseline export into pre-flight checklist (Step 0 of migration).

**P-4 Blocker:** Azure Sentinel not available in all tenants. **Mitigation:** [REQUIRES: Azure Sentinel licensing or alternative monitoring tool]; fallback to daily manual audit if Sentinel unavailable.

**P-5 Blocker:** Case DB REST API may not exist. **Mitigation:** [REQUIRES: Case Management System API development (backlog item)]; use manual lookup CSV until API ready.

**P-6 Blocker:** Knowledge base system permissions. **Mitigation:** Assign Knowledge Manager update rights in KB system before incident closure.

---

### Target Completion Timeline

- **P-1 + P-2:** Complete by Sept 15, 2026 (before next scheduled migration)
- **P-3:** Complete by Sept 8, 2026 (critical monitoring)
- **P-4:** Complete by Sept 15, 2026 (depends on Azure Sentinel licensing approval)
- **P-5:** Complete by Sept 30, 2026 (API development cycle; backlog sprint 2)
- **P-6:** Complete within 48 hours of incident closure (Aug 16, 2026)

---

## Related

**Other Incidents / KB Articles:**

| Incident | Relation | KB Article | Status |
|----------|----------|-----------|--------|
| **Outlook Startup Delay — Q2 2024** | Same cohort (Floor 6); similar post-migration timing; detected days after deployment | KB-OUTLOOK-STARTUP-DELAY-20240415 | CLOSED |
| **Win10→Win11 Migration — Other Departments** | Same root pattern (migration script logic error); affects other departments currently migrating | KB-WIN11-MIGRATION-GUIDE | ACTIVE |
| **SharePoint Permission Misconfiguration — 2024** | Similar access control issue; different root cause (missing permission audit post-deployment) | KB-SHAREPOINT-PERMISSIONS-AUDIT | CLOSED |
| **DLP Policy Violation — 2025-Q1** | Related: Unauthorized data visibility; prevented by proper access controls | KB-DLP-ENFORCEMENT | ACTIVE |

**Escalation Path (If Incident Recurs):**
- Level 1: Service Desk → Use Detection Steps D-1 through D-6
- Level 2: Access Control Team → Use Resolution Steps R-1 through R-5
- Level 3: Azure AD Team → Validate root cause via Azure audit logs
- Level 4: Security/Compliance → Post-incident review of preventive controls

---

**Document Metadata:**

| Field | Value |
|-------|-------|
| Author | DWP Incident Response |
| Created | 14/08/2026 |
| Last Modified | 14/08/2026 |
| Review Date | 14/11/2026 |
| Classification | Internal Use |
| Related Runbook | runbook-floor6-access-remediation-final.md |
| Related RCA | rca-floor6-data-access-incident-final.md |
