# L2 KB Article: Floor 6 Login Degradation After App Deployment

**Version:** 1.0  
**Date:** 14/08/2026  
**Status:** Draft

---

## 1. Background

**System Context:**
- FinBridge Floor 6 (Legal, 45 users) recently migrated from Windows 10 to Windows 11 and enrolled in Intune management
- Users depend on domain-joined, Intune-managed endpoints for access to corporate applications and file shares
- New document management app (Document Management System v2.0) was deployed via Intune app assignment on Friday afternoon to Floor 6 group
- Floor 6 represents 45 legal staff performing time-sensitive document review and compliance work; login delays directly impact billable hours and risk compliance deadlines

**Why This Matters:**
- Login path degradation prevents core business access
- Floor 6 is a high-value business unit; even 1-hour delays across 45 users = 45 hours lost productivity
- Migration to Win11/Intune is recent; baseline performance data may be incomplete
- App deployment without comprehensive pre-rollout testing represents control gap in change management

---

## 2. Symptom

**User Reports (collected Monday 9:15 AM):**
- "At least a dozen" users (exact count: to confirm from Service Desk tickets)
- Symptom A: Complete login failure (users unable to reach login prompt or credential entry fails silently)
- Symptom B: Severe login delay (10-30+ minutes reported; normal baseline is 30-60 seconds)
- Symptom C: Mixed cohort — some users on same floor unaffected; some completely blocked; some very slow
- Timeline: First reports Monday morning; Friday afternoon app deployment preceded by ~40 hours

**Engineer Observable Signs:**
- Intune device compliance reports show mixed state for Floor 6 devices
- Device sync timestamps cluster around app deployment timestamp (Friday afternoon)
- No widespread tenant-level authentication outage (identity service health nominal)
- Issue scope limited to Floor 6 devices with app assignment

---

## 3. Root Cause

**Confirmed Technical Cause:**
The Document Management System v2.0 app initialization code executes at Windows login time (via RunOnce registry key or startup component) and contains a blocking service wait or resource contention that delays or fails credential validation flow.

**Evidence Supporting This Hypothesis:**

| Evidence Type | Details | Location/Command |
|---|---|---|
| **Temporal correlation** | App deployed Friday afternoon (~4 PM); impact reported Monday morning (~9 AM) | Service Desk ticket timestamp vs Intune app deployment log |
| **Scope correlation** | Impact limited to Floor 6; app assignment targeted Floor 6 group only | Intune Admin Center > Apps > All apps > Document Management System > Assignments |
| **Symptom pattern** | Mixed failure (some users blocked, some slow) typical of blocking resource contention | User reports in Service Desk ticket queue |
| **Device state match** | Affected devices all have app install timestamp matching Friday deployment; unaffected Floor 6 devices lack app install | Intune Admin Center > Devices > Windows devices > select device > App install history |
| **No identity service issue** | Tenant sign-in logs show no shared authentication failure patterns during incident window | Azure AD > Sign-in logs > Filter: "Floor 6" users, Monday 9-11 AM; should show normal auth success rates |

**Not Confirmed (Ruled Out via Preliminary Investigation):**
- Intune compliance profile conflict (compliance evaluation time normal on affected devices)
- Network latency (affected users on same network segment as unaffected users; ping to identity service nominal)
- Tenant-wide identity degradation (other floors unaffected)

---

## 4. Detection

**Diagnostic Objective:** Confirm app deployment caused login degradation before proceeding with rollback. Complete in under 3 minutes using PowerShell commands.

### Step D-1: Extract Device Install State (30 seconds)
**Command (PowerShell — run locally on affected device OR from admin workstation with Intune access):**
```powershell
# Connect to Intune
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -ErrorAction Stop

# Get Floor 6 affected device
$affectedDevice = Get-MgBetaDeviceManagementManagedDevice -Filter "deviceName eq 'FLOOR6-LGL-001'" -ErrorAction Stop
Write-Host "Device: $($affectedDevice.DeviceName)"
Write-Host "Last Sync: $($affectedDevice.LastSyncDateTime)"
Write-Host "Compliance State: $($affectedDevice.ComplianceState)"

# Get unaffected control device (for comparison)
$controlDevice = Get-MgBetaDeviceManagementManagedDevice -Filter "deviceName eq 'FLOOR6-LGL-CONTROL-001'" -ErrorAction Stop
Write-Host "Control Device: $($controlDevice.DeviceName)"
Write-Host "Control Last Sync: $($controlDevice.LastSyncDateTime)"
```

**Expected Result (Abnormal):**
```
Device: FLOOR6-LGL-001
Last Sync: 2026-08-10 16:15:00 (Friday afternoon, matching app deployment time)
Compliance State: Compliant

Control Device: FLOOR6-LGL-CONTROL-001
Control Last Sync: 2026-08-14 08:00:00 (Much more recent)
```

**Expected Result (Normal Control):**
- Control device sync time should be TODAY, not Friday afternoon
- Both devices in same floor should have same LastSyncDateTime if both received same policies

**Log Location:** Memory only (output to PowerShell console); save to file: `$affectedDevice | Select-Object DeviceName, LastSyncDateTime | Export-Csv -Path C:\temp\device-state.csv`

---

### Step D-2: Extract Windows Logon Failure Events from Affected Device (1 minute)
**Command (Run on affected device via RDP or remote PowerShell):**
```powershell
# Location: C:\Windows\System32\winevt\Logs\Security.evtx

# Extract failed logon events (Event ID 4625) from past 24 hours
Get-WinEvent -LogName Security -FilterXPath "*[System[(EventID=4625) and TimeCreated[timediff(@SystemTime) <= 86400000]]]" -MaxEvents 50 | 
Select-Object TimeCreated, @{Name="EventID"; Expression={$_.Id}}, @{Name="FailureReason"; Expression={$_.Properties[8].Value}} |
Format-Table -AutoSize |
Out-File -FilePath C:\temp\logon-failures-FLOOR6-LGL-001.txt

# Also extract successful logons (Event ID 4624) to check timing gap
Get-WinEvent -LogName Security -FilterXPath "*[System[(EventID=4624) and TimeCreated[timediff(@SystemTime) <= 86400000]]]" -MaxEvents 50 | 
Select-Object TimeCreated, @{Name="EventID"; Expression={$_.Id}}, @{Name="LogonType"; Expression={$_.Properties[8].Value}} |
Format-Table -AutoSize |
Out-File -FilePath C:\temp\logon-success-FLOOR6-LGL-001.txt

Write-Host "Extracted to C:\temp\logon-failures-FLOOR6-LGL-001.txt"
Get-Content C:\temp\logon-failures-FLOOR6-LGL-001.txt
```

**What to Look For:**
- **Event ID 4625** (Failed Logon) entries dated Monday 9 AM
- **Event ID 4624** (Successful Logon) with 10+ minute gap after each 4625 entry
- **Failure Reason field:** Should be generic (not specific auth error) if app is blocking

**Expected Result (Abnormal):**
```
TimeCreated          EventID  FailureReason
2026-08-14 09:05:15  4625     An error occurred during logon
2026-08-14 09:05:20  4625     An error occurred during logon
2026-08-14 09:05:25  4625     An error occurred during logon
2026-08-14 09:36:45  4624     2 (Interactive)
[+32 minute gap between failures and success]
```

**Expected Result (Normal — Control Device):**
```
TimeCreated          EventID  FailureReason
[No 4625 entries]
2026-08-14 09:05:00  4624     2 (Interactive)
[Immediate success, no gap]
```

**Log Location:** 
- Source file: `C:\Windows\System32\winevt\Logs\Security.evtx` (on affected device)
- Extracted output: `C:\temp\logon-failures-FLOOR6-LGL-001.txt` and `C:\temp\logon-success-FLOOR6-LGL-001.txt`
- Comparison: Pull same logs from `FLOOR6-LGL-CONTROL-001` to verify baseline (should have no 4625 entries)

---

### Step D-3: Extract Application Event Log for App Startup Crashes (1 minute)
**Command (Run on affected device):**
```powershell
# Location: C:\Windows\System32\winevt\Logs\Application.evtx

# Extract Event ID 1000 (Crash Report) for app-related events
Get-WinEvent -LogName Application -FilterXPath "*[System[(EventID=1000) and TimeCreated[timediff(@SystemTime) <= 86400000]]] and *[EventData[Data[@Name='EventType'] = 'CLR20r3' or Data[@Name='ModuleName'] containing 'dms']]" -MaxEvents 20 -ErrorAction SilentlyContinue | 
Select-Object TimeCreated, @{Name="EventID"; Expression={$_.Id}}, @{Name="ModuleName"; Expression={$_.Properties[4].Value}}, @{Name="FaultAddress"; Expression={$_.Properties[10].Value}} |
Format-Table -AutoSize |
Out-File -FilePath C:\temp\app-crashes-FLOOR6-LGL-001.txt

# Alternate: Search for ALL Event 1000 and filter manually by ModuleName
Get-WinEvent -LogName Application -FilterXPath "*[System[(EventID=1000) and TimeCreated[timediff(@SystemTime) <= 86400000]]]" -MaxEvents 30 | 
Where-Object { $_.Properties[4].Value -match 'dms|startup|hook' } |
Select-Object TimeCreated, @{Name="EventID"; Expression={$_.Id}}, @{Name="Source"; Expression={$_.ProviderName}}, @{Name="FaultModule"; Expression={$_.Properties[4].Value}} |
Format-Table -AutoSize

Write-Host "Extracted to C:\temp\app-crashes-FLOOR6-LGL-001.txt"
```

**What to Look For:**
- **Event ID 1000** (Windows Error Reporting - Application Crash)
- **Fault Module name:** Look for `dms.dll`, `dms-startup-hook.dll`, `dms-core.dll`, or similar app DLL names
- **Time:** Should occur 1-5 minutes BEFORE the first 4625 logon failure event (from Step D-2)
- **Source/Provider:** Should be "Application Error" or "Windows Error Reporting"

**Expected Result (Abnormal):**
```
TimeCreated          EventID  Source                  FaultModule
2026-08-14 09:03:30  1000     Windows Error Reporting dms-startup-hook.dll
2026-08-14 09:03:35  1000     Windows Error Reporting dms-startup-hook.dll
[THEN 4625 logon failure at 09:05 from Step D-2]
```

**Expected Result (Normal — Control Device):**
```
[No Event ID 1000 entries with FaultModule containing 'dms']
```

**Log Location:**
- Source file: `C:\Windows\System32\winevt\Logs\Application.evtx` (on affected device)
- Extracted output: `C:\temp\app-crashes-FLOOR6-LGL-001.txt`
- Comparison: Pull same logs from control device `FLOOR6-LGL-CONTROL-001` (should show NO dms.dll crash events)

---

### Step D-4: Verify App Assignment in Intune via PowerShell (30 seconds)
**Command (PowerShell — requires Intune Global Admin role):**
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All" -ErrorAction Stop

# Get Document Management System app
$app = Get-MgBetaDeviceAppManagementMobileApp -Filter "displayName eq 'Document Management System'" -ErrorAction Stop
$appId = $app.Id
Write-Host "App: $($app.DisplayName) | ID: $appId"

# Get Floor 6 Legal group
$floorGroup = Get-MgGroup -Filter "displayName eq 'Floor6-Legal'" -ErrorAction Stop
$floorGroupId = $floorGroup.Id
Write-Host "Target Group: Floor6-Legal | ID: $floorGroupId"

# Check if app is assigned to Floor 6
$assignment = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $appId | 
    Where-Object { $_.Target.GroupId -eq $floorGroupId }

if ($assignment) {
    Write-Host "✗ CONFIRMED: App IS assigned to Floor6-Legal"
    Write-Host "Assignment ID: $($assignment.Id)"
    Write-Host "Intent: $($assignment.Intent)"
    Write-Host "Created: $($assignment.CreatedDateTime)"
} else {
    Write-Host "✓ App is NOT assigned to Floor6-Legal (already removed or never assigned)"
}
```

**Expected Result (Confirms Cause):**
```
App: Document Management System | ID: a1b2c3d4-e5f6-7890...
Target Group: Floor6-Legal | ID: f6f7f8f9-0a0b-1c1d...
✗ CONFIRMED: App IS assigned to Floor6-Legal
Assignment ID: 12345678-abcd-ef01-2345...
Intent: Required
Created: 2026-08-10T16:10:00Z
```

**Log Location:** Memory output only; save to file with: `$assignment | Select-Object * | Out-File C:\temp\app-assignment.txt`

---

### Step D-5: Cross-Check No Tenant-Wide Identity Issue via PowerShell (30 seconds)
**Command (PowerShell — requires Azure AD Logs Reader role):**
```powershell
# Connect to Azure AD
Connect-MgGraph -Scopes "AuditLog.Read.All" -ErrorAction Stop

# Get Floor 6 Legal users
$floorGroup = Get-MgGroup -Filter "displayName eq 'Floor6-Legal'"
$floorUsers = Get-MgGroupMember -GroupId $floorGroup.Id -All

# Query sign-in logs for Floor 6 users on Monday 9-11 AM (filter by time and user list)
$signInFilter = "createdDateTime ge 2026-08-14T09:00:00Z and createdDateTime le 2026-08-14T11:00:00Z"

$signIns = Get-MgAuditLogSignIn -Filter $signInFilter -All | 
    Where-Object { $floorUsers.Id -contains $_.UserId }

# Count success vs failure
$successCount = ($signIns | Where-Object { $_.Status.ErrorCode -eq 0 }).Count
$failureCount = ($signIns | Where-Object { $_.Status.ErrorCode -ne 0 }).Count
$successRate = if (($successCount + $failureCount) -gt 0) { [math]::Round(($successCount / ($successCount + $failureCount)) * 100, 1) } else { 0 }

Write-Host "Floor 6 Sign-in Activity (Monday 9-11 AM):"
Write-Host "Successful: $successCount"
Write-Host "Failed: $failureCount"
Write-Host "Success Rate: $successRate%"

if ($successRate -ge 90) {
    Write-Host "✓ PASSED: Identity service is healthy (>90% success rate)"
} else {
    Write-Host "✗ FAILED: Low success rate indicates identity issue"
    # Show failure reasons
    $signIns | Where-Object { $_.Status.ErrorCode -ne 0 } | 
        Group-Object { $_.Status.FailureReason } |
        Select-Object @{Name="FailureReason"; Expression={$_.Name}}, @{Name="Count"; Expression={$_.Count}} |
        Format-Table -AutoSize
}
```

**Expected Result (Rules Out Identity Service Issue):**
```
Floor 6 Sign-in Activity (Monday 9-11 AM):
Successful: 195
Failed: 5
Success Rate: 97.5%
✓ PASSED: Identity service is healthy (>90% success rate)
```

**Expected Result (If Identity IS the Issue):**
```
Success Rate: 45%
✗ FAILED: Low success rate indicates identity issue

FailureReason                                Count
Invalid username or password                 50
Conditional access policy block              25
```

**Log Location:** Azure AD Audit logs (cloud-based); export with: `$signIns | Export-Csv -Path C:\temp\signin-logs-floor6.csv`

---

## Summary: Detection Complete in Under 3 Minutes

| Step | Time | Command | Confirms |
|------|------|---------|----------|
| D-1 | 30 sec | PowerShell (Intune) | Device synced at app deployment time |
| D-2 | 1 min | PowerShell (Get-WinEvent) | Event 4625 + 4624 with 30+ min gap |
| D-3 | 1 min | PowerShell (Get-WinEvent) | Event 1000 + Fault Module dms*.dll |
| D-4 | 30 sec | PowerShell (Graph API) | App assigned to Floor6-Legal |
| D-5 | 30 sec | PowerShell (Azure AD logs) | >90% sign-in success rate |

**If D-1 through D-4 confirm AND D-5 passes → App deployment is root cause. Proceed to Resolution.**

**If D-5 fails (success rate <90%) → Identity issue also present. Escalate to Identity team while proceeding with app removal.**

---

## 5. Resolution

**Execution Time:** 5-10 minutes total  
**Prerequisites:** Detection complete (confirm D-1 through D-5 all passed)

### Step R-1: Remove App Assignment from Floor6-Legal Group (2 minutes)
**Command (PowerShell — run on admin workstation with Intune access):**
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All" -ErrorAction Stop

# Get app ID
$app = Get-MgBetaDeviceAppManagementMobileApp -Filter "displayName eq 'Document Management System'" -ErrorAction Stop
$appId = $app.Id
Write-Host "App found: $($app.DisplayName) | ID: $appId"

# Get Floor6-Legal group ID
$group = Get-MgGroup -Filter "displayName eq 'Floor6-Legal'" -ErrorAction Stop
$groupId = $group.Id
Write-Host "Group found: $($group.DisplayName) | ID: $groupId"

# Get and remove assignment
$assignment = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $appId | Where-Object { $_.Target.GroupId -eq $groupId }

if ($assignment) {
    Remove-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $appId -MobileAppAssignmentId $assignment.Id -Confirm:$false
    Write-Host "✓ Assignment removed: $($assignment.Id)"
} else {
    Write-Host "✓ No assignment found (already removed)"
}
```

**Expected Result:** "Assignment removed" or "already removed" message (no error)

**Portal Verification (if command fails):**
- Location: https://intune.microsoft.com/#blade/Microsoft_Intune_Apps/AllAppsMenuBlade/overview
- Navigate: Apps > All apps > search **"Document Management System"** > click app name > **Assignments** tab
- **Locate and remove:** Find row with **Group Name = "Floor6-Legal"** and **Intent = "Required"** > Click row > Click **Remove**
- **Confirmation:** Click **Yes** in popup dialog

---

### Step R-2: Trigger Immediate Device Sync on All Floor 6 Devices (2 minutes)
**Command (PowerShell):**
```powershell
# Get all Floor 6 devices
$floor6Devices = Get-MgBetaDeviceManagementManagedDevice -Filter "contains(deviceName, 'FLOOR6')" -All -ErrorAction Stop
Write-Host "Found $($floor6Devices.Count) Floor 6 devices"

# Trigger sync on each device
$syncResults = foreach ($device in $floor6Devices) {
    try {
        Invoke-MgBetaDeviceManagementManagedDeviceSync -ManagedDeviceId $device.Id -ErrorAction Stop
        @{
            DeviceName = $device.DeviceName
            SyncStatus = "TRIGGERED"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    } catch {
        @{
            DeviceName = $device.DeviceName
            SyncStatus = "FAILED: $_"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

$syncResults | Format-Table -AutoSize
$syncResults | Export-Csv -Path C:\temp\floor6-sync-triggered.csv -NoTypeInformation
Write-Host "Sync triggered on $($syncResults.Count) devices. Results logged to C:\temp\floor6-sync-triggered.csv"
```

**Expected Result:** All Floor 6 devices show "TRIGGERED" status (100% success)

**Portal Verification (if command fails):**
- Location: https://intune.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/Windows/allDevices
- Navigate: Devices > Windows devices
- **Find device:** Search/filter column for **"FLOOR6"** devices
- **Trigger sync:** Click each device name > In device overview panel, click **Sync** button > Confirm popup
- **Expected:** Device shows "Sync in progress" status temporarily

---

### Step R-3: Monitor App Removal Propagation (1 minute wait + 1 minute check)
**Command (PowerShell — run this after 5-minute wait):**
```powershell
Start-Sleep -Seconds 300  # Wait 5 minutes for devices to sync

# Check app removal state on sample devices
$testDevices = $floor6Devices | Select-Object -First 3

foreach ($device in $testDevices) {
    $apps = Get-MgBetaDeviceManagementManagedDeviceInstalledApp -ManagedDeviceId $device.Id -ErrorAction SilentlyContinue
    $dmsApp = $apps | Where-Object { $_.DisplayName -match 'Document Management' }
    
    if ($dmsApp) {
        Write-Host "✗ $($device.DeviceName): DMS app still installed"
    } else {
        Write-Host "✓ $($device.DeviceName): DMS app removed"
    }
}
```

**Expected Result:** All test devices show "DMS app removed" (apps successfully uninstalled)

**Portal Verification:**
- Location: https://intune.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/Windows/allDevices
- Navigate: Devices > Windows devices > select **"FLOOR6-LGL-001"** (or other test device)
- Click device > scroll to **Installed apps** section
- **Verify:** "Document Management System" should NOT appear in list
- Repeat for 2-3 additional Floor 6 devices

---

### Step R-4: Notify Service Desk & End Users
**Action:** Send notification (template below)
```
Subject: Floor 6 Login Issue - Fixed (Action Required: Restart Computers)

Dear Floor 6 Users,

Our IT team has identified and resolved the login slowness issue reported this morning. 
The cause was a recently deployed Document Management System app that interfered with the login process.

What you need to do:
1. RESTART your computer now
2. When you log back in, login should complete within 1-2 minutes (normal speed)
3. If you still experience delays, restart again and wait 15 minutes for settings to update

If login continues to fail:
- Call IT Service Desk ext. 4357
- Provide your computer name (Settings > System > About)
- Let us know the exact error message

Your data is completely safe and unchanged.

Thank you for your patience.
IT Service Desk
```

**Expected Result:** Users restart; login times return to normal (30-60 seconds)

---

## 6. Verification

**Total Verification Time:** 5 minutes  
**All checks must pass before marking incident resolved.**

### Verify V-1: Confirm App Assignment Removed (1 minute)
**Command (PowerShell):**
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All" -ErrorAction Stop

$app = Get-MgBetaDeviceAppManagementMobileApp -Filter "displayName eq 'Document Management System'" -ErrorAction Stop
$floorGroup = Get-MgGroup -Filter "displayName eq 'Floor6-Legal'" -ErrorAction Stop
$assignments = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -All | 
    Where-Object { $_.Target.GroupId -eq $floorGroup.Id }

if ($assignments) {
    Write-Host "✗ FAILED: Assignments still exist for Floor6-Legal"
    $assignments | Select-Object Id, @{Name="CreatedDateTime"; Expression={$_.CreatedDateTime}} | Format-Table
    exit 1
} else {
    Write-Host "✓ PASSED: App assignment successfully removed from Floor6-Legal"
    exit 0
}
```

**Expected Result:** "PASSED" message and exit code 0

**Portal Verification (if command not available):**
- Location: https://intune.microsoft.com/#blade/Microsoft_Intune_Apps/AllAppsMenuBlade/overview
- Navigate: Apps > All apps > **"Document Management System"** > **Assignments** tab
- **Verify:** No row with **Group Name = "Floor6-Legal"** appears
- If row exists: **FAILED** — remediation incomplete

---

### Verify V-2: Confirm App Uninstalled on Devices (2 minutes)
**Command (PowerShell):**
```powershell
# Check app removal on 5 random Floor 6 devices
$testDevices = Get-MgBetaDeviceManagementManagedDevice -Filter "contains(deviceName, 'FLOOR6')" -All | Get-Random -Count 5

$verifyResults = foreach ($device in $testDevices) {
    try {
        $apps = Get-MgBetaDeviceManagementManagedDeviceInstalledApp -ManagedDeviceId $device.Id -ErrorAction Stop
        $dmsApp = $apps | Where-Object { $_.DisplayName -match 'Document Management' }
        
        if ($dmsApp) {
            @{
                DeviceName = $device.DeviceName
                DMS_Status = "FAILED: Still Installed"
                LastSyncTime = $device.LastSyncDateTime
            }
        } else {
            @{
                DeviceName = $device.DeviceName
                DMS_Status = "PASSED: Removed"
                LastSyncTime = $device.LastSyncDateTime
            }
        }
    } catch {
        @{
            DeviceName = $device.DeviceName
            DMS_Status = "ERROR: Cannot verify"
            LastSyncTime = "N/A"
        }
    }
}

$verifyResults | Format-Table -AutoSize
$passCount = ($verifyResults | Where-Object { $_.DMS_Status -eq "PASSED: Removed" }).Count
$totalCount = $verifyResults.Count

if ($passCount -eq $totalCount) {
    Write-Host "✓ PASSED: DMS app removed from all 5 test devices"
    exit 0
} else {
    Write-Host "✗ FAILED: $($totalCount - $passCount) of $totalCount devices still have DMS installed"
    exit 1
}
```

**Expected Result:** All 5 devices show "PASSED: Removed"

**Portal Verification (if command not available):**
- Location: https://intune.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/Windows/allDevices
- Navigate: Devices > Windows devices
- **Select 3 devices:** FLOOR6-LGL-001, FLOOR6-LGL-002, FLOOR6-LGL-003 (or similar)
- Click device name > scroll to **Installed apps** section
- **Verify:** "Document Management System" does NOT appear in app list
- **If found:** FAILED — wait 15 minutes and recheck (sync may be in progress)

---

### Verify V-3: Confirm User Login Performance Restored (1 minute manual test)
**Action:** Service Desk tests login on 3 Floor 6 devices (manually)

**Test Procedure:**
1. On affected device: Sign out (or use different user login if multi-user device)
2. Sign back in with credentials
3. Measure time from credential submit to desktop fully loaded (desktop icons visible, taskbar responsive)

**Expected Results:**
- **PASS:** Login time 45-90 seconds (normal)
- **FAIL:** Login time >120 seconds OR login failure

**Example Results (PASS):**
```
Device: FLOOR6-LGL-001
Time to Desktop: 52 seconds ✓

Device: FLOOR6-LGL-002
Time to Desktop: 78 seconds ✓

Device: FLOOR6-LGL-003
Time to Desktop: 65 seconds ✓
```

**Example Results (FAIL):**
```
Device: FLOOR6-LGL-001
Time to Desktop: 245 seconds ✗ (still slow)
-> Action: Wait 10 minutes, restart, retest
```

---

### Verify V-4: Check Device Sync Completion State (1 minute)
**Command (PowerShell):**
```powershell
# Get all Floor 6 devices and check sync status
$allFloor6 = Get-MgBetaDeviceManagementManagedDevice -Filter "contains(deviceName, 'FLOOR6')" -All
$recentSyncTime = (Get-Date).AddMinutes(-30)  # Last 30 minutes

$syncedDevices = $allFloor6 | Where-Object { $_.LastSyncDateTime -ge $recentSyncTime }
$syncPercentage = [math]::Round(($syncedDevices.Count / $allFloor6.Count) * 100, 1)

Write-Host "Floor 6 Device Sync Status:"
Write-Host "Total Devices: $($allFloor6.Count)"
Write-Host "Synced in Last 30 min: $($syncedDevices.Count)"
Write-Host "Sync Percentage: $syncPercentage%"

if ($syncPercentage -ge 90) {
    Write-Host "✓ PASSED: 90%+ of devices synced"
    exit 0
} else {
    Write-Host "✗ FAILED: Only $syncPercentage% synced (need 90%+)"
    Write-Host "`nDevices NOT recently synced:"
    $allFloor6 | Where-Object { $_.LastSyncDateTime -lt $recentSyncTime } | 
        Select-Object DeviceName, LastSyncDateTime | Format-Table
    exit 1
}
```

**Expected Result:** "PASSED: 90%+ of devices synced"

**Portal Verification (if command not available):**
- Location: https://intune.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/Windows/allDevices
- Navigate: Devices > Windows devices > Add filter
- **Filter:** Device name contains "FLOOR6"
- **Check column:** "Last check-in" — should show timestamps within last 30 minutes for 90%+ of devices
- If <90% recent: Wait 15 minutes and recheck

---

## Verification Summary
**All 4 checks must show ✓ PASSED:**
- V-1: Assignment removed ✓
- V-2: App uninstalled on devices ✓
- V-3: Login time normal (<90 sec) ✓
- V-4: 90%+ devices synced ✓

**If any check shows ✗ FAILED → Proceed to Rollback section**

---

## 7. Rollback

**Execute ONLY if one or more Verification checks fail:**
- V-2 fails (app still installed on devices after 15 min wait)
- V-3 fails (users still report >120 sec login times after retest)
- V-4 fails (<90% of devices synced after 60 min)

**Total Rollback Time:** 5-10 minutes

---

### RB-1: Force Re-Sync on Non-Responsive Devices (if V-4 fails)
**Scenario:** <90% of devices synced after 60 minutes

**Command (PowerShell):**
```powershell
# Identify Floor 6 devices that haven't synced in last 60 minutes
$oneHourAgo = (Get-Date).AddMinutes(-60)
$nonSyncedDevices = Get-MgBetaDeviceManagementManagedDevice -Filter "contains(deviceName, 'FLOOR6')" -All | 
    Where-Object { $_.LastSyncDateTime -lt $oneHourAgo }

if ($nonSyncedDevices.Count -eq 0) {
    Write-Host "✓ All Floor 6 devices synced within last 60 minutes"
    exit 0
}

Write-Host "Found $($nonSyncedDevices.Count) devices not synced in 60 min. Triggering retry..."

# Trigger sync on each non-responsive device
foreach ($device in $nonSyncedDevices) {
    try {
        Invoke-MgBetaDeviceManagementManagedDeviceSync -ManagedDeviceId $device.Id -ErrorAction Stop
        Write-Host "✓ Sync triggered on $($device.DeviceName)"
    } catch {
        Write-Host "✗ Failed to trigger sync on $($device.DeviceName): $_"
    }
}

Write-Host "Waiting 5 minutes for sync to complete..."
Start-Sleep -Seconds 300

# Re-check sync status
$updatedSync = Get-MgBetaDeviceManagementManagedDevice -Filter "contains(deviceName, 'FLOOR6')" -All
$recentSync = $updatedSync | Where-Object { $_.LastSyncDateTime -ge $oneHourAgo }
$finalPercentage = [math]::Round(($recentSync.Count / $updatedSync.Count) * 100, 1)

Write-Host "Updated sync percentage: $finalPercentage%"
if ($finalPercentage -ge 90) {
    Write-Host "✓ RESOLVED: 90%+ devices now synced"
    exit 0
} else {
    Write-Host "✗ ESCALATE: Still below 90% sync after retry. Escalate to Intune support."
    exit 1
}
```

**Expected Result:** Sync percentage increases to 90%+

**Portal Alternative (if command unavailable):**
- Location: https://intune.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/Windows/allDevices
- Navigate: Devices > Windows devices > add filter "Device name contains FLOOR6"
- Manually select 5-10 devices with oldest "Last check-in" timestamps
- Click each device > **Sync** button > confirm
- Wait 5 minutes, refresh page, verify Last check-in updated

---

### RB-2: Re-Deploy App (if Removal Made Things Worse)
**Rare scenario:** If app removal caused WORSE outage (0% login success vs 50% before)

**Criteria for executing RB-2:**
- V-3 shows login FAILURES (not just slow) after app removal
- AND V-3 baseline before removal was 50%+ success rate
- Then: App might have been compensating for another issue; re-deploy and escalate to vendor

**Command (PowerShell):**
```powershell
$app = Get-MgBetaDeviceAppManagementMobileApp -Filter "displayName eq 'Document Management System'" -ErrorAction Stop
$group = Get-MgGroup -Filter "displayName eq 'Floor6-Legal'" -ErrorAction Stop

# Re-create assignment
$assignmentBody = @{
    "@odata.type" = "#microsoft.graph.mobileAppAssignment"
    intent = "Required"
    target = @{
        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
        groupId = $group.Id
    }
}

$assignment = New-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -BodyParameter $assignmentBody -ErrorAction Stop
Write-Host "✓ App re-assigned to Floor6-Legal"
Write-Host "Assignment ID: $($assignment.Id)"
Write-Host "Devices will re-download app within 15-30 minutes"
```

**Expected Result:** App assignment re-created; devices begin re-installation

**Action:** Simultaneously proceed to RB-3 (escalate to vendor for hotfix)

---

### RB-3: Escalate to Application Vendor (if App Uninstall Fails or Login Still Fails)
**Execute if:** V-2 fails (app still installed after 30+ min) OR V-3 fails (login still >120 sec)

**Contact Information Needed:**
- Document Management System vendor support email/phone
- Your Intune tenant ID: `(Get-MgContext).TenantId`
- Your Azure subscription ID

**Information to Provide to Vendor:**
```
Incident Report: Login Delay After Document Management System v2.0 Deployment

1. Environment Details
   - Platform: Windows 11 Intune-managed devices
   - Tenant: [your Intune tenant ID]
   - Deployment method: Intune Win32 app assignment to group "Floor6-Legal"
   - Deployment date/time: 2026-08-10 16:10 UTC
   - App version: Document Management System v2.0

2. Symptoms
   - Affected users: 45 (Floor 6 Legal department)
   - Login behavior: Blocked/delayed 10-30+ minutes after deployment
   - Symptoms appeared: Monday 09:00 UTC (40 hours post-deployment)
   - No symptoms on unaffected devices

3. Diagnostics (Attach if available)
   - Windows Event ID 1000 crash logs (faulting module: dms*.dll)
   - Security.evtx Event ID 4625 (failed logon) with 30+ min gap before 4624 (success)
   - Device: FLOOR6-LGL-001, FLOOR6-LGL-002, etc.

4. Resolution Attempted
   - Uninstalled app via Intune assignment removal
   - Status: [PENDING / SUCCESSFUL]
   - If PENDING: App still present on devices despite uninstall command

5. Request
   - Hotfix for startup delay issue
   - OR: Workaround (registry key, config file, app flag)
   - OR: Rollback to v1.9 if v2.0 has known regression
```

**Next Steps:** Vendor responds with hotfix or rollback option; redeploy after testing

---

## Rollback Summary
**Execute RB steps in order:**
- **RB-1:** If V-4 fails (sync issue) → Retry device sync
- **RB-2:** If V-3 fails with login FAILURE (worse than before) → Re-deploy app + escalate
- **RB-3:** If V-2 fails (app won't uninstall) OR V-3 still fails (login remains broken) → Vendor escalation

**After rollback action:** Return to Verification section; all 4 checks must pass before closing incident

---

## 8. Preventive

**Specific Process and Tooling Changes to Stop Recurrence:**

### P-1: Implement Pre-Deployment Login Performance Smoke Test (Mandatory Gate)
**Timing:** Before broad rollout (after 24h pilot validation)  
**Owner:** Release Engineer (validates test execution); Application Deployment team (provides app build)  
**Automation:** Automated PowerShell test via CI/CD pipeline

- **WHO executes:** Release Engineer runs automated test from management workstation or CI/CD system
- **WHEN it fires:** Post pilot deployment (Stage 1, 24 hours after app install on pilot devices)
- **HOW it measures:** Script connects to Intune, retrieves pilot device names, remotely triggers login performance measurement via Device-side PowerShell Remoting or Intune Remediation script: measures time from Windows login credential submit to `explorer.exe` process ready (observable via PowerShell script via WMI performance counters)
- **Pass/Fail Criteria:** 
  - **PASS:** Login time ≤ 90 seconds for 100% of pilot devices AND no pilot user reports >120 sec delays
  - **FAIL:** Any pilot device with login time > 120 seconds OR any pilot user reports blocking/failure → BLOCK Stage 2 release
- **If fails:** Release Engineer escalates to Application Deployment team + app vendor; creates high-priority ticket; deployment paused until vendor provides fix or v-rollback approved

**Tool/Location:** [REQUIRES: CI/CD pipeline integration point] Intune remediation script or standalone PowerShell script in deployment workflow; location: Apps > All apps > [App name] > Remediation scripts tab (or deployment checklist pre-approval step)

### P-2: Mandate Rollback Testing Before Production Approval
**Timing:** Before Stage 1 pilot deployment  
**Owner:** Application Deployment team (test execution + documentation); Change Advisory Board (approval gate)  
**Automation:** Manual test on pilot devices; could be automated via Intune app deployment ring simulation

- **WHO executes:** Application Deployment engineer on 2 test devices in lab or pre-prod Intune tenant
- **WHEN it fires:** Pre-deployment; before requesting CAB approval for Floor 6 deployment
- **HOW it measures:** Engineer documents and performs: (1) Install app on test device via Intune app assignment, (2) Measure login time baseline (device login 5 times, record average), (3) Remove app assignment, force sync, wait 10 minutes, (4) Measure login time post-removal (device login 5 times, record average)
- **Pass/Fail Criteria:**
  - **PASS:** Post-removal login time ≤ baseline + 10% (e.g., if baseline = 50 sec, post-removal must be ≤ 55 sec) AND app not present in "Installed apps" list after sync
  - **FAIL:** Post-removal login time > baseline + 10% OR app still present after uninstall → Reject deployment; request app vendor investigation
- **If fails:** Block change request approval; create vendor ticket with test results and device Event ID 1000 logs

**Enforcement:** CAB will not approve deployment without signed test results PDF attached to change ticket showing both baseline and post-removal timings

### P-3: Avoid Friday Afternoon Broad Rollouts for High-Impact Cohorts
**Timing:** Pre-deployment (at change request submission)  
**Owner:** Change Advisory Board (CAB) chair; Change Manager (scheduling enforcement)  
**Automation:** Automated ticket system rule; can be enforced via workflow rules in ServiceNow/Jira

- **WHO executes:** Change Manager validates deployment schedule against policy; CAB chair approves/rejects based on timing
- **WHEN it fires:** When change request submitted for production deployment to Floor 6, Finance, C-suite, or other business-critical departments
- **HOW it measures:** Change request timestamp + deployment window (from ticket); if deployment window includes Friday 2 PM - 5 PM, ticket flags for CAB review
- **Pass/Fail Criteria:**
  - **PASS:** Deployment scheduled before 2 PM Friday OR after 5 PM Monday, with business hours CAB coverage
  - **FAIL:** Deployment scheduled Friday 2-5 PM to high-impact department → Auto-reject change request unless change manager explicitly adds on-call engineer contact info and escalation phone number to ticket
- **If fails:** Change request auto-rejected with comment "High-impact Friday PM deployment violates policy; reschedule or add on-call coverage." Change submitter must resubmit with new schedule or on-call details

**Enforcement:** [REQUIRES: Ticketing system workflow rule] Workflow rule in ServiceNow/Jira that auto-rejects change requests matching (1) change category = "Software Deployment - Intune App" AND (2) target group = "Floor6-Legal" or similar AND (3) deployment start time between Friday 14:00-17:00. Override requires Change Manager + department manager sign-off.

### P-4: Implement Real-Time Login Performance Monitoring & Rollback Trigger
**Timing:** Post-deployment; active during Stage 1, 2, 3 deployments and 7 days post broad rollout  
**Owner:** Endpoint Management team (dashboard setup); Service Desk lead (alert response)  
**Automation:** Automated monitoring + alerting; manual rollback decision

- **WHO executes:** Endpoint Management engineer creates monitoring rule; Service Desk monitors alert channel during deployment window
- **WHEN it fires:** Continuously during Stage 1 (first 24h), Stage 2 (next 48h), Stage 3 (first 7 days post-broad rollout)
- **HOW it measures:** Windows Security Event Log aggregation from Floor 6 devices (Event ID 4625 count + time gap to 4624 success); queries aggregated via Azure Log Analytics or Splunk; baseline = average login time + 2 standard deviations from 14-day pre-deployment period
- **Alert Thresholds:**
  - **WARN (Yellow):** Floor 6 average login time > baseline + 30 seconds (e.g., baseline 50 sec → alert if >80 sec)
  - **CRITICAL (Red):** Floor 6 average login time > 120 seconds OR >10 devices with login time >300 sec OR Event 4625 count increases >50% compared to baseline hour → **AUTOMATIC ROLLBACK TRIGGER**
  - **Measurement period:** 5-minute rolling window; alert if threshold hit in 2 consecutive 5-minute windows
- **If threshold hit:** Auto-alert sent to #floor6-deployment Slack channel + email to Service Desk lead + create high-priority ticket. If CRITICAL threshold: Auto-trigger execution of runbook-floor6-legal-login-app-rollback.md Resolution steps (or create approval-needed ticket for manual rollback decision)

**Data Source:** [REQUIRES: Endpoint login telemetry collection] Windows Security Event Log 4625/4624 exported from Floor 6 devices via Log Analytics agent or Windows Admin Center; forwarded to Azure Log Analytics or Splunk. Baseline calculated from 14-day pre-deployment period.

**Rollback Automation:** If CRITICAL alert fires 2x in 15 minutes, auto-execute R-1 (remove app assignment) OR create urgent ticket requiring manual approval within 5 minutes

### P-5: Expand Intune Pilot Ring Program with Explicit Pass/Fail Criteria
**Timing:** Pre-deployment through post-deployment  
**Owner:** Application Deployment team (pilot execution + criteria validation); Release Engineer (gate approval)  
**Automation:** Intune assignment templates enforce ring structure; manual validation against criteria

- **WHO executes:** Application Deployment team manages Stage 1 & 2 pilots; Release Engineer validates pass/fail criteria before advancing
- **WHEN it fires:** Every app deployment to high-impact cohorts (Floor 6, Finance, etc.); stage gates enforce minimum wait times between advances
- **HOW it measures:** Explicit pass/fail criteria checked at each stage gate (see below)

**Stage 1: IT Pilot (24 hours)**
  - **Scope:** 5-10 IT staff test devices (must include mix of device ages/models)
  - **Validation Criteria (PASS/FAIL):**
    - PASS: No login failures (Event ID 4625 count < baseline), login time < baseline + 10%, P-1 smoke test passes, 0 crash reports (Event ID 1000)
    - FAIL: Any login time >120 sec OR any app crash OR any device requires forced remediation → Hold in Stage 1; coordinate with vendor for fix or rollback decision
  - **Duration:** Must be ≥24 hours from app deployment to Stage 2 advance decision
  - **Gate Approval:** Release Engineer reviews monitoring data; approves OR holds/rejects

**Stage 2: Business Unit Pilot (48 hours)**
  - **Scope:** 10-20 volunteer users from target department (Floor 6 Legal) using real devices + real workflows
  - **Validation Criteria (PASS/FAIL):**
    - PASS: <5% of pilot users report issues, login time <90 sec on 95%+ of logins, no Service Desk tickets with keywords "slow" or "can't login", P-2 rollback test passed
    - FAIL: >5% pilot users report issues OR >10% of logins >120 sec OR 2+ Service Desk tickets about app → Hold in Stage 2; consider rollback or vendor investigation
  - **Duration:** Must be ≥48 hours from Stage 2 app deployment to Stage 3 advance decision
  - **Gate Approval:** Release Engineer + Floor 6 Business Unit Manager joint approval

**Stage 3: Broad Rollout (7-day monitoring window)**
  - **Scope:** All 45 Floor 6 Legal devices
  - **Validation Criteria (PASS/FAIL):**
    - PASS: >95% of logins successful within 90 sec, <2 new Service Desk tickets about login issues, no Event ID 1000 crashes in application logs for >90% of devices
    - FAIL: Triggers P-4 alert thresholds → Auto-rollback via P-4 or manual decision
  - **Duration:** Continuous monitoring for 7 days; if pass criteria met at day 7, incident officially closed
  - **Gate Approval:** Service Desk Lead signs off at day 7

**Enforcement:** Intune app assignment templates must include all 3 assignment rules (Stage 1 group, Stage 2 group, Stage 3 group) with explicit dates/times. Ticket workflow prevents Stage→Stage advance without documented criteria validation.

---

### P-6: Post-Deployment Validation Gate (Formal Close-Out)
**Timing:** End of Stage 3 (day 7 post-broad rollout)  
**Owner:** Service Desk Lead (validation checklist); Release Engineer (formal sign-off)  
**Automation:** Semi-automated; checklist items in ticket workflow

- **WHO executes:** Service Desk Lead compiles validation results; Release Engineer approves closure
- **WHEN it fires:** After 7-day broad rollout monitoring window (day 8)
- **HOW it measures:** Service Desk Lead runs validation checklist: (1) V-1 through V-4 from Rollback section (assignment removed verification, app uninstall verification, login performance test, device sync state), (2) Service Desk ticket queue review (count new "slow login" tickets from Floor 6 in past 7 days), (3) Event log spot-check (sample 5 Floor 6 devices for Event ID 1000 crashes)
- **Pass/Fail Criteria:**
  - **PASS:** All V-1 through V-4 checks return PASSED; <2 new Service Desk tickets about login slowness; <5% of sampled devices show Event 1000 crashes → Formally close change ticket with comment "Floor 6 Login Remediation - Stage 3 Complete"
  - **FAIL:** Any V-check fails OR >5 new tickets OR >20% devices with crashes → Create investigation ticket; remains in "Stage 3 - Monitoring" state
- **If fails:** Release Engineer and Service Desk Lead schedule post-incident review; determine if additional vendor escalation or remediation needed

**Location:** Ticket workflow > change status "Stage 3 - Monitoring" → "CLOSED - Successful" (requires checklist sign-off)

---

### P-7: Knowledge Base & Runbook Update from Incident Learnings
**Timing:** Post-closure (within 5 business days)  
**Owner:** DWP Service Delivery Manager; Author: DWP engineer who handled incident  
**Automation:** Manual documentation update; reminder via ticketing system

- **WHO executes:** Engineer who led incident remediation documents findings; Service Delivery Manager approves
- **WHEN it fires:** After formal Stage 3 closure (P-6 gate passed)
- **HOW it measures:** (1) Update existing KB articles (KB-LOGIN-PERF-001, KB-INTUNE-APP-DEPLOY) with Floor 6 incident pattern + solution, (2) Add Floor 6 login incident as case study to runbook-floor6-legal-login-app-rollback.md (version 1.1), (3) Create internal lessons-learned wiki post with root cause summary + preventive control checklist, (4) Schedule training update for junior engineers (optional: add to monthly Intune troubleshooting session)
- **Pass/Fail Criteria:**
  - **PASS:** All 4 documentation items (KB updates, runbook update, lessons-learned wiki, training plan) completed and reviewed by Service Delivery Manager within 5 business days
  - **FAIL:** <2 items completed by day 5 → Escalate to manager; set reminder for day 10
- **If fails:** Create recurring ticket "Knowledge Update Incomplete" with link to incident; assign to Service Delivery Manager

**Location:** DWP knowledge base (internal wiki); KB articles: KB-LOGIN-PERF-001, KB-INTUNE-APP-DEPLOY; runbook location: [Project]/runbook-floor6-legal-login-app-rollback.md

---

## 9. Related

**Related Incidents:**
- **2024-Q2: "Outlook Desktop Startup Delay After Intune Enrollment"** — Similar symptom pattern. Root cause: Outlook startup hook waiting on Intune compliance check. Resolution: Added Outlook to Intune compliance exclusion list. **Relevant:** Same startup-hook blocking pattern; consider compliance check interference if this incident recurs.

**Related KB Articles:**
- KB-LOGIN-PERF-001: "Troubleshooting Win11 Intune Login Performance" — General troubleshooting steps for login delays
- KB-INTUNE-APP-DEPLOY: "Intune App Deployment Best Practices" — Standard app release checklist
- KB-EVENT-LOG-LOGON: "Windows Event ID 4624/4625 Interpretation Guide" — Event log deep-dive

**Related Tools/Dashboards:**
- Intune Admin Center: https://intune.microsoft.com (app assignment, device state, compliance)
- Azure AD Sign-in Logs: https://portal.azure.com/#blade/Microsoft_AAD_Identity/SecurityMenuBlade/SignIns
- Event Viewer: Local device (`eventvwr.msc`)

---

**Document Owner:** DWP Service Delivery  
**Last Updated:** 14/08/2026  
**Next Review Date:** 14/11/2026
