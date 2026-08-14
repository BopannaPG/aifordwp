# Cause Analysis: Unauthorized Client Matter Visible in Copilot

**Incident:** Floor 6 paralegal reports seeing confidential client matter in Copilot without claimed access  
**Evidence:** 1 paralegal, Monday morning report, ~72 hours after app deployment, recent Win11 migration  
**Security Risk:** Attorney-client privilege / data governance violation  

---

## Ranked Cause Hypotheses

### Cause 1 (Most Probable): Access Control Misconfiguration During Win11/Intune Migration

**Why it fits the evidence:**
- Floor 6 was "recently migrated" to Win11 + Intune (exact date: to confirm, but likely within past 2-4 weeks)
- Windows migrations often involve identity/permissions re-sync: on-premises groups → Azure AD groups, legacy file share ACLs → SharePoint permissions
- Migration timing + recent app deployment = high likelihood of permission drift or incomplete migration of access controls
- Paralegal's statement "I swear I've never had access" is consistent with accidental/default assignment post-migration
- New Document Management System app deployed Friday could have triggered Intune device sync that re-applied migrated (but incorrect) permissions

**Security signal to identify:**
- Azure AD Audit Log: "User added to group" events for Floor 6 users during migration window
- SharePoint/OneDrive Audit Log: Permission changes to matter-related files/folders during migration or within 72 hours of app deployment
- **Search command:** `Get-AzAuditLog -Filter "Category eq 'UserManagement' and ActivityDisplayName eq 'Add member to group'" -StartTime (Get-Date).AddDays(-30) | Where-Object { $_.TargetResources.DisplayName -match 'Floor6|Matter' }`

**Fastest check to confirm or eliminate (< 5 min):**
```powershell
# Check if paralegal's user account was added to unauthorized matter-access group post-migration
$user = Get-AzADUser -Filter "userPrincipalName eq 'paralegal@finbridge.com'"

# Query groups she was added to in past 30 days
$groupsAdded = Get-AzAuditLog -Filter "ActivityDisplayName eq 'Add member to group' and TargetResources/DisplayName eq '$($user.DisplayName)'" -StartTime (Get-Date).AddDays(-30)

# Check current memberships for overly broad matter-access groups
$matterGroups = Get-MgUserMemberOf -UserId $user.Id | Where-Object { $_.DisplayName -match 'Matter-|Client-|Case-' }

Write-Host "Groups added past 30 days: $($groupsAdded.Count)"
$groupsAdded | Select-Object ActivityDisplayName, CreatedDateTime, TargetResources
Write-Host "`nCurrent matter-related groups: $($matterGroups.Count)"
$matterGroups | Select-Object DisplayName
```

**Expected result (if TRUE):**
- User was added to groups matching "Matter-*" or "Client-*" patterns within past 30 days
- Audit log shows group additions correlating with migration date or Friday app deployment
- User's current group list includes groups she has no business access to

**Expected result (if FALSE):**
- No group additions in past 30 days
- Current matter-related groups are minimal and match expected case assignments
- **Shift hypothesis focus to Cause 2 or 3**

**Specific remediation if confirmed:**
1. **Immediate:** Remove user from unauthorized matter-access groups: `Remove-AzADGroupMember -GroupId $group.Id -MemberId $user.Id`
2. **Audit:** Check all Floor 6 users for similar unauthorized group memberships (compare current assignments vs pre-migration baseline)
3. **Restore correct permissions:** Re-apply access controls based on official case assignment matrix (check with Floor 6 manager + case management system)
4. **Root cause:** Investigate migration script / permission sync logic — why were broad groups assigned? Re-run migration validation to identify other affected users

**Security signal to document:**
- Azure AD group membership drift post-migration
- Audit log entries: "Member added to group [unauthorized matter group]" with timestamp + admin account
- Count of affected users (1 confirmed; likely others)

---

### Cause 2 (Very Probable): Document Management System App Deployed with Overly Broad Default Permissions

**Why it fits the evidence:**
- New app (v2.0) deployed Friday afternoon to Floor6-Legal group in Intune
- App deployment completed 72 hours before issue reported (time for sync to complete across all devices)
- Apps often default to "Full access for all assigned group members" rather than per-user role restrictions
- If app synced permissions to local device OR Azure AD on Monday morning, user may have suddenly gained access
- Paralegal may have had app on machine since Friday, but Copilot search integration (if using app API) only became active Monday morning
- No version history available (to confirm if v2.0 is known to have permission issues)

**Security signal to identify:**
- Intune app assignment settings: Look for "Permissions" or "Access level" configuration → if set to "Required" without role-based restrictions, all assigned users get full access
- Document Management System audit logs: "User given full access to matters" or similar broad permission grant events for Floor 6 cohort on Friday afternoon or Monday AM
- **Search command:** `Get-MgBetaDeviceAppManagementMobileApp -Filter "displayName eq 'Document Management System'" | Get-MgBetaDeviceAppManagementMobileAppAssignment | Select-Object Intent, TargetGroupId, CreatedDateTime`

**Fastest check to confirm or eliminate (< 5 min):**
```powershell
# Check Intune app assignment permissions
$app = Get-MgBetaDeviceAppManagementMobileApp -Filter "displayName eq 'Document Management System'"
$assignment = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id | Where-Object { $_.Target.GroupId -match 'Floor6-Legal' }

Write-Host "App: $($app.DisplayName) | Version: $($app.DisplayVersion)"
Write-Host "Assignment Intent: $($assignment.Intent)"  # 'Required' = auto-install for all group members
Write-Host "Target Group: $($assignment.Target.DisplayName)"
Write-Host "Created: $($assignment.CreatedDateTime)"

# Check Document Management System local app for permission configuration
# (If app is installed on device, check its settings/logs)
Get-Item -Path "C:\Program Files\DocumentManagementSystem\config.ini" | Select-String "DefaultAccessLevel|PermissionLevel"
```

**Expected result (if TRUE):**
- Intune assignment shows Intent = "Required" (auto-deploys to all Floor6-Legal members)
- App config or assignment shows broad permission level (e.g., "FullAccess" or "NoRestrictions")
- App was assigned/synced Friday afternoon; permission grant timestamp correlates with deployment
- All Floor 6 users would have same access (not just the one paralegal) — but she's first to report it

**Expected result (if FALSE):**
- Assignment shows Intent = "Available" or role-based restriction
- App permissions are properly scoped (e.g., "User" or "ReadOnly")
- **Shift hypothesis focus to Cause 3**

**Specific remediation if confirmed:**
1. **Immediate:** Remove app assignment from Floor6-Legal group: `Remove-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $assignment.Id`
2. **Contact vendor:** "v2.0 deployed with overly broad default permissions. Provide configuration option to restrict access by user role or case assignment."
3. **Retest:** Vendor provides v2.0 hotfix with configurable permission scoping (e.g., "Restrict to user's assigned matters only")
4. **Redeploy:** Re-assign app with correct permission settings after vendor confirms fix
5. **Audit:** Check if app also affected file permissions on local devices (C:\Users\ParalegalName\Documents\DocumentManagementSystem\* — are all matters cached locally?)

**Security signal to document:**
- Intune app assignment: broad Intent + no permission filtering
- Audit log: "Device downloaded Document Management System v2.0 with assignment [Friday time]"
- Count of affected users (potentially all 45 Floor 6 staff, not just 1 paralegal)

---

### Cause 3 (Possible, Lower Priority): Copilot Search Interface Misconfiguration / Permission Bypass

**Why it fits the evidence:**
- Paralegal is using Copilot (likely Microsoft 365 Copilot or Azure AI Search integrated with SharePoint/OneDrive)
- Copilot search indexes content from SharePoint, OneDrive, Teams — but permission filtering may not be enforced
- If Copilot index includes all Floor 6 shared documents but doesn't filter results by user's actual permissions, user sees matters outside her access scope
- Search result does NOT mean user has actual access — just that search indexed the data and Copilot displayed it
- Timing (Monday morning report) could correlate with Copilot index update cycle or new search configuration

**Security signal to identify:**
- Copilot search configuration: Check if permission filtering is enabled or disabled
- Azure AI Search / Cognitive Search index: Confirm if it includes access control enforcement
- **Search command:** `Get-MgBetaSearchEntity | Select-Object SearchableContentExternalId, DisplayName` (lists what's indexed without user-specific filtering)

**Fastest check to confirm or eliminate (< 5 min):**
```powershell
# Check Copilot search behavior: Can user actually OPEN the document, or just see it in search results?
# This is a qualitative test — requires user interaction

# Step 1: Ask paralegal: "Can you click on the matter and open/download the document, or does it give access denied?"
# Answer: 
#   - YES (can open) = Cause 1 or 2 (user has actual access) 
#   - NO (access denied) = Cause 3 (search showing data user can't access)

# Step 2: Check Copilot search configuration
Get-MgBetaSearchConnectorConfiguration -SearchConnectorId "sharepoint" | Select-Object DisplayName, IsEnabled, IncludeAccessControl
```

**Expected result (if TRUE):**
- User can see matter in Copilot search results but **cannot click/open** the actual document
- Copilot search configuration shows IncludeAccessControl = $false or permission filtering disabled
- Search index was recently updated (Monday morning or Friday evening), coinciding with incident report timing
- Other Floor 6 users may also report seeing matters in Copilot they can't access

**Expected result (if FALSE):**
- User CAN click and open the matter document (meaning she has actual access — issue is Cause 1 or 2)
- Copilot search configuration shows permission filtering ENABLED

**Specific remediation if confirmed:**
1. **Immediate:** Disable or reduce Copilot search scope to exclude full-text content indexing of matter documents (or enable permission filtering)
2. **Index update:** Force re-index of Copilot search results with access control enforcement enabled
3. **Test:** Run search query again — matter should no longer appear in paralegal's results
4. **Notify users:** "Copilot search configuration corrected. You may no longer see matters in search results, but if you have access, you can still access them via direct link or matter management system."

**Security signal to document:**
- Copilot search index includes unfiltered matter documents
- Audit log: "Search query executed by [paralegal], returned [matter name]" with access_level = "no_access" (if available)
- False positive rate: # of search results user sees but cannot access

---

## Recommended Investigation Order

**Do in parallel (< 15 min total):**

1. **Ask paralegal the critical question:** "Can you open/download the document from the Copilot result, or does it say access denied?"
   - YES → Pursue Cause 1 or 2 (actual permission issue)
   - NO → Pursue Cause 3 (search display issue)

2. **Run Cause 1 check** (Azure AD group audit)

3. **Run Cause 2 check** (Intune app assignment settings)

**Based on results, escalate to:**
- **Cause 1 confirmed:** DWP Infrastructure Lead + Compliance (permission drift post-migration)
- **Cause 2 confirmed:** DWP Application Deployment team + Vendor (app permission misconfiguration)
- **Cause 3 confirmed:** Microsoft 365 / Azure Search team (Copilot configuration issue)

---

## Decision Tree

```
Issue: Paralegal sees client matter in Copilot

├─ Can she click and OPEN the document?
│  ├─ YES → She has actual access (Cause 1 or 2)
│  │  ├─ Check Intune app assignment (Cause 2)
│  │  │  └─ If broad permissions + Friday deployment → Cause 2 (remediate: remove/reconfigure app)
│  │  └─ Check Azure AD group memberships (Cause 1)
│  │     └─ If added to unauthorized groups post-migration → Cause 1 (remediate: remove from groups)
│  │
│  └─ NO → She does NOT have access; search showing unauthorized data (Cause 3)
│     └─ Check Copilot search configuration
│        └─ If permission filtering disabled → Cause 3 (remediate: enable filtering / re-index)
```

