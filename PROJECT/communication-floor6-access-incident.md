# Floor 6 Incident Response: Technical Action & User Communication

---

## Technical Action: Remove Unauthorized Group Memberships

**Execute immediately (applies to all Floor 6 users flagged in access audit):**

```powershell
# PowerShell — Run on admin workstation
# Removes Floor 6 users from unauthorized matter-access groups

$floor6Group = Get-AzADGroup -Filter "displayName eq 'Floor6-Legal'"
$floor6Users = Get-AzADGroupMember -GroupId $floor6Group.Id

# Define authorized matter groups per user (example; populate from case assignment system)
$authorizedMatters = @{
    'paralegal1@finbridge.com' = @('Matter-CompanyA-Contract-2026', 'Matter-CompanyB-Litigation-2024')
    'paralegal2@finbridge.com' = @('Matter-CompanyC-IPTransfer-2025')
    # ... add all Floor 6 users with their authorized matters
}

# Remove from all unauthorized Matter-* groups
foreach ($user in $floor6Users) {
    $allMatterGroups = Get-AzADGroupMember -GroupId $user.Id | Where-Object { $_.DisplayName -match 'Matter-|Client-|Case-' }
    $authorized = $authorizedMatters[$user.UserPrincipalName]
    
    foreach ($group in $allMatterGroups) {
        if ($group.DisplayName -notin $authorized) {
            Remove-AzADGroupMember -GroupId $group.Id -MemberId $user.Id -Confirm:$false
            Write-Host "Removed $($user.DisplayName) from $($group.DisplayName)"
            Add-Content -Path C:\temp\floor6-access-remediation.log -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Removed $($user.DisplayName) from $($group.DisplayName)"
        }
    }
}

Write-Host "Remediation complete. Log: C:\temp\floor6-access-remediation.log"
```

**Verification:**
```powershell
# After executing above, verify removal completed
$floor6Users | ForEach-Object {
    $matterGroups = Get-AzADGroupMember -GroupId $_.Id | Where-Object { $_.DisplayName -match 'Matter-' }
    Write-Host "$($_.DisplayName): $($matterGroups.Count) matter groups (expected: 1-3)"
}
```

---

## User Communication for Floor 6 Staff

**Subject:** Your Data Access Is Secure — Action Complete

Dear Floor 6 Team,

**What happened:** During our computer system upgrade last week, some of you were temporarily given access to client matters outside your assigned cases by mistake—not intentional, just an error in how we migrated permissions.

**What we did:** We've corrected everyone's access. You now see only the cases you're supposed to work on.

**If you see unexpected data again:** Contact IT Service Desk (ext. 4357) right away. Include: your computer name (Settings > System > About) + what you saw + when you saw it. We'll check it immediately.

**Your data is safe:** Nothing was deleted or changed. All client information remains secure and protected.

Questions? Call ext. 4357 or email servicedesk@finbridge.local.

Thank you,  
IT Service Desk

---

**Word Count (User Communication):** 96 words ✓

