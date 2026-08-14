# Root Cause Analysis: Unauthorized Client Matter Access — Floor 6 Paralegal

**Incident ID:** FLOOR6-DATA-ACCESS-20260814  
**Date of Incident:** Monday, August 14, 2026, ~9:30 AM  
**Date of Detection:** Monday, August 14, 2026, ~9:30 AM  
**Date of RCA Completion:** August 14, 2026  
**Time to Detect:** Immediate (user-reported)  
**Time to Remediate:** 27 minutes  
**Status:** RESOLVED  

**RCA Author:** DWP Service Delivery Team  
**Reviewed by:** DWP Infrastructure Lead, Compliance Officer  

---

## 1. Executive Summary

A Floor 6 paralegal reported seeing a confidential client matter in Microsoft Copilot search results that she stated she had no business access to. Investigation confirmed that during Floor 6's recent Windows 11 + Intune migration, the user was accidentally added to unauthorized matter-access security groups as a result of overly broad permission-sync logic in the migration script. This gave her access to client matters beyond her assigned cases.

**Root Cause:** Access control misconfiguration during Win11/Intune migration; migration script applied floor-wide group membership rather than preserving user-specific case assignments.

**Scope:** 1 confirmed paralegal affected; potential for other Floor 6 users to have same issue (audit pending).

**Risk:** Attorney-client privilege violation, data governance breach, compliance exposure.

**Resolution:** User removed from unauthorized groups; access verified restored to authorized matters only; audit initiated for other Floor 6 users.

**Preventive Action:** Mandatory access control audit gate within 5 business days of any large-scale permission migration.

---

## 2. Timeline of Events

| Time | Event | Details | Source |
|------|-------|---------|--------|
| ~Early August 2026 | Win11/Intune Migration Begins | Floor 6 (45 users) migrated from Windows 10 on-premises domain to Windows 11 + Intune cloud management | Migration project plan (to confirm exact start date) |
| ~[Migration Date] - 2 weeks | Migration Script Executes | Automated permission-sync script runs; migrates on-premises groups to Azure AD security groups | Migration logs (to retrieve) |
| ~[Migration Date] - 1 week | Paralegal Added to Groups | During permission sync, paralegal is added to floor-wide Matter-* groups (not user-specific case assignments) | Azure AD audit log: "Add member to group" events |
| Friday, Aug 10, 2026, 4 PM | Document Management System v2.0 Deployed | New app deployed to Floor6-Legal Intune group via app assignment; installation + permission sync to all 45 devices | Intune app deployment log |
| Friday, Aug 10, 2026, 4-6 PM | Devices Receive Assignment | Floor 6 devices sync with Intune; Document Management System v2.0 and permissions installed locally | Device sync logs (to retrieve) |
| Saturday, Aug 11, 2026 | Copilot Index Updates | Azure AD Graph and Copilot search index updated overnight; includes new matter permissions from recent group assignments | Search index update logs (to confirm) |
| Sunday, Aug 12, 2026 | (Silent) | No reports; issue not yet detected | N/A |
| Monday, Aug 14, 2026, ~9:30 AM | User Reports Issue | Paralegal opens Copilot, searches for information, sees client matter in search results; states "I swear I've never had access to this" | Service Desk ticket #[ticket ID]; user verbal report |
| Monday, Aug 14, 2026, 9:35 AM | Ticket Created | Service Desk creates CRITICAL priority ticket flagging potential data access violation | Service Desk system |
| Monday, Aug 14, 2026, 9:40 AM | Triage Begins | DWP analyst begins investigation; checks user's group memberships and access control configuration | This RCA |
| Monday, Aug 14, 2026, 9:47 AM | Hypothesis Confirmed | Verification shows paralegal is member of 8+ unauthorized Matter-* groups not matching her case assignments | Azure AD group membership audit (this RCA) |
| Monday, Aug 14, 2026, 9:50 AM | Remediation Begins | Remove user from unauthorized groups | Remediation-access-control-floor6.md, Phase 1, Step 1.3 |
| Monday, Aug 14, 2026, 9:57 AM | Remediation Complete | User removed from all unauthorized groups; Azure AD sync initiated | Step 1.3 completion |
| Monday, Aug 14, 2026, 10:07 AM | Verification | User group memberships re-checked; user now member of 2 authorized Matter-* groups only | Step 2.1 verification |
| Monday, Aug 14, 2026, 10:10 AM | Copilot Test | User re-tested in Copilot; unauthorized matter no longer appears in search results | Step 2.2 verification |
| Monday, Aug 14, 2026, 10:15 AM | Scope Audit Initiated | DWP Infrastructure Lead checks all 45 Floor 6 users for similar unauthorized group memberships | Step 3.1; results pending |
| Monday, Aug 14, 2026, 10:20 AM | Case Closed — User | User's access corrected; ticket status "Resolved" | Service Desk ticket update |

**Key Timeline Observations:**
- **Detection delay:** Issue existed since ~early August migration; not detected until Monday (72+ hours post-app deployment)
- **Root cause timing:** Problem introduced during migration, not triggered by app deployment (app deployment likely just exposed issue via Copilot integration)
- **Remediation speed:** 27 minutes from triage to verification complete

---

## 3. Supporting Evidence

### Evidence 1: Azure AD Group Membership Audit
**Source:** Azure AD Admin Center > User > Group memberships query (Step 1.1)  
**Details:**
- User `[paralegal@finbridge.com]` is member of:
  - Matter-CompanyA-Contract-2026 ✓ (Authorized; confirmed with Floor 6 manager)
  - Matter-CompanyB-Litigation-2024 ✓ (Authorized; confirmed with Floor 6 manager)
  - Matter-CompanyC-IPTransfer-2025 ✗ (Unauthorized; not in user's case assignment list)
  - Matter-CompanyD-MandatoryVendor-2026 ✗ (Unauthorized)
  - Matter-CompanyE-RealEstate-2024 ✗ (Unauthorized)
  - Matter-CompanyF-EmploymentLitigation-2026 ✗ (Unauthorized)
  - Matter-CompanyG-TaxCompliance-2026 ✗ (Unauthorized)
  - Matter-CompanyH-Bankruptcy-2025 ✗ (Unauthorized)
  - And 6 additional Matter-* groups (Total: 16 groups; expected: 2)

**Audit Log Evidence:**
- Event: "User added to group Matter-CompanyC-IPTransfer-2025"
- Timestamp: [Migration date - 1 week approximately]
- Admin: "[Service account name]" (migration script, not human admin)
- Reason: (none logged; automated process)

**Conclusion:** User was added to 14 unauthorized groups during migration by automated script; not by individual assignment decision.

---

### Evidence 2: Copilot Search Result
**Source:** User screenshot / Service Desk report  
**Details:**
- Copilot search query: "[Client name] Matter details"
- Result displayed: Document from Matter-CompanyD-MandatoryVendor-2026 (unauthorized matter)
- User able to see document title, snippet preview, access link in Copilot interface
- When user clicked link, document opened successfully (confirming user has actual access via Azure AD group, not false positive search result)

**Conclusion:** Access control failure confirmed; search result matched actual Azure AD permissions (not search permission bypass).

---

### Evidence 3: Migration Script Configuration
**Source:** Migration project documentation, script repository  
**Details:**
- Migration script name: `Migrate-OnPremGroupsToAzureAD.ps1`
- Script logic: "For each on-premises group matching pattern `FLOOR-*`, create Azure AD security group with same membership"
- Problem: On-premises group `FLOOR6-LEGAL-ALLUSERS` (intended for broad floor-wide email/Teams notifications) was migrated as security group with Matter-access permissions
- Result: All 45 Floor 6 users added to this group; group then added to all Matter-* groups for broad access

**Configuration excerpt:**
```
# On-premises group
Name: FLOOR6-LEGAL-ALLUSERS
Members: All 45 Floor 6 staff
Purpose: Email distribution, Teams channel notifications (NOT access control)

# Post-migration
Azure AD Group Name: FLOOR6-LEGAL-ALLUSERS (automatically created)
Members: All 45 Floor 6 staff (migrated)
Access Scope: Added as member of all Matter-* groups (INCORRECT; should not have been)
```

**Conclusion:** Migration script did not distinguish between notification groups (which should be broad) and access control groups (which should be specific). All Floor 6 users received access to all matters.

---

### Evidence 4: Absence of Access Control Audit Post-Migration
**Source:** Migration project documentation  
**Details:**
- Migration checklist items:
  - ✓ Devices migrated to Intune
  - ✓ Compliance policies deployed
  - ✓ Applications deployed
  - ✗ **MISSING: Access control audit** (no step to verify that group memberships matched pre-migration assignments)
  - ✗ **MISSING: Permission baseline comparison** (no before/after audit)

**Conclusion:** No control gate existed to catch permission misconfiguration before users accessed resources.

---

## 4. Five-Whys Analysis

**Level 1: Why could the paralegal see unauthorized client matter data in Copilot?**
→ Because she was a member of the Azure AD security group "Matter-CompanyD-MandatoryVendor-2025" which has permissions to that matter.

**Level 2: Why was she a member of that group?**
→ Because during the Windows 11/Intune migration, the automated permission-sync script added all Floor 6 users to all Matter-* security groups.

**Level 3: Why did the migration script add her to all Matter-* groups instead of preserving her individual case assignments?**
→ Because the migration script was configured to migrate on-premises group "FLOOR6-LEGAL-ALLUSERS" (an email distribution/notification group) into Azure AD as a security group and add it as a member of all access-control groups (Matter-* groups). The script did not distinguish between notification groups and access-control groups.

**Level 4: Why was the script configured this way?**
→ Because the migration project plan did not account for the semantic difference between notification groups (which should be broad) and access-control groups (which should be specific). The script's designers assumed "migrating FLOOR6-LEGAL-ALLUSERS" meant "give all Floor 6 staff broad access to all matter content"; no one validated that this assumption was correct against the actual access control policy.

**Level 5: Why was this assumption never validated?**
→ Because there was no access control audit gate in the migration checklist. The migration project closed without verifying that post-migration access controls matched pre-migration access controls. No baseline comparison was performed. The issue was not detected until 72+ hours later when a user noticed unexpected data in Copilot search results.

**Root Cause (Level 5):** Absence of access control audit gate post-migration; no verification that automated permission sync preserved correct user-specific access levels.

---

## 5. Root Cause Details

### Technical Root Cause
**Migration script misconfiguration:** `Migrate-OnPremGroupsToAzureAD.ps1` did not preserve the semantic meaning of on-premises groups; instead, it migrated all groups as security groups and created "flatten" relationships that gave all Floor 6 staff access to all Matter-* security groups.

### Process Root Cause
**Missing control gate:** Migration checklist lacked an "Access Control Audit" step to verify post-migration permissions matched pre-migration permissions. No baseline comparison was performed before declaring migration complete.

### Organizational Root Cause
**No definition of "migration complete" for identity/permissions:** The migration project's completion criteria did not include "verified that all user access controls remain unchanged." Infrastructure team assumed successful device migration = successful identity migration; they did not separately validate access control policies.

---

## 6. Why This Was Not Caught Immediately

**No automated monitoring of access control changes:** The organization does not have real-time monitoring to alert when a user is added to unexpected security groups (e.g., "User added to 14 groups in 10 minutes via service account = anomalous" alert).

**No audit trail review:** The migration project did not include a step to review Azure AD audit logs for suspicious group additions (e.g., bulk additions to access-control groups by service accounts).

**No user testing of access control post-migration:** The migration validation did not include manual spot-checks like "Log in as paralegal; verify you can access your assigned matters; verify you CANNOT access other matters."

---

## 7. Severity Assessment

| Severity Factor | Rating | Details |
|---|---|---|
| **Data Sensitivity** | CRITICAL | Client confidential data; attorney-client privilege; regulated in legal industry |
| **Scope of Exposure** | Contained | 1 user detected; potential 44 other users affected (audit in progress) |
| **Duration** | 72 hours | Issue existed since migration (~1 week ago); detected Monday morning |
| **Likelihood of Exploitation** | UNKNOWN | Single user reported seeing data in Copilot; unclear if data was downloaded, printed, or shared externally (to confirm with user) |
| **Compliance Impact** | HIGH | Unauthorized access to client data violates attorney-client privilege and data governance requirements |

**Overall Severity: HIGH** — Data governance/privilege violation; requires Compliance Officer notification and documentation.

---

## 8. Corrective Actions (Immediate — Already Executed)

| Action | Owner | Status | Timeline |
|--------|-------|--------|----------|
| **CA-1:** Remove paralegal from unauthorized groups | DWP Service Desk | ✓ COMPLETE | 27 minutes (Mon 9:50-10:17 AM) |
| **CA-2:** Verify Copilot access restored to authorized matters only | DWP Service Desk | ✓ COMPLETE | 2 minutes (Mon 10:10 AM) |
| **CA-3:** Audit all Floor 6 users for similar misconfiguration | DWP Infrastructure Lead | ✓ IN PROGRESS | Started Mon 10:15 AM; results due Mon 10:30 AM |
| **CA-4:** Remove all Floor 6 users from unauthorized groups (if audit finds others) | DWP Service Desk | Pending | Based on CA-3 results |
| **CA-5:** Notify Compliance Officer of incident | DWP Service Delivery Lead | Pending | Within 1 hour of CA-3 completion |

---

## 9. Preventive Actions (Long-Term — Stop Recurrence)

### P-1: Mandatory Access Control Audit Gate Post-Large-Scale Migration

**Applies to:** Any migration affecting 20+ users' identity, group membership, or permission scope (Win10→Win11, on-prem→cloud, identity provider change, etc.)

**When:** Within 5 business days of migration completion (before declaring "migration successful")

**Process:**
1. Export pre-migration access control baseline (from on-premises system): user → groups → resources mapping
2. Export post-migration current state (from Azure AD): same mapping
3. Compare: For each user, confirm their Azure AD group memberships match pre-migration assignments (tolerance: ±1 group for sync timing variations)
4. Flag: Any user with >2 standard deviations more groups than pre-migration baseline = investigation required
5. Remediate: Investigate flagged users; remove from unauthorized groups if confirmed misconfiguration
6. Sign-off: Infrastructure Lead confirms audit complete; permits migration project to close

**Tool:** PowerShell script (automation approach; see remediation-access-control-floor6.md, Step 3.1 for template)

**Owner:** DWP Infrastructure Lead

**Enforcement:** Migration project checklist includes "Access Control Audit" as mandatory step before sign-off

**Target implementation:** September 15, 2026

---

### P-2: Real-Time Monitoring of Suspicious Group Membership Changes

**What to monitor:** Detect and alert on:
- User added to 5+ groups within 1 hour (indicates bulk assignment; likely automated script)
- Service account adding user to access-control groups (e.g., Matter-* groups) without corresponding change ticket
- Group membership changes to 20+ users in one batch (indicates migration or bulk sync)

**Alert threshold:** Trigger alert if activity matches above patterns; send to Infrastructure Lead for review

**Tool:** Azure Sentinel or Azure Monitor alert rule

**Owner:** DWP Infrastructure Lead

**Target implementation:** September 30, 2026

---

### P-3: Post-Migration User Access Verification Testing

**Process:** After any large-scale migration, conduct spot-check tests:
- Select 5 random users from migrated cohort
- For each user, manually verify:
  - ✓ User can access resources they should have access to (e.g., paralegal logs in, can access their assigned case matters)
  - ✓ User CANNOT access resources they should NOT have access to (e.g., try to open a case matter not assigned to them = access denied)
- Document results; remediate any failures before declaring migration complete

**Owner:** DWP Infrastructure Lead

**Target implementation:** September 15, 2026 (before next departmental migration)

---

## 10. Lessons Learned

| Lesson | Application |
|--------|-------------|
| **Notification groups ≠ Access control groups** | When migrating identity/groups, manually review group purposes; do not auto-classify. Notification groups should be broadly membered; access-control groups should be individually scoped. |
| **Automated migrations need audit gates** | Large-scale bulk operations (adding 45 users to 14 groups each) require post-execution verification. Human review is necessary even for "fully automated" processes. |
| **Copilot search exposes access control issues** | Search tools inherit permission scope from underlying access control system; search results are an effective audit mechanism for detecting access control misconfiguration. |
| **Migration completion ≠ Validation completion** | Moving devices/identities ≠ confirming access controls are correct. Separation between "migration phase" and "validation phase" is critical. |

---

## 11. Related Incidents

**2024-Q2: Outlook Startup Delay After Intune Enrollment** — Similar timing pattern (post-migration performance degradation). Root cause: different (Outlook startup hook vs. access control), but shares theme of "migration process introduced new problem that wasn't caught by pre-deployment testing."

---

## 12. Document Control

| Field | Value |
|-------|-------|
| Document ID | RCA-FLOOR6-DATA-ACCESS-20260814 |
| Version | 1.0 |
| Status | FINAL |
| Author | DWP Service Delivery Team |
| Reviewer | DWP Infrastructure Lead |
| Reviewed | [Date: to confirm] |
| Approved by | DWP Service Delivery Manager |
| Approval Date | [Date: to confirm] |
| Next Review | 14/11/2026 or upon preventive action implementation |

