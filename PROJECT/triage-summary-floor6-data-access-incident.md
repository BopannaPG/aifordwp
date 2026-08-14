# Triage Summary: Unexpected Data Access — Floor 6 Paralegal / Copilot Client Matter

**Date:** Monday 14/08/2026, ~9:30 AM  
**Reported by:** Floor 6 paralegal (name: to confirm)  
**Assigned to:** [DWP Service Desk Analyst]  
**Ticket Priority:** HIGH (potential data access violation in legal environment)

---

## Summary

Floor 6 paralegal reports seeing confidential client matter data in Copilot that she states she has no business access to.

---

## Impact

**Who:** 1 paralegal (Floor 6 Legal), potentially others affected (to confirm)  
**How many:** 1 confirmed; unknown if broader access misconfiguration (to confirm)  
**Business Urgency:** **CRITICAL**
- Legal department handles confidential client data; unauthorized access violates attorney-client privilege and data governance
- If access control is misconfigured post-migration, may affect multiple users/matters
- Risk of compliance violation (client data exposure)
- Incident requires immediate containment + documentation for Legal/Compliance team

---

## Known Facts

- **User:** One Floor 6 paralegal
- **Time:** Monday morning, 14/08/2026 (approximately 9:30 AM — to confirm exact time)
- **Access point:** "Copilot" interface (specific tool/URL: to confirm — could be Azure AI Search, Microsoft 365 Copilot, SharePoint search, or other)
- **Data exposed:** One client matter (matter name/ID: to confirm)
- **User's claim:** "I swear I've never had access to this"
- **Timing context:** User is on Floor 6, which was migrated to Windows 11 + Intune "recently" (exact date: to confirm) and received new Document Management System app Friday 13/08
- **Environment:** Floor 6 users are Intune-managed, Azure AD enrolled

## Missing Information to Gather

**URGENT (investigate within 30 min):**
1. **User's actual permissions:** Does the paralegal actually have access rights to this client matter? (Check: SharePoint permissions list, Document Management System permissions matrix, Matter access log)
2. **Which Copilot interface?** Where/how did she see the data? (URL, app name, screenshot: to confirm)
3. **Exact matter identifier:** Client name, matter ID, document title (to confirm)
4. **How she discovered it:** Did she search for it intentionally? Was it suggested? Did she click a link? (to confirm)
5. **User's prior access history:** Has she accessed this matter before? Check audit logs for past 30 days (to confirm)

**Within 2 hours:**
6. **Scope of misconfiguration:** Check if other Floor 6 users also have unexpected access to matters outside their case assignments (check 5-10 random other paralegal accounts)
7. **Access grant timeline:** When was access granted/changed? During migration, Friday app deployment, or earlier? (Check: Azure AD group membership changes, SharePoint permission audit logs, Document Management System assignment logs)
8. **Who else has access to this matter?** Who are legitimate assignees? (Check matter file, case management system)
9. **App deployment scope:** Did the new Document Management System app assign broad permissions by default? (Check: Intune app assignment settings for Floor6-Legal group)

---

## Likely Category

**Primary (most probable):** Access Control Misconfiguration  
- Post-Win11/Intune migration security group permissions not migrated correctly, OR
- New Document Management System app assigned with overly broad permissions to Floor6-Legal group
- **Evidence:** Timing correlates with migration (recent) and app deployment (Friday)

**Secondary (possible):** User confusion or prior authorization  
- Paralegal actually has access but doesn't recall assignment
- Matter was shared with her case but she doesn't recognize context

**Tertiary (lower priority but rule out):** Search index/Copilot configuration error  
- Copilot search index includes matters it shouldn't; permission controls not enforced by search interface

---

## First Diagnostic Step (Immediate — <5 min)

**Step 1: Verify actual user permissions**

**Command (PowerShell — run on admin workstation):**
```powershell
# Step 1A: Check if user is member of the matter's access group
$user = Get-AzADUser -Filter "userPrincipalName eq 'paralegal.name@finbridge.com'" 
$matterGroup = Get-AzADGroup -Filter "displayName eq 'Matter-ClientName-MatterID'" 
Get-AzADGroupMember -GroupId $matterGroup.Id | Where-Object { $_.ObjectId -eq $user.ObjectId }

# If user found above = HAS PERMISSION (result: user object returned)
# If no result = NO PERMISSION (result: blank)

# Step 1B: Check user's Intune group memberships (especially new group assignments from Friday deployment)
Get-MgUserMemberOf -UserId $user.Id | Select-Object DisplayName, Id
```

**Expected result (if MISCONFIGURATION exists):**
- User is listed as member of matter access group (contradicting her claim of no access)
- User's group memberships include new groups created during migration or app deployment

**Expected result (if NO MISCONFIGURATION):**
- User is NOT listed as member of matter group
- **Next step escalate:** Copilot search index is showing data outside permission scope (search tool misconfiguration)

**Parallel check (Manual — 2 min):**
- **Go to:** Matter file location in Document Management System (if accessible via UI)
- **Check:** Matter "Shared with" list — is paralegal's name listed?
- **Check:** Intune Admin Center > Groups > "Floor6-Legal" > Members — confirm paralegal is member; check if new permissions assigned Friday

---

## Recommended Next Actions (Based on Step 1 Result)

**If user HAS actual permissions (Step 1 shows member of group):**
- **Action:** Confirm with case/matter owner: "Is paralegal supposed to have access to this matter?"
  - **If YES:** Explain to paralegal why she has access (case assignment, etc.); close ticket as user education
  - **If NO:** User has unauthorized access — **ESCALATE TO COMPLIANCE/LEGAL.** Investigate how permissions were assigned; audit all Floor 6 user permissions for similar misconfigurations
- Create incident ticket: "Post-migration access control drift — Floor 6 users"

**If user has NO actual permissions (Step 1 shows NOT member):**
- **Action:** Copilot/search interface is bypassing access controls
- **Check:** Can she still see the matter data, or was it a one-time display?
- **Escalate to:** Azure/Microsoft 365 team; investigate Copilot search index permissions enforcement
- Create incident ticket: "Copilot search result showing unauthorized data — potential search index configuration issue"

---

## Containment (Do immediately while investigating)

1. **Do NOT delete/hide data.** Preserve evidence for audit.
2. **Document the paralegal's statement.** Screenshot/record: exact matter data displayed, time, user account.
3. **Restrict matter distribution:** If misconfiguration confirmed, consider temporarily removing matter from Copilot search index until permissions verified.
4. **Notify Legal/Compliance:** Flag as potential privilege/data governance issue; they may require formal incident report.

---

## Escalation Path

- **If access control misconfiguration confirmed:** Escalate to DWP Infrastructure Lead + Legal/Compliance Officer
- **If Copilot search configuration issue:** Escalate to Azure/Microsoft 365 team
- **If broader floor-wide permission drift:** Escalate to Change Management (connect to Floor 6 Win11 migration incident)

