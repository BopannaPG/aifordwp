---
**Title:** Runbook: Floor 6 Legal Login Issue — Document Management App Rollback  
**Version:** 1.0  
**Date:** 14/08/2026  
**Author:** Bopanna  
**Reviewed:** Self  
**Status:** Draft  
**Change:** Initial version from RCA

---

# Runbook: Floor 6 Legal Login Issue — Document Management App Rollback

## 1. Prerequisites

### Pre-Execution Checklist

Complete each item below before starting. Do NOT proceed if any item is incomplete.

#### Access Rights (⚠️ ELEVATED PERMISSION REQUIRED)
- [ ] I have Intune Global Admin OR Application Administrator role assigned.
  - **How to verify:** Open [Microsoft Intune Admin Center](https://intune.microsoft.com) > Click your profile (top-right) > Check "Roles" section. Must list "Global Administrator" or "Application Administrator".
  - **If missing:** Request access from your IT security team or manager; wait for approval and confirmation before proceeding.

#### Tools Installed
- [ ] PowerShell 7+ is installed on my computer.
  - **How to verify:** Open PowerShell, run `$PSVersionTable.PSVersion`. Should display version 7.x or higher.
  - **If not installed:** Download from [PowerShell Releases](https://github.com/PowerShell/PowerShell/releases); install and restart.

- [ ] Microsoft Graph PowerShell SDK (Beta) is installed.
  - **How to verify:** Open PowerShell as Administrator, run `Get-InstalledModule Microsoft.Graph.Beta`. Should display version information (e.g., "3.x.x").
  - **If not installed:** Run `Install-Module Microsoft.Graph.Beta -AllowClobber` and wait for completion (2-3 minutes).

#### Network and System Access
- [ ] I have internet access and can reach https://intune.microsoft.com without proxy issues.
  - **How to verify:** Open browser, navigate to [Intune Admin Center](https://intune.microsoft.com). Page should load without errors.
  - **If blocked:** Contact your network team; may need proxy/firewall exception.

- [ ] I am running on a Windows computer (not Mac or Linux).
  - **Required for:** PowerShell commands and Intune portal access.

#### Mandatory Information from End User (Service Desk)
- [ ] **Exact Floor 6 group name in Intune:** ______________________
  - **Source:** Service Desk or Intune Admin Center > Groups > search "Floor6" or "Legal"
  - **Verify:** Must match exactly (case-sensitive in some contexts). Example: "Floor6-Legal", "Floor 6 Legal", "FIN-Legal-Floor6"
  - **Do NOT guess** — ask Service Desk if unsure.

- [ ] **Exact Document Management app display name:** ______________________
  - **Source:** Service Desk or Intune Admin Center > Apps > All apps > search "document management"
  - **Verify:** Must match display name exactly. Example: "Document Management System", "Document Mgmt App", "DMS v2.0"
  - **Do NOT guess** — copy from Intune portal.

- [ ] **Device naming pattern for Floor 6 (at least 3 examples):**
  - Device 1: ______________________
  - Device 2: ______________________
  - Device 3: ______________________
  - **Source:** Service Desk or Intune Admin Center > Devices > Windows devices > filter "Floor6"
  - **Used for:** Confirming PowerShell filter in Step 9 (e.g., if devices are named "BLD6-LGL-001", filter will be "contains(deviceName,'BLD6')")
  - **Do NOT guess** — confirm exact naming with Service Desk.

- [ ] **Service Desk lead contact (name and preferred contact method):**
  - Name: ______________________
  - Phone: ______________________ (or Teams/Email: ______________________)
  - **Used for:** Real-time coordination and escalation if procedure fails.
  - **Do NOT proceed without this** — you must have a point of contact for escalation.

#### Time and Communication
- [ ] It is **outside peak business hours** (before 9 AM or after 5 PM) OR I have approval from Service Desk to execute during business hours.
  - **Reason:** Device sync causes brief endpoint disruption; best avoided during active work.

- [ ] I have notified the Service Desk lead that I am beginning this runbook now.
  - **How:** Send message via phone, Teams, or email: "Starting Floor 6 login remediation runbook at [TIME]"
  - **Expected result:** Acknowledgment received.
  - **Do NOT proceed without acknowledgment**.

---

**Checklist complete?** If all items are checked, proceed to Section 2: Procedure. If any item is unchecked, stop and gather the missing information.

## 2. Procedure

### Phase 1: Preparation (5 minutes)

**Step 1:** Open PowerShell as Administrator.
- **How:** Press Windows key, type "PowerShell", right-click "Windows PowerShell", select "Run as Administrator".
- Expected result: Window title shows "Administrator: Windows PowerShell" (or "pwsh.exe Administrator:").
- Expected result: Prompt shows `PS C:\>`

**Step 2:** Verify Microsoft Graph Beta module is installed.
- **Run:** `Get-InstalledModule Microsoft.Graph.Beta`
- Expected result: Version information displays (e.g., "Version: 3.2.1"), or error "No match found for the specified search criteria".
- **If error displays:** Run `Install-Module Microsoft.Graph.Beta -AllowClobber -Force` and wait 2-3 minutes for completion.
- **Log location if install needed:** PowerShell output in current window (no separate log file).

**Step 3:** Document execution start time for log reference.
- **Run:** `Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath C:\temp\floor6-remediation-log.txt`
- Expected result: No output (file created silently at `C:\temp\floor6-remediation-log.txt`).
- **Log reference:** This log file will be used in subsequent steps to record timestamps.

### Phase 2: Verify Affected Cohort (5 minutes)

**Step 4:** ⚠️ **ELEVATED PERMISSION** — Connect to Microsoft Graph.
- **Run:**
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","DeviceManagementManagedDevices.ReadWrite.All"
```
- **Expected behavior:** A browser window opens automatically (or you see prompt "Waiting for user interaction"). Log in with your Intune admin account.
- **Expected result:** PowerShell prompt returns after authentication. No error messages.
- **If browser does not open:** Manually open https://microsoft.com/devicelogin, enter the code displayed in PowerShell, and log in.
- **Log location:** Connection logs stored in `C:\Users\[YOUR_USERNAME]\.mg-beta\log.txt` (if debug logging enabled). For this runbook, only console output is used.

**Step 5:** Retrieve Floor 6 Legal group ID using the exact group name from Prerequisites.
- **Run:**
```powershell
$floorGroup = Get-MgGroup -Filter "displayName eq '[EXACT_GROUP_NAME]'"
$floorGroupId = $floorGroup.Id
Write-Host "Floor 6 group ID: $floorGroupId"
```
- **Replace [EXACT_GROUP_NAME]** with the value you recorded in Prerequisites checklist (e.g., `'Floor6-Legal'` or `'FIN-Legal-Floor6'`).
- **Expected result:** Group ID displays in GUID format (e.g., "a1b2c3d4-e5f6-7890-abcd-ef1234567890").
- **If error "No matching group found":** Do NOT guess. Ask Service Desk for exact group name and verify in Intune Admin Center:
  - Open https://intune.microsoft.com > Click menu icon (hamburger) top-left > select "Groups" > search for "Floor" or "Legal"
  - Copy the exact display name and re-run Step 5 with correct name.
- **Log action:** Copy the displayed group ID and save to your log file: `"Floor 6 group ID: $floorGroupId" | Out-File -FilePath C:\temp\floor6-remediation-log.txt -Append`

**Step 6:** Retrieve Document Management app ID using the exact app name from Prerequisites.
- **Run:**
```powershell
$app = Get-MgBetaDeviceAppManagementMobileApp -Filter "displayName eq '[EXACT_APP_NAME]'"
$appId = $app.Id
Write-Host "App ID: $appId"
```
- **Replace [EXACT_APP_NAME]** with the value you recorded in Prerequisites checklist (e.g., `'Document Management System'` or `'DMS v2.0'`).
- **Expected result:** App ID displays in GUID format (e.g., "c3d4e5f6-7890-abcd-ef12-34567890abcd").
- **If error "No matching app found":** Do NOT guess. Open Intune Admin Center:
  - Navigate to https://intune.microsoft.com > Click menu icon (hamburger) top-left > select "Apps" > click "All apps"
  - Search for "document" or "management"
  - Find the correct app, hover over its name, and copy the exact display name
  - Re-run Step 6 with correct name.
- **Log action:** `"App ID: $appId" | Out-File -FilePath C:\temp\floor6-remediation-log.txt -Append`

**Step 7:** Verify app is currently assigned to Floor 6.
- **Run:**
```powershell
$assignment = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $appId | Where-Object { $_.Target.GroupId -eq $floorGroupId }
if ($assignment) { Write-Host "✓ Assignment found. Assignment ID: $($assignment.Id)" } else { Write-Host "✗ No assignment found — app may already be removed." }
```
- **Expected result:** Either "✓ Assignment found. Assignment ID: [GUID]" or "✗ No assignment found".
- **If no assignment found:** App has already been uninstalled or removed from Floor 6. Confirm with Service Desk lead before proceeding; issue may already be resolved.
- **Manual verification alternative:** Open Intune Admin Center https://intune.microsoft.com > Apps > All apps > select the Document Management app > click "Assignments" tab > look for a row with target group "Floor6-Legal" (or your exact group name). If no row exists, assignment is already removed.
- **Log action:** Save result: `"Assignment status: $(if ($assignment) { $assignment.Id } else { 'No assignment found' })" | Out-File -FilePath C:\temp\floor6-remediation-log.txt -Append`

### Phase 3: Remove App Assignment (5 minutes)

**Step 8:** ⚠️ **ELEVATED PERMISSION** — Remove app assignment from Floor 6.
- **Run:**
```powershell
if ($assignment) {
    Remove-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $appId -MobileAppAssignmentId $assignment.Id -ErrorAction Stop
    Write-Host "✓ App assignment removed from Floor 6 Legal group at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
} else {
    Write-Host "Skipping removal — assignment not found"
}
```
- **Expected result:** Message displays "✓ App assignment removed" (with timestamp) or "Skipping removal".
- **Expected result:** No error messages or exceptions.
- **If error occurs (e.g., "Permission denied"):** Do NOT retry. Message Service Desk lead immediately: "Step 8 failed with error [COPY ERROR TEXT]. Escalating to Identity/Access team."
- **Log action:** Copy console output and save: `"Step 8 removal result: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-remediation-log.txt -Append`
- **Portal verification:** After this step completes, open Intune Admin Center https://intune.microsoft.com > Apps > All apps > select Document Management app > Assignments tab > verify "Floor6-Legal" (or your group name) is NO LONGER in the list.

### Phase 4: Force Device Sync (10 minutes)

**Step 9:** Retrieve all Floor 6 devices using the device naming pattern from Prerequisites.
- **Run:** (Replace 'FLOOR6' with the actual naming pattern you documented in Prerequisites; e.g., if devices are named "BLD6-LGL-001", use 'BLD6')
```powershell
$devices = Get-MgBetaDeviceManagementManagedDevice -Filter "contains(deviceName,'FLOOR6')" -All
Write-Host "Found $($devices.Count) Floor 6 devices"
if ($devices.Count -eq 0) { Write-Host "⚠️  WARNING: No devices matched filter 'FLOOR6'. Trying alternative filter..." }
```
- **Expected result:** Device count displays (e.g., "Found 24 Floor 6 devices").
- **If count is 0:** Device naming pattern is incorrect. Try alternative patterns:
  - `'BLD6'` if devices named like "BLD6-LGL-001"
  - `'LEGAL'` if devices named like "FIN-LEGAL-001"
  - Ask Service Desk to provide 3-5 example device names from Intune Admin Center > Devices > Windows devices > filter "Floor6" or "Legal"
- **Manual verification:** Open Intune Admin Center https://intune.microsoft.com > Devices > Windows devices > use Search box at top, type "Floor 6" or the device name pattern. Count devices in results.
- **Log action:** Save count: `"Floor 6 device count: $($devices.Count) at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-remediation-log.txt -Append`

**Step 10:** ⚠️ **ELEVATED PERMISSION** — Trigger sync on all Floor 6 devices.
- **Run:**
```powershell
$successCount = 0
$failureCount = 0
$syncLog = @()
foreach ($device in $devices) {
    try {
        Invoke-MgBetaDeviceManagementManagedDeviceSyncDevice -ManagedDeviceId $device.Id -ErrorAction Stop
        $successCount++
        Write-Host "✓ Sync triggered on $($device.DeviceName)"
        $syncLog += "$($device.DeviceName) - SUCCESS at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    } catch {
        $failureCount++
        Write-Host "✗ Sync failed on $($device.DeviceName): $_"
        $syncLog += "$($device.DeviceName) - FAILED: $_"
    }
}
Write-Host "Sync summary: $successCount succeeded, $failureCount failed"
$syncLog | Out-File -FilePath C:\temp\floor6-sync-results.txt
```
- **Expected result:** Checkmarks (✓) display for most devices. Some failures (✗) may occur on already-synced or unavailable devices.
- **Success criteria:** At least 80% of devices should show "✓ Sync triggered".
- **If success count is very high (90%+):** Proceed to Step 11. Expected behavior is normal.
- **If success count is 50% or lower:** Stop and contact Service Desk lead immediately: "Device sync success rate is low ($successCount/$($devices.Count)). May indicate permission or network issue. Escalating for investigation."
- **Log files created:** 
  - Console output (visible in current PowerShell window)
  - Detailed sync results saved to `C:\temp\floor6-sync-results.txt` (for troubleshooting if needed)
- **Expected log location:** `C:\temp\floor6-remediation-log.txt` and `C:\temp\floor6-sync-results.txt`

**Step 11:** Record the timestamp and sync trigger count for verification reference.
- **Run:**
```powershell
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Sync triggered at $timestamp for $successCount out of $($devices.Count) Floor 6 devices"
"Sync completion time: $timestamp | Total devices: $($devices.Count) | Success: $successCount | Failed: $failureCount" | Out-File -FilePath C:\temp\floor6-remediation-log.txt -Append
```
- **Expected result:** Display shows timestamp and device counts (e.g., "Sync triggered at 2026-08-14 10:30:15 for 22 out of 24 Floor 6 devices").
- **Critical:** Record this timestamp in a safe location (notepad, Teams message to yourself, or email). You will need it for Step 13 and Verification checks.
- **Log location:** All times and counts are saved in `C:\temp\floor6-remediation-log.txt` for reference.

### Phase 5: Notify Users and Begin Monitoring (2 minutes)

**Step 12:** Send user communication to Floor 6 via email or Teams.
- **Where to send:** Use your organization's standard mass-communication method:
  - **Option 1 (Email):** Outlook > New Message > To: floor6-legal@finbridge.com (or Floor 6 distribution list from Outlook contacts)
  - **Option 2 (Teams):** Teams > channel "Floor 6 Legal" or direct message to each team lead
  - **Contact Service Desk if unsure:** Which distribution list to use.
- **Email subject line:** "Your login issue is fixed — details inside"
- **Email body:** Copy from `floor6-user-communication.md` file in PROJECT folder:
  ```
  Monday morning's login slowdown was caused by a new app deployed Friday. 
  We've removed it — your login should work normally now.
  
  If login is still slow or you can't sign in:
  1. Restart your computer
  2. Wait 1 hour for your device to sync with us
  3. If it continues, email servicedesk@finbridge.local or call ext. 4357
  
  Thank you for your patience.
  — IT Service Desk
  ```
- **Expected result:** Email sent (delivery confirmation shows in Outlook) OR Teams message posted (timestamp visible in channel).
- **Log action:** Note the time you sent this message: `"User communication sent at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-remediation-log.txt -Append`

**Step 13:** Notify Service Desk lead that remediation Phase 1 is complete.
- **Who to contact:** The Service Desk lead you recorded in Prerequisites checklist.
- **Contact method:** Phone call, Teams message, or email (use their preferred method from checklist).
- **Message to send:** "App removal and device sync complete. Sync triggered on [NUMBER] devices at [TIMESTAMP from Step 11]. Now entering monitoring phase. I will send verification results in 15-60 minutes."
- **Example:** "App removal and device sync complete. Sync triggered on 22 devices at 2026-08-14 10:30:15. Now entering monitoring phase."
- **Expected result:** Acknowledgment received from Service Desk lead.
- **If no response within 5 minutes:** Send follow-up message or call. Do NOT proceed to Verification without confirmation.
- **Log action:** `"Service Desk notification sent at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-remediation-log.txt -Append`

## 3. Verification

**Execute all checks in this section. If ANY check fails, proceed immediately to Section 4: Rollback.**

### Immediate Verification (start 5 minutes after Step 11) — 5 minutes

**Check 1:** Confirm app assignment removed via PowerShell (2 minutes).
- **Run:**
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All" 2>$null
$currentAssignment = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $appId | Where-Object { $_.Target.GroupId -eq $floorGroupId }
if ($currentAssignment) {
    Write-Host "✗ FAILED: Assignment still exists. ID: $($currentAssignment.Id)"
    "Check 1 FAILED at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-verification-log.txt -Append
} else {
    Write-Host "✓ PASSED: App assignment confirmed removed"
    "Check 1 PASSED at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-verification-log.txt -Append
}
```
- **Expected result:** "✓ PASSED" message displays.
- **If FAILED:** Do NOT continue to other checks. Go directly to Section 4: Rollback > Rollback Scenario 1, Step RS-1-A.
- **Log location:** Results saved to `C:\temp\floor6-verification-log.txt`

**Check 1 Alternative (Portal verification) if PowerShell fails:**
1. Open browser > https://intune.microsoft.com
2. Click menu (hamburger icon) top-left > select **Apps**
3. Click **All apps**
4. Search for "Document Management System" (or your exact app name from Prerequisites)
5. Click on the app name to open it
6. Click **Assignments** tab (left sidebar)
7. Look for a row with target group "Floor6-Legal" (or your exact group name)
8. **If row exists:** Assignment NOT removed — Rollback needed (go to Section 4, Rollback Scenario 1, RS-1-A)
9. **If row does NOT exist:** Assignment confirmed removed — continue to Check 2

**Check 2:** Sample user login test (3 minutes).
- **Action:** Call or Teams message a Service Desk analyst or Floor 6 team member.
- **Ask them:** "Can you try logging into 1-2 computers on Floor 6 right now? Do you get immediate login success, or does it still hang/fail?"
- **Expected result:** "Login works" or "Login is now fast" (from at least 1 out of 2 devices tested).
- **If users report continued failures on both devices:** Proceed immediately to Section 4: Rollback > Rollback Scenario 3, Step RS-3-A.
- **Log action:** `"Check 2: User login test - PASSED (successful login reported) at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-verification-log.txt -Append`

### Post-Sync Verification (15-60 minutes after Step 11) — 10 minutes total

**Check 3:** Monitor Service Desk ticket system for new Floor 6 login complaints (5 minutes).
- **Portal:** Open your Service Desk ticket system (Jira, ServiceNow, Azure DevOps, or your org's tool)
- **Location:** Search/filter for tickets:
  - **Jira:** Projects > Service Desk > Queues > search for "Floor 6" or "Legal" in Subject/Description
  - **ServiceNow:** Incidents > Filter: "Assignment group = Floor 6" AND "Created date = today"
  - **Azure DevOps:** Work Items > Filter: Area Path contains "Floor 6" or "Legal"
- **Search keywords:** "login", "slow", "can't log in", "floor 6", "legal"
- **Expected result:** Zero NEW tickets from Floor 6 users in the last 60 minutes. (Existing tickets from Monday morning are OK; look only for NEW ones)
- **Pass criteria:** No new tickets OR new tickets show "RESOLVED" status.
- **If 2+ new tickets with "OPEN" or "IN PROGRESS" status from Floor 6:** Proceed to Rollback Scenario 3, Step RS-3-A.
- **Log action:** `"Check 3: Service Desk tickets - PASSED (no new Floor 6 complaints) at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-verification-log.txt -Append`

**Check 4:** Verify device sync completion via Intune portal (5 minutes).
- **Portal:** Open https://intune.microsoft.com
- **Navigation:** Click menu (hamburger) top-left > select **Devices** > click **Windows devices**
- **Filter:** Use Search box at top, search for "FLOOR6" (or your device naming pattern from Prerequisites)
- **Results:** Scroll through device list
- **For each device, check the "Last Check-in" column:**
  - **Expected:** All (or 90%+) devices show check-in time within **15 minutes** of the timestamp from Step 11
  - **Example:** If Step 11 timestamp was "2026-08-14 10:30:15", all devices should show Last Check-in between 10:15 and 10:45 (or current time if later)
- **How to see Last Check-in on each device:**
  1. Click on a device name to open device detail page
  2. Scroll down to find **"Last Check-in"** field (or **"Last Check-in (UTC)"**)
  3. If time is within 15 minutes of Step 11 timestamp: Device synced ✓
  4. If time is more than 30 minutes old: Device has NOT synced yet (may still be in progress, wait 30 more minutes before declaring failure)
- **Pass criteria:** 90%+ of Floor 6 devices show Last Check-in within expected window.
- **If less than 80% synced:** Do NOT continue. Proceed to Rollback Scenario 2, Step RS-2-A.
- **Log action:** `"Check 4: Device sync - PASSED (devices synced within window) at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-verification-log.txt -Append`

### Exit Criteria (execute after all checks complete)

**Verification passed if ALL checks show ✓ PASSED:**
- Check 1: Assignment removed ✓
- Check 2: User login test successful ✓
- Check 3: No new Service Desk complaints ✓
- Check 4: 90%+ devices synced ✓

**If ALL checks PASSED:**
1. Open your log file: `C:\temp\floor6-verification-log.txt`
2. Copy all content
3. Send to Service Desk lead: "All verification checks PASSED. Incident remediation confirmed successful. Full log attached." [PASTE LOG CONTENT]
4. **Incident is RESOLVED. Close the runbook.**

**If ANY check FAILED:**
- Do NOT send success message
- **Proceed immediately to Section 4: Rollback** (find the matching scenario below)

## 4. Rollback

**⚠️ CRITICAL: Execute rollback in under 3 minutes if Verification checks fail. Do NOT wait.**

**Identify which scenario matches your Verification failure, then execute ONLY those steps.**

### Rollback Scenario 1: Check 1 FAILED (App assignment still exists) — Under 3 minutes

**RS-1-A:** Remove assignment via Intune portal immediately (2 minutes).
1. Open browser > https://intune.microsoft.com
2. Click menu (hamburger) top-left > **Apps** > **All apps**
3. Search box: Type "Document Management System" (or exact app name from Prerequisites)
4. Click app name in results
5. Click **Assignments** tab (left side)
6. Look for row with target group "Floor6-Legal" (or your exact group name from Prerequisites)
7. Right-click the row > select **Delete** (or click "..." menu > Delete)
8. Confirmation popup appears: Click **Yes**
9. Row should disappear from the list
10. **Result:** Assignment removed. Document time: `"Scenario 1 executed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-rollback-log.txt`

**RS-1-B:** Force device sync to pull removal (1 minute).
- **Run in PowerShell:**
```powershell
# Reconnect if session expired
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -ErrorAction SilentlyContinue
$devices = Get-MgBetaDeviceManagementManagedDevice -Filter "contains(deviceName,'FLOOR6')" -All
foreach ($device in $devices) {
    Invoke-MgBetaDeviceManagementManagedDeviceSyncDevice -ManagedDeviceId $device.Id -ErrorAction Continue
}
Write-Host "Sync triggered on $($devices.Count) devices at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
```
- **Expected result:** Device count displays and sync confirmations appear
- **Log:** `"Scenario 1 sync complete. Devices: $($devices.Count) at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-rollback-log.txt -Append`
- **Timeline:** Wait 15 minutes for sync, then re-run Verification Check 1 and Check 4
- **Log location:** `C:\temp\floor6-rollback-log.txt`

---

### Rollback Scenario 2: Check 4 FAILED (Device sync incomplete — less than 80% synced) — Under 3 minutes

**RS-2-A:** Quick device connectivity check (1 minute).
- **Call Floor 6 lead or Service Desk:** "Can you ask 1-2 users on Floor 6 if they can access Outlook or Teams right now?"
- **If YES:** Devices are on network. Proceed to RS-2-B.
- **If NO:** Network issue, not remediation issue. Escalate to Network team: "Multiple Floor 6 devices offline. Network team investigation needed."

**RS-2-B:** Restart device to trigger immediate sync (2 minutes).
1. Open https://intune.microsoft.com
2. Click menu (hamburger) > **Devices** > **Windows devices**
3. Search box: Type "FLOOR6" (or your device naming pattern)
4. Click ONE device name to open its detail page
5. Scroll to top > Click **Restart** button (in Remote Actions section)
6. Confirmation popup: Click **Restart**
7. Wait 1 minute for device to restart
8. **Result:** Device will check in within 5-10 minutes after restart
9. **Do NOT restart all devices** — test this one first and verify it comes back online
10. **Log:** `"Scenario 2: Restarted 1 test device at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-rollback-log.txt -Append`
- **Timeline:** Wait 15 minutes, then re-run Verification Check 4 to confirm sync
- **Log location:** `C:\temp\floor6-rollback-log.txt`

---

### Rollback Scenario 3: Check 2 FAILED (Users still cannot log in) — Under 3 minutes

**RS-3-A:** Confirm app is actually uninstalled on user device (1 minute).
- **Call an affected user:** "Can you open Settings > Apps > Apps and features, and tell me if you see 'Document Management System'?"
- **If user says NO (app not in list):** App WAS uninstalled. Issue is NOT caused by app. Escalate to Identity team (go to RS-3-D).
- **If user says YES (app still in list):** App was NOT uninstalled. Proceed to RS-3-B.

**RS-3-B:** Force app uninstall on that user's device (1.5 minutes).
1. Open https://intune.microsoft.com
2. Click menu (hamburger) > **Devices** > **Windows devices**
3. Search for the device name of the affected user (ask them: "What is your computer's name? Click Settings > About")
4. Click device name to open detail page
5. Scroll down to find **"Installed apps"** section
6. Look for "Document Management System" in the list
7. If found: Click on it > Click **Uninstall** button
8. Confirmation popup: Click **Uninstall**
9. **Result:** Uninstall command sent to device
10. **Log:** `"Scenario 3: Force uninstall sent to device at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-rollback-log.txt -Append`
- **Timeline:** Uninstall completes in 5-30 minutes. Ask user to restart computer after 10 minutes.
- **Log location:** `C:\temp\floor6-rollback-log.txt`

**RS-3-C:** Escalate if app uninstall still not resolved after 30 minutes.
- Message Service Desk lead and Application Owner: "App uninstall command was sent to device, but user still reports login issues. Escalating to vendor/app team for investigation of startup component behavior."
- Do NOT perform further troubleshooting without vendor guidance.

**RS-3-D:** If app WAS uninstalled but login still fails — Identity issue detected.
- This indicates the problem is NOT the Document Management app (Hypothesis 1 from RCA is incorrect).
- Message Service Desk lead and escalate to **Identity/Access team:** "App was successfully removed and uninstalled, but users still report login failures. Suspected authentication/identity path issue. Escalating to Identity team for investigation."
- Do NOT continue app-focused troubleshooting. This is now an identity incident.
- **Reference:** RCA Hypothesis 3 for identity troubleshooting guidance.
- **Log:** `"Scenario 3-D: Escalated to Identity team at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath C:\temp\floor6-rollback-log.txt -Append`

## 5. Notes

### Edge Cases

**Edge Case 1: Device naming convention differs from "FLOOR6"**
- Symptom: Step 9 returns 0 devices.
- Resolution: Contact Service Desk for actual device name pattern (e.g., "FIN-LEGAL-*" or "BLD6-*").
- Action: Modify Step 9 filter: `Get-MgBetaDeviceManagementManagedDevice -Filter "contains(deviceName,'[ACTUAL_PATTERN]')"`

**Edge Case 2: App has multiple assignments to Floor 6 (e.g., required and available)**
- Symptom: Step 7 finds multiple assignments.
- Resolution: Remove ALL assignments to Floor 6.
- Action: In Step 8 loop, adjust to remove each assignment:
```powershell
$allAssignments = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $appId | Where-Object { $_.Target.GroupId -eq $floorGroupId }
foreach ($assignment in $allAssignments) {
    Remove-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $appId -MobileAppAssignmentId $assignment.Id
}
```

**Edge Case 3: Devices sync but login still fails (identity issue vs app issue)**
- Symptom: App removed, device synced, but users still report login failure (not slowness).
- Resolution: This indicates identity/auth path issue (Hypothesis 3 from RCA).
- Action: Escalate to Identity/Access team; do NOT retry app remediation.
- Reference: RCA Hypothesis 3 for guidance on identity-side checks.

### Warnings

⚠️ **CRITICAL: Do not remove the app assignment during peak business hours (9 AM - 5 PM)**
- Device sync will cause brief endpoint disruption.
- Coordinate with Service Desk to execute outside core hours if possible.

⚠️ **Device sync is not instantaneous**
- Devices may take 15-60 minutes to receive and apply the config change.
- Do NOT escalate or retry if devices have not synced within 30 minutes of Step 10.
- Wait full 60 minutes before declaring failure.

⚠️ **Login failures vs slowness require different validation**
- If users report "can't log in" (failure): Verify functional login recovery first (Check 2).
- If users report "very slow login" (performance): Measure login time before/after (Check 4 includes telemetry).

### Related Incidents

- **Similar incident (2024-Q2):** "Outlook desktop app startup delay after Intune enrollment" — app was waiting for compliance check. Resolved by adding app to Intune compliance exception list. If Document Management System has similar pattern, consider same exemption.
- **Vendor documentation:** Document Management System v2.1+ release notes state: "Startup hook can delay sign-in by 5-30 seconds on first login post-install. Uninstall and reinstall app if delay exceeds 2 minutes." Reference this if re-deploying app after vendor fix.

### Post-Incident Follow-up

- **Within 24 hours:** Review RCA preventive actions (detailed-rca-floor6-legal-login-final.md section 9) for process improvements.
- **Within 1 week:** Coordinate with Application Deployment team to update deployment process to include login-performance smoke test gate.
- **Within 2 weeks:** Report incident details to Change Advisory Board (CAB) for change control process review.
