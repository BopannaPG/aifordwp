---
# Leadership Update: Floor 6 Legal Access Control Incident

**Date:** August 14, 2026  
**Incident:** Unauthorized Access to Client Cases Post-Migration  
**Status:** Remediation Complete | Prevention In Progress  
**Audience:** Leadership  

---

## What Happened

During the recent computer update (Windows 11 migration), a script error gave all 45 Floor 6 legal staff access to client cases they don't work on. The mistake happened because the migration script was designed to check group names for patterns like "all users" or "notifications" — but it didn't distinguish between communication groups (for emails) and security groups (for sensitive data access). Result: everyone got added to all 14+ case access groups instead of just their own cases.

**How we discovered it:** Three days after migration, a paralegal noticed they could search for and open a confidential case they'd never worked on. We immediately investigated and found the issue affected the entire Floor 6 team.

**Why this matters:** Client confidentiality is a legal requirement. Giving staff access to cases outside their work violates attorney-client privilege and creates regulatory risk. This required immediate remediation and reporting to compliance.

---

## What We Did (Completed)

✓ **Confirmed the problem** — Verified each staff member and documented exactly which cases they had unauthorized access to

✓ **Removed unauthorized access** — Restored each person's access to only their assigned cases (took ~40 minutes per person to do safely; now complete for all 45)

✓ **Verified the fix worked** — Confirmed via two methods: (1) checked Azure AD group memberships, (2) had representatives test Copilot search to confirm unauthorized cases no longer appear

✓ **Documented everything** — Created complete audit trail of all changes for legal and compliance review

✓ **Updated support staff** — Trained IT helpdesk on this issue so they can recognize and escalate if it recurs

---

## What Remains Open

**Prevention Controls (Being Implemented by Sept 30):**

1. **Pre-flight validation** — Before the next migration, run the script on a small test group first to catch classification errors before they affect everyone

2. **Daily monitoring** — After any future migration, daily automated checks will flag if staff have unexpected case access within the first week (currently catching issues manually takes 3–4 days)

3. **Real-time alerts** — Set up security monitoring to alert us immediately if bulk access changes happen outside of scheduled migration windows (current setup only has daily spot-checks)

4. **System integration** — Connect the migration script directly to our case management database so it sources truth from there, not from manual Excel lists that can get out of sync

5. **Training update** — Update the migration runbook and IT training materials to include lessons from this incident

---

## By the Numbers (Business Impact)

- **Affected:** 45 staff members in Floor 6
- **Duration of exposure:** 3 days (from Aug 10 migration to Aug 13 discovery)
- **Cases impacted:** 14+ client matters
- **Remediation time:** 40 minutes per person; completed day 1 (Aug 14)
- **Prevention controls:** 5 total; 3 can launch by mid-September, 2 require tooling by end-September

---

## Why This Happened (Root Cause)

The migration script was built to detect and migrate security groups based on naming patterns, but it had a flaw: it treated all group-name matches the same way. A notification group named "Floor6-All-Users" matched the pattern the same as a case-access group. Once matched, the script added that entire notification group to all case access controls without checking whether that was correct.

**Fix:** The script now requires manual review before any "all users" or notification-type group gets migrated, and it verifies the action against the case management system.

---

## Confidence Level

**What we're certain about:**
- The problem is fully resolved for all 45 staff members
- No further access violations are occurring
- We can detect if this pattern happens again

**What we're still implementing:**
- Full prevention controls won't be in place until late September
- Until prevention controls are live, this type of issue could theoretically recur during future migrations if the script isn't carefully reviewed

**Risk mitigation:** We've added immediate pre-flight checks for the next scheduled migration (Sept 10). We're not migrating any other large cohorts until prevention controls are in place.

---

## Next Steps & Timeline

| Action | Owner | Target Date | Status |
|--------|-------|-------------|--------|
| Complete daily access audits (post-migration) | Access Control | Aug 20 | On track |
| Implement pre-flight validation for next migration | IT Engineering | Sept 8 | In progress |
| Launch real-time access monitoring | Security team | Sept 15 | Pending Azure Sentinel licensing approval |
| Connect case database to migration script | Infrastructure team | Sept 30 | Backlog sprint 2 |
| Update training & runbooks | IT Knowledge Manager | Aug 16 | Scheduled |

---

## Compliance Status

✓ **Remediated:** Full unauthorized access removed  
✓ **Documented:** Audit trail complete  
⏳ **Reporting:** Escalated to Compliance team for disclosure review (timeline: within 48 hours per policy)  

---

**Questions:** Contact DWP Incident Commander | For technical detail: See attached L2 troubleshooting guide

---

**Confidence Level:** HIGH (remediation complete) | Prevention controls MEDIUM (implementation ongoing)

---

**Version:** 1.0 | **Date:** August 14, 2026 | **Distribution:** Executive Leadership, Compliance Officer, Change Management Board
