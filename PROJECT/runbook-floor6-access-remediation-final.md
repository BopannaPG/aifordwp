---
# Runbook: Remediate Unauthorized Matter-Access Group Membership Post-Migration

**Version Header:**
| Field | Value |
|-------|-------|
| **Title** | Floor 6 Legal — Access Control Remediation Runbook |
| **Version** | 1.0 |
| **Date** | 14/08/2026 |
| **Author** | Bopanna |
| **Reviewed** | Self |
| **Status** | Draft |
| **Change** | Initial version converted from RCA-floor6-data-access-incident-final.md |

---

**Quick Reference:**
| Attribute | Value |
|-----------|-------|
| **Incident Type** | Access Control Misconfiguration |
| **Affected Cohort** | Floor 6 Legal (45 users) |
| **Root Cause** | Migration script added all Floor 6 users to unauthorized matter-access security groups |
| **Detection Signal** | User reports seeing confidential client matter in Copilot without claimed access |
| **Time to Execute** | 35 minutes (including Azure AD sync wait) |
| **Difficulty** | Intermediate (requires Azure AD PowerShell and permission understanding) |
| **Last Updated** | 14/08/2026 |  

---

## 1. Prerequisites — Complete Pre-Execution Checklist

⚠️ **DO NOT PROCEED BEYOND THIS SECTION UNTIL ALL CHECKBOXES ARE COMPLETED**

### Section 1A: Access Rights Verification ⚠️ *Required Role*

**Checkpoint 1A-1: Verify User Administrator Role**
- [ ] Open: https://portal.azure.com (login if prompted)
- [ ] Navigate: **Azure Active Directory** (left sidebar) → **Roles and administrators** (under "Manage" section)
  - *If sidebar not visible: Click **≡** (three lines) in top-left corner*
- [ ] In search box labeled "Search by role name": Type **"User Administrator"**
- [ ] Click on **"User Administrator"** result (blue link)
- [ ] You should see a list of members. **LOOK FOR YOUR NAME/EMAIL in this list**
  - **Status:** ✓ PASS if your name appears | ✗ FAIL if your name NOT in list
- [ ] **If FAIL:** Contact your manager. You need "User Administrator" role before proceeding. STOP.
- [ ] **If PASS:** Check box and proceed to 1A-2.

**Checkpoint 1A-2: Verify Global Reader OR Audit Log Reader Role (for Step 1.4 audit logs)**
- [ ] In same **Roles and administrators** page, search for **"Global Reader"**
- [ ] Click result and look for your name
  - **Status:** ✓ PASS if found | ⚠ WARN if not found (you can still proceed; you just won't see full audit logs)
- [ ] If not found, try search for **"Audit Log Reader"** instead
- [ ] Check box if you have at least one of these roles

**Checkpoint 1A-3: Test PowerShell Permissions Before Starting Procedure**
- [ ] Open **PowerShell** on your workstation
  - How to find: Right-click desktop or Start menu → "Windows PowerShell" or "PowerShell 5.1" OR search Start menu for "PowerShell"
  - ⚠️ **IMPORTANT:** Do NOT use "PowerShell ISE" for this runbook; use regular PowerShell console
- [ ] Copy-paste this command and press ENTER:
  ```powershell
  Connect-MgGraph -Scopes "DirectoryManagement.ReadWrite.All" -ErrorAction Stop
  ```
- [ ] You will see a **browser pop-up login window**. Sign in with your work email.
- [ ] After login, return to PowerShell console.
- [ ] **Expected output:** Console should show your email and tenant ID (e.g., "contoso.onmicrosoft.com")
- [ ] **If error appears:** STOP. Contact Azure AD team. Do NOT proceed.
- [ ] Check box if test successful.

---

### Section 1B: Tools & Environment Setup

**Checkpoint 1B-1: PowerShell Version**
- [ ] Open **PowerShell** console
- [ ] Type: `$PSVersionTable.PSVersion` and press ENTER
- [ ] Look for line showing version (e.g., "Major 5" or "Major 7")
- [ ] **Status:** ✓ PASS if version 5 or higher | ✗ FAIL if lower than 5
- [ ] Check box if version is 5 or higher

**Checkpoint 1B-2: Microsoft Graph PowerShell Module**
- [ ] In **PowerShell** console, type: `Get-Module Microsoft.Graph -ListAvailable` and press ENTER
- [ ] **If module appears in results:** ✓ PASS — skip to 1B-3
- [ ] **If blank result (no module found):**
  - Type: `Install-Module Microsoft.Graph -Force -Scope CurrentUser -ErrorAction Stop` and press ENTER
  - Wait 2-3 minutes for installation
  - When done, type: `Get-Module Microsoft.Graph -ListAvailable` again
  - Should now show module installed
- [ ] Check box when module is installed

**Checkpoint 1B-3: Verify Log Directory Exists**
- [ ] Open **File Explorer** (Windows + E key)
- [ ] Navigate to: `C:\temp\`
- [ ] **If folder exists:** ✓ PASS — proceed to next
- [ ] **If folder does NOT exist:**
  - Right-click in empty area → **New** → **Folder**
  - Name it: `temp`
  - Double-click to enter folder
- [ ] Check box when C:\temp\ folder verified/created

**Checkpoint 1B-4: Create Working Directory for This Incident**
- [ ] Open **PowerShell** console
- [ ] Type: `mkdir C:\temp\floor6-remediation-$(Get-Date -Format 'yyyyMMdd-HHmm')` and press ENTER
- [ ] This creates a timestamped folder like: `C:\temp\floor6-remediation-20260814-0945\`
- [ ] **Document this folder path:** ____________________
  - You will save all reports and logs here
- [ ] Check box when folder created

---

### Section 1C: Mandatory Information from Business — MUST GATHER BEFORE STARTING

**Checkpoint 1C-1: Case Assignment Matrix (CRITICAL)**

⚠️ **This is the MOST IMPORTANT information. Incorrect data here causes remediation failures.**

- [ ] Contact: **Floor 6 Legal Department Manager**
  - Name: ____________________
  - Phone: ____________________
  - Email: ____________________
- [ ] Ask them: **"For each paralegal, which client matters should they have access to?"**
- [ ] Request: **CSV file or spreadsheet with columns:**
  ```
  ParalegalName | ParalegalEmail | AuthorizedMatter1 | AuthorizedMatter2 | AuthorizedMatter3
  Example:
  John Smith | john.smith@finbridge.com | Matter-CompanyA-Contract-2026 | Matter-CompanyB-Litigation-2024 | 
  Jane Doe | jane.doe@finbridge.com | Matter-CompanyC-IPTransfer-2025 | |
  ```
- [ ] Save this file to: `C:\temp\floor6-remediation-[timestamp]\authorized-matters-matrix.csv`
- [ ] **Verification:** Open file in Notepad; check that it contains:
  - ✓ At least 40+ rows (Floor 6 has 45 users)
  - ✓ Email addresses in consistent format (all lowercase, @finbridge.com domain)
  - ✓ Matter names starting with "Matter-" prefix
- [ ] Check box when file verified

**Checkpoint 1C-2: Pre-Migration Baseline (if available — OPTIONAL but HELPFUL)**

- [ ] Ask Floor 6 manager: **"Do you have a report of who had access to which matters BEFORE the Win11 migration?"**
- [ ] **If YES:** Request the file and save to: `C:\temp\floor6-remediation-[timestamp]\baseline-premigration.csv`
- [ ] **If NO:** Note "Baseline unavailable" — you can still proceed; just makes verification harder
- [ ] Check box when addressed (either file obtained or marked unavailable)

**Checkpoint 1C-3: Migration Completion Date**

- [ ] Ask Floor 6 manager OR check with Infrastructure team: **"When did Floor 6's Windows 11 migration complete?"**
- [ ] Write date here: ____________________
- [ ] This helps correlate group membership changes in audit logs
- [ ] Check box when date documented

**Checkpoint 1C-4: Floor 6 Group Name Confirmation**

- [ ] Confirm: The Floor 6 security group name in Azure AD is exactly: **"Floor6-Legal"**
  - If different name (e.g., "Floor6-LegalDept" or "Legal-Floor6"), note the correct name: ____________________
- [ ] Check box

---

### Section 1D: Final Go/No-Go Decision

**All checkboxes complete?**

- [ ] **If YES to all:** ✓ **YOU ARE READY TO PROCEED TO SECTION 2 (PROCEDURE)**
- [ ] **If NO to any:** ✗ **STOP. Do not proceed. Resolve the failed checkpoint first, then return here.**

**Final confirmation:**
- [ ] I have User Administrator role verified
- [ ] I have tested PowerShell connectivity successfully  
- [ ] I have the case assignment matrix file saved
- [ ] I have confirmed Floor 6 group name
- [ ] I have created working directory: `C:\temp\floor6-remediation-[timestamp]\`

**Incident start time:** ____________________  
**Engineer name:** ____________________

---

## 2. Procedure

⚠️ **BEFORE STARTING:** Confirm all checkboxes in Section 1 are complete. If not, STOP and complete Prerequisites first.

### PHASE 1: Identify Unauthorized Groups (5 minutes)

**Step 1.1: Open PowerShell Console and Connect to Azure AD** ⚠️ *Requires User Administrator role*

1. Open **PowerShell** console:
   - Windows key + X → Select **"Windows PowerShell"** (NOT PowerShell ISE)
   - OR: Search Start menu for "PowerShell" → Click "Windows PowerShell"
   - Wait for blue PowerShell window to open

2. In PowerShell console, type this command and press ENTER:
   ```powershell
   Connect-MgGraph -Scopes "DirectoryManagement.ReadWrite.All" -ErrorAction Stop
   ```

3. A **browser window** will pop up asking you to sign in:
   - Sign in with your work email/password
   - You may see "Permissions requested" — click **Accept**
   - Return to PowerShell window (browser may close automatically)

4. In PowerShell console, you should see:
   ```
   Connected as: yourname@finbridge.com
   Tenant: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

**Expected Result:** PowerShell shows connection confirmed. If you see an ERROR → STOP. Contact Azure AD team for permissions.

**Log location for this step:** Not logged (connection only)

---

**Step 1.2: Create Log File for This Remediation**

1. In same PowerShell console, copy-paste this command and press ENTER:
   ```powershell
   $logFolder = "C:\temp\floor6-remediation-$(Get-Date -Format 'yyyyMMdd-HHmm')"
   $logFile = "$logFolder\remediation-$(Get-Date -Format 'yyyyMMdd-HHmm-ss').log"
   New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
   New-Item -Path $logFile -ItemType File -Force | Out-Null
   
   Write-Host "Log file created: $logFile"
   Add-Content -Path $logFile -Value "Floor 6 Access Remediation Log"
   Add-Content -Path $logFile -Value "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
   Add-Content -Path $logFile -Value "Engineer: $env:USERNAME"
   Add-Content -Path $logFile -Value "---"
   ```

2. PowerShell will display something like:
   ```
   Log file created: C:\temp\floor6-remediation-20260814-0950\remediation-20260814-095034.log
   ```

3. **IMPORTANT:** Copy the log file path displayed and **SAVE IT** — you'll need this throughout the runbook:
   - **My log file path:** ________________________________________________

**Expected Result:** Log file created successfully. Path displayed in PowerShell console.

**Log location for this step:** `C:\temp\floor6-remediation-[YYYYMMDD-HHMM]\remediation-[timestamp].log`

---

**Step 1.3: Retrieve Floor 6 Legal Group From Azure AD**

1. In PowerShell console, copy-paste this and press ENTER:
   ```powershell
   $floor6Group = Get-MgGroup -Filter "displayName eq 'Floor6-Legal'" -ErrorAction Stop
   
   if (-not $floor6Group) {
       Write-Host "ERROR: Floor6-Legal group not found."
       Write-Host "Check Azure AD manually: https://portal.azure.com > Azure AD > Groups"
       exit 1
   }
   
   Write-Host "✓ Found group: $($floor6Group.DisplayName)"
   Write-Host "  Group ID: $($floor6Group.Id)"
   
   Add-Content -Path $logFile -Value "Step 1.3: Retrieved Floor6-Legal group. ID: $($floor6Group.Id)"
   ```

2. PowerShell output should show:
   ```
   ✓ Found group: Floor6-Legal
     Group ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

**Expected Result:** Group found successfully. If ERROR: STOP and verify group name in Azure AD portal (https://portal.azure.com > Azure AD > Groups > search "Floor6").

**Log location:** Added to `$logFile` (your log path from Step 1.2)

---

**Step 1.4: Export All Floor 6 Users to CSV File**

1. In PowerShell console, copy-paste this and press ENTER:
   ```powershell
   Write-Host "Retrieving all Floor 6 Legal members..."
   $floor6Users = Get-MgGroupMember -GroupId $floor6Group.Id -All -ErrorAction Stop
   
   Write-Host "✓ Retrieved $($floor6Users.Count) Floor 6 members"
   
   # Export to CSV for reference
   $csvPath = "$logFolder\floor6-users-list.csv"
   $floor6Users | Select-Object DisplayName, UserPrincipalName, Id | Export-Csv -Path $csvPath -NoTypeInformation
   
   Write-Host "  Exported to: $csvPath"
   Add-Content -Path $logFile -Value "Step 1.4: Retrieved $($floor6Users.Count) Floor 6 users. Exported to: $csvPath"
   ```

2. PowerShell output should show:
   ```
   ✓ Retrieved 45 Floor 6 members
     Exported to: C:\temp\floor6-remediation-20260814-0950\floor6-users-list.csv
   ```

3. To verify: Open **File Explorer** → Go to `C:\temp\floor6-remediation-[timestamp]\` → Double-click `floor6-users-list.csv` → Should see list of 45 users with emails

**Expected Result:** CSV file created with all 45 Floor 6 users. If count is 0 or much lower than 45, stop and verify group membership in Azure portal.

**Log location:** `$logFolder\floor6-users-list.csv` (file path shown in PowerShell output)

---

**Step 1.5: Load Authorized Matters Matrix into PowerShell**

1. In PowerShell console, copy-paste this and press ENTER:
   ```powershell
   # Load the authorized matters CSV you prepared in Prerequisites (Section 1C-1)
   $csvMatrixPath = "C:\temp\floor6-remediation-20260814-0950\authorized-matters-matrix.csv"  # UPDATE THIS PATH
   
   Write-Host "Loading authorized matters matrix from: $csvMatrixPath"
   $matrixData = Import-Csv -Path $csvMatrixPath -ErrorAction Stop
   
   Write-Host "✓ Loaded authorized matters for $($matrixData.Count) users"
   
   # Convert to hashtable for faster lookup during removal phase
   $authorizedMatters = @{}
   foreach ($row in $matrixData) {
       $email = $row.ParalegalEmail.Trim()
       $matters = @(
           $row.AuthorizedMatter1,
           $row.AuthorizedMatter2,
           $row.AuthorizedMatter3,
           $row.AuthorizedMatter4,
           $row.AuthorizedMatter5
       ) | Where-Object { $_ -and $_.Trim() -ne "" }  # Remove empty entries
       
       $authorizedMatters[$email] = $matters
   }
   
   Write-Host "✓ Converted to lookup table"
   Add-Content -Path $logFile -Value "Step 1.5: Loaded authorized matters matrix. $($authorizedMatters.Count) users defined"
   ```

2. PowerShell output should show:
   ```
   ✓ Loaded authorized matters for 45 users
   ✓ Converted to lookup table
   ```

⚠️ **CRITICAL:** Update the `$csvMatrixPath` in the command above to match YOUR actual file path from Prerequisites. If path is wrong, this step will ERROR.

**Expected Result:** Authorization matrix loaded successfully. If error about file not found: verify the file path is correct and file exists.

**Log location:** Added to main log file
---

**Step 1.6: Generate Report of Unauthorized Group Memberships**

1. In PowerShell console, copy-paste this command and press ENTER:
   ```powershell
   Write-Host "Scanning each Floor 6 user for unauthorized Matter-* groups..."
   Write-Host "This may take 2-3 minutes..."
   
   $unauthorizedReport = @()
   $userCount = 0
   
   foreach ($user in $floor6Users) {
       $userCount++
       Write-Progress -Activity "Scanning user groups" -CurrentOperation $user.DisplayName -PercentComplete (($userCount / $floor6Users.Count) * 100)
       
       $userEmail = $user.UserPrincipalName
       
       # Get all groups this user belongs to (Query Azure AD)
       try {
           $userGroups = Get-MgUserMemberOf -UserId $user.Id -All -ErrorAction Stop
       } catch {
           Write-Host "WARNING: Could not retrieve groups for $userEmail. Skipping."
           Add-Content -Path $logFile -Value "Step 1.6: ERROR retrieving groups for $userEmail - $($_.Exception.Message)"
           continue
       }
       
       # Filter to only Matter-* groups (these are access-control groups)
       $matterGroups = $userGroups | Where-Object { $_.DisplayName -match '^Matter-' }
       
       # Check against authorized list
       $authorizedForUser = $authorizedMatters[$userEmail]
       
       if (-not $authorizedForUser) {
           Write-Host "WARNING: No authorized matters defined for $userEmail"
           Add-Content -Path $logFile -Value "Step 1.6: WARNING - No authorized matters found for $userEmail"
           continue
       }
       
       # Identify unauthorized groups
       $unauthorizedGroups = $matterGroups | Where-Object { $_.DisplayName -notin $authorizedForUser }
       
       # Add to report
       foreach ($group in $unauthorizedGroups) {
           $unauthorizedReport += [PSCustomObject]@{
               UserEmail = $userEmail
               UserName = $user.DisplayName
               UnauthorizedGroupName = $group.DisplayName
               GroupId = $group.Id
               UserId = $user.Id
           }
       }
   }
   
   Write-Progress -Completed
   
   Write-Host "✓ Scan complete"
   Write-Host "  Found $($unauthorizedReport.Count) unauthorized group memberships"
   Write-Host "  Affecting $($unauthorizedReport.UserEmail | Select-Object -Unique | Measure-Object).Count user(s)"
   
   # Export report to CSV for reference
   $reportPath = "$logFolder\unauthorized-groups-report.csv"
   $unauthorizedReport | Export-Csv -Path $reportPath -NoTypeInformation
   
   Write-Host "  Detailed report: $reportPath"
   Add-Content -Path $logFile -Value "Step 1.6: Scan found $($unauthorizedReport.Count) unauthorized memberships. Report: $reportPath"
   
   # Display summary by user
   Write-Host ""
   Write-Host "Summary by user:"
   $unauthorizedReport | Group-Object UserEmail | ForEach-Object {
       Write-Host "  $($_.Name): $($_.Count) unauthorized groups"
       foreach ($item in $_.Group) {
           Write-Host "    - $($item.UnauthorizedGroupName)"
       }
   }
   ```

2. PowerShell will show progress bar, then display results like:
   ```
   ✓ Scan complete
     Found 14 unauthorized group memberships
     Affecting 1 user(s)
   Detailed report: C:\temp\floor6-remediation-20260814-0950\unauthorized-groups-report.csv
   
   Summary by user:
     jane.doe@finbridge.com: 14 unauthorized groups
       - Matter-CompanyD-MandatoryVendor-2026
       - Matter-CompanyE-Litigation-2024
       ...
   ```

3. **Check the report CSV file:**
   - Open File Explorer → Go to your log folder (C:\temp\floor6-remediation-[timestamp]\)
   - Double-click: `unauthorized-groups-report.csv`
   - You should see table with columns: UserEmail | UserName | UnauthorizedGroupName | GroupId | UserId

**Expected Result:** Report created with list of unauthorized groups. If `$unauthorizedReport` count is 0 → **NO REMEDIATION NEEDED** → Skip to Step 3.1 (verification/closure).

**Log location:** `$logFolder\unauthorized-groups-report.csv`

---

### PHASE 2: Remove Users from Unauthorized Groups (8 minutes)

⚠️ **HIGH-RISK PHASE** — Actions here are permanent until rollback. Read carefully.

**Step 2.1: Review and Confirm Removal List**

1. In PowerShell console, copy-paste this and press ENTER:
   ```powershell
   Write-Host "======================================"
   Write-Host "FINAL CONFIRMATION BEFORE REMOVALS"
   Write-Host "======================================"
   Write-Host ""
   Write-Host "You are about to REMOVE users from these groups:"
   Write-Host ""
   
   $unauthorizedReport | Group-Object UserEmail | ForEach-Object {
       Write-Host "User: $($_.Name)"
       foreach ($item in $_.Group) {
           Write-Host "  - REMOVE FROM: $($item.UnauthorizedGroupName)"
       }
       Write-Host ""
   }
   
   Write-Host "This action is PERMANENT until rollback."
   Write-Host "Users affected: $($unauthorizedReport.UserEmail | Select-Object -Unique | Measure-Object).Count"
   Write-Host "Groups to remove: $($unauthorizedReport.Count)"
   Write-Host ""
   Write-Host "⚠️ Type 'YES' to proceed, or anything else to CANCEL:"
   $confirmation = Read-Host
   
   if ($confirmation -ne "YES") {
       Write-Host "CANCELLED. No changes made."
       Add-Content -Path $logFile -Value "Step 2.1: User cancelled removal. No groups removed."
       exit 0
   }
   
   Write-Host "✓ Confirmation received. Proceeding with removals..."
   Add-Content -Path $logFile -Value "Step 2.1: User confirmed. Beginning removals at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
   ```

2. PowerShell displays all unauthorized groups and asks for confirmation. **Type "YES" (all caps) and press ENTER** to proceed, or anything else to CANCEL.

**Expected Result:** Confirmation captured. If you typed "YES", proceed to Step 2.2. If you typed anything else, script exits safely.

**Log location:** Added to main log file

---

**Step 2.2: Execute Removals** ⚠️ *This step removes users from groups*

1. In PowerShell console, copy-paste this command and press ENTER:
   ```powershell
   Write-Host "Starting removals at $(Get-Date -Format 'HH:mm:ss')..."
   Write-Host ""
   
   $removalResults = @()
   $successCount = 0
   $failureCount = 0
   
   foreach ($item in $unauthorizedReport) {
       try {
           # This command removes user ($item.UserId) from group ($item.GroupId)
           Remove-MgGroupMember -GroupId $item.GroupId -DirectoryObjectId $item.UserId -ErrorAction Stop
           
           $successCount++
           Write-Host "✓ [$successCount] Removed: $($item.UserEmail) FROM $($item.UnauthorizedGroupName)"
           Add-Content -Path $logFile -Value "$(Get-Date -Format 'HH:mm:ss') | SUCCESS | $($item.UserEmail) removed from $($item.UnauthorizedGroupName)"
           
       } catch {
           $failureCount++
           $errorMsg = $_.Exception.Message
           Write-Host "✗ [$failureCount] FAILED: $($item.UserEmail) FROM $($item.UnauthorizedGroupName) - Error: $errorMsg"
           Add-Content -Path $logFile -Value "$(Get-Date -Format 'HH:mm:ss') | FAILED | $($item.UserEmail) - $errorMsg"
       }
   }
   
   Write-Host ""
   Write-Host "======== REMOVAL PHASE COMPLETE ========"
   Write-Host "Successful: $successCount"
   Write-Host "Failed: $failureCount"
   Write-Host "Total processed: $($unauthorizedReport.Count)"
   Write-Host ""
   
   Add-Content -Path $logFile -Value "Removal complete: $successCount successful, $failureCount failed"
   
   if ($failureCount -gt 0) {
       Write-Host "⚠️ ATTENTION: Some removals failed. See above for details."
       Write-Host "Failed removals must be completed manually or investigated."
   }
   ```

2. PowerShell displays each removal with ✓ or ✗ indicator. Example output:
   ```
   ✓ [1] Removed: jane.doe@finbridge.com FROM Matter-CompanyD-MandatoryVendor-2026
   ✓ [2] Removed: jane.doe@finbridge.com FROM Matter-CompanyE-Litigation-2024
   ...
   ======== REMOVAL PHASE COMPLETE ========
   Successful: 14
   Failed: 0
   ```

**Expected Result:** All removals show ✓ (successful). If any show ✗ (failed) → Note the group names and users → You'll need to investigate why (may need to retry or check group permissions).

**Log location:** All actions logged to `$logFile` (your main log file from Step 1.2)

---

**Step 2.3: Wait for Azure AD Synchronization (5 minutes)**

1. In PowerShell console, copy-paste this and press ENTER:
   ```powershell
   Write-Host "⏳ Waiting 5 minutes for Azure AD to sync changes..."
   Write-Host "   (User removals from groups must propagate through Azure AD backend)"
   Write-Host "   DO NOT CLOSE POWERSHELL WINDOW OR INTERRUPT THIS WAIT"
   Write-Host ""
   
   $waitSeconds = 300
   $startTime = Get-Date
   
   for ($i = $waitSeconds; $i -gt 0; $i--) {
       $elapsed = (Get-Date) - $startTime
       Write-Progress -Activity "Azure AD Sync Wait" `
                      -Status "Time remaining: $i seconds" `
                      -PercentComplete (($waitSeconds - $i) / $waitSeconds * 100)
       Start-Sleep -Seconds 1
   }
   
   Write-Progress -Completed
   
   Write-Host "✓ 5-minute sync wait complete at $(Get-Date -Format 'HH:mm:ss')"
   Write-Host ""
   Add-Content -Path $logFile -Value "Step 2.3: Azure AD sync wait completed at $(Get-Date -Format 'HH:mm:ss')"
   ```

2. PowerShell displays progress bar. Wait for it to complete. Expected time: exactly 5 minutes.

3. When complete, PowerShell shows: `✓ 5-minute sync wait complete`

**Expected Result:** 5-minute wait completes without errors. Progress bar reaches 100%.

**Log location:** Added to main log file

---

### PHASE 3: Verification (5 minutes)

⚠️ **CRITICAL PHASE** — Verify removals worked before closing incident. Do NOT skip these steps.

**Step 3.1: Re-Query User Groups and Verify Removals** ⚠️ *Most critical verification step*

1. In PowerShell console, copy-paste this command and press ENTER:
   ```powershell
   Write-Host "Verifying that unauthorized groups have been removed..."
   Write-Host ""
   
   $verificationResults = @()
   $allPassed = $true
   
   foreach ($user in $floor6Users) {
       $userEmail = $user.UserPrincipalName
       $authorizedForUser = $authorizedMatters[$userEmail]
       
       # Skip users not in authorization matrix
       if (-not $authorizedForUser) {
           continue
       }
       
       # Query Azure AD for current group memberships
       try {
           $currentGroups = Get-MgUserMemberOf -UserId $user.Id -All -ErrorAction Stop
       } catch {
           Write-Host "WARNING: Could not query $userEmail. Skipping."
           continue
       }
       
       # Filter to Matter-* groups only
       $currentMatterGroups = $currentGroups | Where-Object { $_.DisplayName -match '^Matter-' }
       
       # Find authorized Matter-* groups for this user
       $authorizedGroupsForUser = $currentMatterGroups | Where-Object { $_.DisplayName -in $authorizedForUser }
       
       # Find ANY remaining unauthorized groups
       $unauthorizedRemaining = $currentMatterGroups | Where-Object { $_.DisplayName -notin $authorizedForUser }
       
       # Determine PASS/FAIL
       if ($unauthorizedRemaining.Count -eq 0) {
           $status = "✓ PASSED"
           Write-Host "$status - $userEmail"
           Write-Host "        Current authorized groups: $($authorizedGroupsForUser.Count)"
       } else {
           $status = "✗ FAILED"
           $allPassed = $false
           Write-Host "$status - $userEmail"
           Write-Host "        Still has $($unauthorizedRemaining.Count) unauthorized group(s):"
           foreach ($group in $unauthorizedRemaining) {
               Write-Host "          ✗ $($group.DisplayName)"
           }
       }
       
       Write-Host ""
       
       $verificationResults += [PSCustomObject]@{
           UserEmail = $userEmail
           Status = $status
           AuthorizedGroupsRemaining = $authorizedGroupsForUser.Count
           UnauthorizedGroupsRemaining = $unauthorizedRemaining.Count
       }
   }
   
   # Summary
   $passedCount = ($verificationResults | Where-Object { $_.Status -match "PASSED" }).Count
   $failedCount = ($verificationResults | Where-Object { $_.Status -match "FAILED" }).Count
   
   Write-Host "======== VERIFICATION SUMMARY ========"
   Write-Host "Users PASSED: $passedCount"
   Write-Host "Users FAILED: $failedCount"
   Write-Host ""
   
   if ($allPassed) {
       Write-Host "✓✓✓ ALL VERIFICATIONS PASSED ✓✓✓"
       Write-Host "Proceeding to Step 3.2 (manual Copilot test)"
   } else {
       Write-Host "✗✗✗ SOME VERIFICATIONS FAILED ✗✗✗"
       Write-Host "⚠️ DO NOT PROCEED. Execute Rollback Step 2 (re-add groups)"
   }
   
   Write-Host ""
   
   # Export verification results
   $verPath = "$logFolder\verification-results-step3.1.csv"
   $verificationResults | Export-Csv -Path $verPath -NoTypeInformation
   Write-Host "Verification results saved to: $verPath"
   
   Add-Content -Path $logFile -Value "Step 3.1: Verification complete - $passedCount passed, $failedCount failed"
   ```

2. PowerShell displays each user with ✓ PASSED or ✗ FAILED and shows summary. Example output:
   ```
   ✓ PASSED - jane.doe@finbridge.com
             Current authorized groups: 2
   
   ======== VERIFICATION SUMMARY ========
   Users PASSED: 45
   Users FAILED: 0
   
   ✓✓✓ ALL VERIFICATIONS PASSED ✓✓✓
   Verification results saved to: C:\temp\floor6-remediation-20260814-0950\verification-results-step3.1.csv
   ```

3. **Check the CSV file:**
   - Open File Explorer → Go to your log folder
   - Double-click: `verification-results-step3.1.csv`
   - You should see table with Status = "✓ PASSED" for all users

**Expected Result:** All users show "✓ PASSED". CSV file created. If any users show "✗ FAILED" → **STOP** and execute Rollback Step 2 before proceeding.

**Log location:** `$logFolder\verification-results-step3.1.csv`

---

**Step 3.2: Manual Copilot Access Test (Requires User Participation)**

1. **Coordinate with Floor 6 manager.** Provide these instructions to AT LEAST ONE affected user (the original reporter if possible):

   ```
   ======================== USER TEST INSTRUCTIONS ========================
   
   1. Sign out of Microsoft 365 completely (if logged in)
   
   2. Open: https://copilot.microsoft.com (in browser address bar)
   
   3. Sign in with your work email
   
   4. In Copilot search box, search for ONE of the client matters you should NOT have access to:
      - Example: "Matter-CompanyD-MandatoryVendor-2026"
      - Expected result: Matter should NOT appear in search results
      - If matter APPEARS: ✗ FAILED - Notify IT immediately
      - If matter does NOT appear: ✓ PASSED - Proceed to step 5
   
   5. Now search for ONE of your authorized client matters:
      - Example: "Matter-CompanyA-Contract-2026" (check with IT which matters you should see)
      - Expected result: Matter SHOULD appear and be clickable
      - If matter APPEARS: ✓ PASSED
      - If matter does NOT appear: ✗ FAILED - Notify IT immediately
   
   Report result to IT: jane.smith@finbridge.com ext.4357
   ========================================================================
   ```

2. Collect results from user test:
   ```powershell
   Write-Host "Ask Floor 6 user to test Copilot access:"
   Write-Host ""
   Write-Host "Test 1 - Unauthorized matter should NOT appear:"
   $test1 = Read-Host "  Did unauthorized matter appear? (YES/NO)"
   
   Write-Host ""
   Write-Host "Test 2 - Authorized matter SHOULD appear:"
   $test2 = Read-Host "  Did authorized matter appear? (YES/NO)"
   
   Write-Host ""
   if ($test1 -eq "NO" -and $test2 -eq "YES") {
       Write-Host "✓ Copilot test PASSED"
       Add-Content -Path $logFile -Value "Step 3.2: Manual Copilot test PASSED"
   } else {
       Write-Host "✗ Copilot test FAILED"
       Write-Host "  ✗ Unauthorized matter visible: $($test1 -eq 'YES')"
       Write-Host "  ✗ Authorized matter NOT visible: $($test2 -eq 'NO')"
       Write-Host "If either is true, execute Rollback Step 3"
       Add-Content -Path $logFile -Value "Step 3.2: Manual Copilot test FAILED"
   }
   ```

**Expected Result:** User confirms unauthorized matter no longer visible AND authorized matter still visible. Example:
   ```
   Did unauthorized matter appear? (YES/NO): NO
   Did authorized matter appear? (YES/NO): YES
   
   ✓ Copilot test PASSED
   ```

If either test fails → Execute Rollback Step 3.

**Log location:** Added to main log file

---

**Step 3.3: Check Service Desk Ticket Queue (Manual Check)**

1. Open **Service Desk/Ticket system** (contact location depends on your organization):
   - **If using Jira Service Desk:** https://finbridge.atlassian.net/servicedesk/customer/portals
   - **If using Zendesk:** https://finbridge.zendesk.com/agent/dashboard
   - **If using other system:** Contact your IT helpdesk for URL
   - Sign in if needed

2. Search for new tickets in **last 2 hours** from **Floor 6 Legal** with keywords:
   - "can't access"
   - "permission denied"
   - "matter not found"
   - "access denied"
   - "copilot"

3. **Expected result:** 0 new tickets matching above criteria

4. Document findings:
   ```powershell
   Write-Host "Manual check: Service Desk ticket queue"
   Write-Host "Search period: Last 2 hours"
   Write-Host "Assigned group: Floor 6 Legal"
   Write-Host ""
   $ticketCount = Read-Host "Number of NEW access-related tickets found (0 expected)"
   
   if ([int]$ticketCount -eq 0) {
       Write-Host "✓ Ticket check PASSED - No new access issues reported"
       Add-Content -Path $logFile -Value "Step 3.3: Service Desk check PASSED - 0 access-related tickets"
   } else {
       Write-Host "⚠️ $ticketCount new access tickets found. Review and escalate if needed."
       Add-Content -Path $logFile -Value "Step 3.3: Service Desk check ALERT - $ticketCount access-related tickets found"
   }
   ```

**Expected Result:** 0 new access-related tickets from Floor 6 in last 2 hours. If tickets found → Document ticket IDs and investigate before closing.

**Log location:** Ticket system URL (manual external system)
  - Location: C:\temp\floor6-access-remediation-[timestamp].log
  - Check: File shows all removals with SUCCESS or FAILED status

---

## 3. Verification Checklist

⚠️ **ALL verification checks must PASS before closing incident. If ANY check FAILS → Execute Rollback immediately.**

**Verification Log Location:** `$logFolder\verification-execution-[timestamp].log`

---

### V-1: Azure AD Verification (Automated)

**What:** Confirm all unauthorized groups successfully removed from Azure AD

**How to Execute (30 seconds):**

In PowerShell console, copy-paste:
```powershell
$v1LogFile = "$logFolder\V1-Azure-AD-verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$v1Status = "PASSED"

Write-Host "V-1: Azure AD Verification starting..."
Add-Content -Path $v1LogFile -Value "V-1 Azure AD Verification | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Add-Content -Path $v1LogFile -Value "---"

$v1FailedUsers = @()

foreach ($user in $floor6Users) {
    $userEmail = $user.UserPrincipalName
    $authorizedForUser = $authorizedMatters[$userEmail]
    
    if (-not $authorizedForUser) { continue }
    
    $currentMatterGroups = Get-MgUserMemberOf -UserId $user.Id -All -ErrorAction SilentlyContinue | 
                           Where-Object { $_.DisplayName -match '^Matter-' }
    $unauthorizedRemaining = $currentMatterGroups | 
                             Where-Object { $_.DisplayName -notin $authorizedForUser }
    
    if ($unauthorizedRemaining.Count -gt 0) {
        $v1Status = "FAILED"
        $v1FailedUsers += $userEmail
        Add-Content -Path $v1LogFile -Value "FAILED: $userEmail - Still has $($unauthorizedRemaining.Count) groups: $($unauthorizedRemaining.DisplayName -join '; ')"
    }
}

if ($v1Status -eq "PASSED") {
    Write-Host "✓ V-1 PASSED"
    Add-Content -Path $v1LogFile -Value "RESULT: PASSED - No unauthorized groups"
} else {
    Write-Host "✗ V-1 FAILED - $($v1FailedUsers.Count) user(s) still have unauthorized groups"
    Add-Content -Path $v1LogFile -Value "RESULT: FAILED - $($v1FailedUsers.Count) users affected"
}

Write-Host "Log: $v1LogFile"
Add-Content -Path $logFile -Value "V-1: $v1Status"
```

**V-1 Log File:** `$logFolder\V1-Azure-AD-verification-[timestamp].log`  
**Decision:** ✓ PASSED if log shows "RESULT: PASSED" | ✗ FAILED if shows "RESULT: FAILED" → Rollback Scenario 1

---

### V-2: Copilot Access Verification (2 minutes)

**What:** User confirms unauthorized matter hidden; authorized matter visible

**How to Execute:**

1. **Call affected user** (original reporter): Phone: ______________

2. **Give them these exact steps:**
   ```
   STEP 1: Open https://copilot.microsoft.com
   STEP 2: Sign out if already logged in, then sign in again
   STEP 3: Search for: "Matter-CompanyD-MandatoryVendor-2026"
           Report: Did it appear? (YES/NO)
   STEP 4: Clear search, search for: "Matter-CompanyA-Contract-2026"
           Report: Did it appear? (YES/NO)
   
   Tell IT engineer both answers
   ```

3. **Record result in PowerShell:**
   ```powershell
   $v2LogFile = "$logFolder\V2-Copilot-verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
   
   Write-Host "V-2: Copilot Test"
   $unauth = Read-Host "Did unauthorized matter appear? (YES/NO)"
   $auth = Read-Host "Did authorized matter appear? (YES/NO)"
   
   if ($unauth -eq "NO" -and $auth -eq "YES") {
       Write-Host "✓ V-2 PASSED"
       Add-Content -Path $v2LogFile -Value "RESULT: PASSED | Unauth hidden, Auth visible"
   } else {
       Write-Host "✗ V-2 FAILED - Unauth: $unauth (want NO), Auth: $auth (want YES)"
       Add-Content -Path $v2LogFile -Value "RESULT: FAILED | Unauth=$unauth, Auth=$auth"
   }
   
   Write-Host "Log: $v2LogFile"
   Add-Content -Path $logFile -Value "V-2: PASSED/FAILED"
   ```

**V-2 Log File:** `$logFolder\V2-Copilot-verification-[timestamp].log`  
**Decision:** ✓ PASSED if Unauth=NO AND Auth=YES | ✗ FAILED → Rollback Scenario 3

---

### V-3: Service Desk Queue Check (1 minute)

**What:** Confirm 0 new access complaints in last 2 hours

**How to Execute:**

1. **Open ticketing system:**
   - Jira: https://finbridge.atlassian.net/servicedesk/customer/portals
   - Zendesk: https://finbridge.zendesk.com/agent/dashboard

2. **Search:** Last 2 hours | Floor 6 Legal | Keywords: "access" OR "permission" OR "matter"

3. **In PowerShell:**
   ```powershell
   $v3LogFile = "$logFolder\V3-ServiceDesk-check-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
   
   Write-Host "V-3: Service Desk Check"
   $count = Read-Host "New access tickets found (type 0 for none)"
   
   if ($count -eq "0") {
       Write-Host "✓ V-3 PASSED"
       Add-Content -Path $v3LogFile -Value "RESULT: PASSED | 0 tickets"
   } else {
       Write-Host "⚠️ $count tickets found (may still proceed)"
       Add-Content -Path $v3LogFile -Value "RESULT: ALERT | $count tickets"
   }
   
   Write-Host "Log: $v3LogFile"
   Add-Content -Path $logFile -Value "V-3: Tickets=$count"
   ```

**V-3 Log File:** `$logFolder\V3-ServiceDesk-check-[timestamp].log`  
**Decision:** ✓ PASSED if 0 tickets | ⚠️ ALERT if tickets found (may still close but investigate)

---

### V-4: Audit Trail Check (30 seconds)

```powershell
$v4LogFile = "$logFolder\V4-Audit-Trail-check-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

Write-Host "V-4: Audit Trail Check"

if (Test-Path $logFile) {
    $lines = (Get-Content $logFile | Measure-Object -Line).Lines
    Write-Host "✓ V-4 PASSED - Main log exists ($lines lines)"
    Add-Content -Path $v4LogFile -Value "RESULT: PASSED | Log file: $logFile ($lines lines)"
} else {
    Write-Host "✗ V-4 FAILED - Log file missing"
    Add-Content -Path $v4LogFile -Value "RESULT: FAILED | Missing: $logFile"
}

Write-Host "Log: $v4LogFile"
Add-Content -Path $logFile -Value "V-4: $(if (Test-Path $logFile) {'PASSED'} else {'FAILED'})"
```

**V-4 Log File:** `$logFolder\V4-Audit-Trail-check-[timestamp].log`  
**Decision:** ✓ PASSED if log file exists | ✗ FAILED if missing

---

### Final Verification Gate (30 seconds)

```powershell
Write-Host ""
Write-Host "========== FINAL VERIFICATION GATE =========="
Write-Host ""

$v1 = if (Select-String "RESULT: PASSED" "$logFolder\V1-*.log" -ErrorAction SilentlyContinue) { "PASS" } else { "FAIL" }
$v2 = if (Select-String "RESULT: PASSED" "$logFolder\V2-*.log" -ErrorAction SilentlyContinue) { "PASS" } else { "FAIL" }
$v4 = if (Select-String "RESULT: PASSED" "$logFolder\V4-*.log" -ErrorAction SilentlyContinue) { "PASS" } else { "FAIL" }

Write-Host "V-1 (Azure AD):      $v1"
Write-Host "V-2 (Copilot):       $v2"
Write-Host "V-4 (Audit Trail):   $v4"
Write-Host ""

if ($v1 -eq "PASS" -and $v2 -eq "PASS" -and $v4 -eq "PASS") {
    Write-Host "✓✓✓ ALL VERIFICATIONS PASSED ✓✓✓"
    Write-Host ""
    Write-Host "CLOSE TICKET WITH COMMENT:"
    Write-Host "Floor 6 remediation complete. All unauthorized groups removed."
    Write-Host "Verification: Azure AD passed, Copilot test passed, audit trail logged."
    Write-Host "Log folder: $logFolder"
    Add-Content -Path $logFile -Value "INCIDENT COMPLETE - Ready to close"
} else {
    Write-Host "✗✗✗ VERIFICATION FAILED ✗✗✗"
    Write-Host ""
    if ($v1 -eq "FAIL") { Write-Host "Execute: Rollback Scenario 1" }
    if ($v2 -eq "FAIL") { Write-Host "Execute: Rollback Scenario 3" }
    if ($v4 -eq "FAIL") { Write-Host "Investigate: Log file location" }
    Add-Content -Path $logFile -Value "INCIDENT FAILED - Execute Rollback"
}
```

---

## 4. Rollback — 3-Minute Emergency Execution

⚠️ **Only execute if V-1, V-2, or V-4 verification FAILED. Must complete in under 3 minutes.**

---

### Rollback Scenario 1: Azure AD Verification Failed (Unauthorized Groups Remain)

**Trigger:** V-1 shows "RESULT: FAILED"

**Action (< 2 minutes):**

```powershell
# Quick re-attempt for failed users
$rb1Log = "$logFolder\RB1-Failed-Removal-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

$failedUsers = Import-Csv "$logFolder\V1-failed-users.csv"

Write-Host "RB1: Re-attempting removal for $($failedUsers.Count) user(s)..."
Add-Content -Path $rb1Log -Value "Rollback 1: Re-attempt removal | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

foreach ($user in $failedUsers) {
    foreach ($group in ($user.GroupNames -split '; ')) {
        try {
            $u = Get-MgUser -Filter "userPrincipalName eq '$($user.UserEmail)'" -ErrorAction Stop
            $g = Get-MgGroup -Filter "displayName eq '$group'" -ErrorAction Stop
            Remove-MgGroupMember -GroupId $g.Id -DirectoryObjectId $u.Id -Confirm:$false -ErrorAction Stop
            Write-Host "✓ Removed $($user.UserEmail) from $group"
            Add-Content -Path $rb1Log -Value "SUCCESS: $($user.UserEmail) from $group"
        } catch {
            Write-Host "✗ Failed: $($_.Exception.Message)"
            Add-Content -Path $rb1Log -Value "FAILED: $($user.UserEmail) from $group - $($_.Exception.Message)"
        }
    }
}

Write-Host "Wait 90 seconds for sync..."
Start-Sleep -Seconds 90

Write-Host "Re-running V-1 verification..."
Write-Host "If still fails: ESCALATE to Azure AD team"

Add-Content -Path $rb1Log -Value "Rollback 1 complete. May need manual escalation."
Write-Host "Log: $rb1Log"
```

**If still fails after 90 sec:** ESCALATE to Azure AD team with $rb1Log file

**Log Location:** `$logFolder\RB1-Failed-Removal-[timestamp].log`

---

### Rollback Scenario 2: User Lost Authorized Access (V-2 shows Authorized=NO)

**Trigger:** V-2 shows user cannot access authorized matter

**Action (< 1 minute):**

```powershell
$rb2Log = "$logFolder\RB2-Restore-Authorized-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

Write-Host "RB2: Restoring authorized access"
Write-Host "User email: " -NoNewline
$userEmail = Read-Host
Write-Host "Authorized matters (comma-separated): " -NoNewline
$authMatters = (Read-Host).Split(',') | ForEach-Object { $_.Trim() }

Add-Content -Path $rb2Log -Value "Rollback 2: Restore authorized access for $userEmail"

$u = Get-MgUser -Filter "userPrincipalName eq '$userEmail'" -ErrorAction Stop

foreach ($matter in $authMatters) {
    try {
        $g = Get-MgGroup -Filter "displayName eq '$matter'" -ErrorAction Stop
        New-MgGroupMember -GroupId $g.Id -DirectoryObjectId $u.Id -ErrorAction SilentlyContinue
        Write-Host "✓ Added to $matter"
        Add-Content -Path $rb2Log -Value "SUCCESS: Added to $matter"
    } catch {
        Write-Host "✗ Failed: $matter"
        Add-Content -Path $rb2Log -Value "FAILED: $matter"
    }
}

Write-Host "Wait 60 seconds for sync..."
Start-Sleep -Seconds 60

Write-Host "User can now access authorized matters in Copilot"
Add-Content -Path $rb2Log -Value "Rollback 2 complete"
Write-Host "Log: $rb2Log"
```

**Log Location:** `$logFolder\RB2-Restore-Authorized-[timestamp].log`

---

### Rollback Scenario 3: Copilot Search Cache Lag (V-2 shows Unauth=YES)

**Trigger:** V-2 shows unauthorized matter still visible

**Action (< 30 seconds, mostly waiting):**

```powershell
$rb3Log = "$logFolder\RB3-Copilot-Cache-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

Write-Host "RB3: Copilot Cache/Index Issue"
Write-Host ""
Write-Host "IMMEDIATE ACTION:"
Write-Host "1. Call user: 'Clear your browser cache for copilot.microsoft.com'"
Write-Host "2. User clears cache in browser settings"
Write-Host "3. User closes and reopens browser"
Write-Host "4. User retests in Copilot"
Write-Host ""
Write-Host "If still visible after 4 hours:"
Write-Host "   → Escalate to Microsoft 365 team (search permission bypass)"
Write-Host ""

Add-Content -Path $rb3Log -Value "Rollback 3: Copilot cache cleared by user"
Add-Content -Path $rb3Log -Value "If issue persists after 4 hours, escalate as search permission bypass"

Write-Host "Log: $rb3Log"
```

**Log Location:** `$logFolder\RB3-Copilot-Cache-[timestamp].log`

---

### Rollback Scenario 4: Mass Access Failure (5+ Tickets, Widespread Issues)

**Trigger:** Service Desk flooded with new "can't access my cases" tickets within 30 min of remediation

**Action (< 2 minutes, EMERGENCY):**

```powershell
$rb4Log = "$logFolder\RB4-Emergency-Rollback-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

Write-Host "⚠⚠⚠ EMERGENCY ROLLBACK ⚠⚠⚠"
Write-Host ""
Write-Host "File required: C:\temp\floor6-group-memberships-before-remediation.csv"

if (-not (Test-Path "C:\temp\floor6-group-memberships-before-remediation.csv")) {
    Write-Host "✗ ERROR: Backup file not found. CANNOT EXECUTE EMERGENCY ROLLBACK."
    Write-Host "ESCALATE TO: Manager + Azure AD team"
    Add-Content -Path $rb4Log -Value "FAILED: Backup file missing. Cannot restore."
    exit 1
}

Write-Host "This will UNDO all removals and restore to pre-remediation state."
Write-Host "Press Ctrl+C to CANCEL, or type 'CONFIRM' to proceed:"
$confirm = Read-Host

if ($confirm -ne "CONFIRM") {
    Write-Host "CANCELLED"
    exit 0
}

$backup = Import-Csv "C:\temp\floor6-group-memberships-before-remediation.csv" -ErrorAction Stop
$restored = 0
$failed = 0

Write-Host "Restoring $($backup.Count) memberships..."
Add-Content -Path $rb4Log -Value "Emergency rollback started: $($backup.Count) memberships to restore"

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
Write-Host "Wait 120 seconds for full sync..."
Start-Sleep -Seconds 120

Write-Host "✓ Emergency rollback complete"
Write-Host "NEXT: Contact Floor 6 manager + Schedule RCA"

Add-Content -Path $rb4Log -Value "Emergency rollback complete: $restored restored, $failed failed"
Write-Host "Log: $rb4Log"
```

**Backup File Required:** `C:\temp\floor6-group-memberships-before-remediation.csv`  
**Log Location:** `$logFolder\RB4-Emergency-Rollback-[timestamp].log`  
**After Completion:** ESCALATE to Manager + Azure AD team for investigation

---

### Quick Rollback Reference Card

| Scenario | Trigger | Action | Time |
|----------|---------|--------|------|
| **RB1** | V-1 FAILED | Re-attempt failed removals | 90 sec |
| **RB2** | V-2: Auth=NO | Re-add authorized groups | 60 sec |
| **RB3** | V-2: Unauth=YES | Clear Copilot cache (user) | 30 sec |
| **RB4** | 5+ tickets in 30 min | Restore all to pre-remediation | 120 sec |

**All rollbacks:** Check log file afterward. If log shows FAILED → Escalate to Azure AD team.

---

## 5. Notes

### Edge Cases

**Edge Case 1: User Not Found in Authorized Matters Lookup**
- **Symptom:** Step 1.4 shows "WARNING: No authorized matters defined for [user] in lookup table. Skipping."
- **Cause:** User missing from case assignment export
- **Resolution:** Get correct authorized matters from Floor 6 manager; manually add user to lookup table; re-run Step 1.4 for that user only

**Edge Case 2: Group Does Not Exist**
- **Symptom:** "ERROR: User or group not found" in removal step
- **Cause:** Group name misspelled OR group was already deleted before remediation
- **Resolution:** Check group name in Azure AD console (https://portal.azure.com > Azure AD > Groups); correct spelling and re-run removal

**Edge Case 3: User Removed from Group But Still Has Access**
- **Symptom:** User can still access matter in Copilot after removal confirmed
- **Cause:** User has direct SharePoint access (not via group) OR multiple groups grant same access
- **Resolution:** Check user's direct SharePoint permissions (SharePoint > Sharing > Advanced); remove direct access separately

---

### Warnings

⚠️ **WARNING 1: Authorized Matters Lookup Table Critical**  
Do NOT guess which matters should be authorized for each user. Incorrect data will cause:
- Over-removal: Users lose access to their actual work cases (disrupts business)
- Under-removal: Users keep unauthorized access (violates data governance)

**Mitigation:** Source from case management system or Floor 6 manager. Document source in log file for audit trail.

⚠️ **WARNING 2: Azure AD Sync Timing**  
Changes take 2-5 minutes to propagate to Copilot search. DO NOT skip the 5-minute wait in Step 2.3. If you skip, verification will show false failures.

⚠️ **WARNING 3: Network Timeout Risk**  
If PowerShell loses connectivity during removal, script will fail mid-operation. Check log file to determine which users were successfully removed vs. which failed (Rollback Scenario 1).

---

### Related Incidents

**Related Incident 1: 2024-Q2 Outlook Startup Delay After Intune Enrollment**
- **Link:** KB-OUTLOOK-INTUNE-DELAY-2024
- **Relevance:** Same cohort (Floor 6); similar timing pattern (post-migration issue detected days later)
- **Lesson:** Post-migration validation must include both device behavior AND access control verification

**Related Incident 2: Win10→Win11 Migration — Other Departments**
- **Expected:** Other departments undergo same Win11 migration
- **Risk:** Same access control misconfiguration likely to recur
- **Mitigation:** Use this runbook and preventive controls (see RCA Preventive Actions section) for all future migrations

---

### Audit Trail

All actions logged to:
- **Primary log:** C:\temp\floor6-access-remediation-[timestamp].log
- **Backup reports:** C:\temp\unauthorized-groups-report.csv, C:\temp\verification-results.csv

**Archive log files after incident closure:**  
Copy to shared folder: \\finbridge\compliance\incident-logs\[incident-id]\  
Retention: 7 years (legal data retention requirement)

---

**Runbook Owner:** DWP Service Delivery  
**Last Updated:** 14/08/2026  
**Next Review:** 14/11/2026 or upon incident recurrence

