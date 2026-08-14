# Floor 6 Incident Response: Technical Command & User Message

## TECHNICAL REMEDIATION COMMAND

Execute this command to remove the Document Management app from Floor 6 and resolve the login issue:

```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","DeviceManagementManagedDevices.ReadWrite.All"
$floorGroup = Get-MgGroup -Filter "displayName eq 'Floor6-Legal'"
$app = Get-MgBetaDeviceAppManagementMobileApp -Filter "displayName eq 'Document Management System'"
$assignment = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id | Where-Object { $_.Target.GroupId -eq $floorGroup.Id }
Remove-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $assignment.Id
$devices = Get-MgBetaDeviceManagementManagedDevice -Filter "contains(deviceName,'FLOOR6')"
foreach ($device in $devices) { Invoke-MgBetaDeviceManagementManagedDeviceSyncDevice -ManagedDeviceId $device.Id }
Write-Host "App removed and sync triggered on $($devices.Count) devices"
```

---

## MESSAGE FOR FLOOR 6 USERS

**Subject: Your login issue is fixed**

We found the problem: a new document management app deployed Friday was causing login delays. We've removed it—your login should work normally now.

**If login is still slow or you can't sign in:**
- Restart your computer
- Wait 1 hour for your device to sync with us
- If it continues, email servicedesk@finbridge.local or call ext. 4357

Thank you for your patience while we fixed this.

— IT Service Desk
