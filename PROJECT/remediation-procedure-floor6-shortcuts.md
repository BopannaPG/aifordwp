# Remediation Procedure: Floor 6 Desktop Shortcuts Incident
**Version 1.0 | 14/08/2026 | Status: Ready for Execution**

---

## Hypothesis Finalized
**🔴 CONFIRMED: INTUNE POLICY — "Hide Desktop Items" Applied to Floor 6 Legal Group**

**Justification**: All 45 users affected simultaneously + Intune enrollment Friday + policy timing matches → cohort-wide scope confirms policy-driven issue, not app or migration-specific.

---

## Exact Remediation Steps (In Correct Order)

### PHASE 1: IDENTIFY & VERIFY POLICY (15 minutes)

**Step 1.1: Verify Policy on User Device** (5 minutes)
```
LOCATION: User's Floor 6 Legal device
ACTION: Open Command Prompt as Administrator
  - Press: Win+R
  - Type: cmd
  - Press: Ctrl+Shift+Enter (Run as Admin)

EXECUTE:
  gpresult /h C:\temp\gpresult.html

WAIT: 5–10 seconds for completion
OPEN: C:\temp\gpresult.html in web browser
SEARCH: Ctrl+F → Search for: "Hide" OR "Redirect" OR "Desktop"

EXPECTED FINDINGS:
  ✅ Policy name: "Hide all items on desktop" → Applied status: Yes
  ✅ Policy name: "Known Folder Redirection" → Applied status: Yes
  
EVIDENCE CAPTURE: Take screenshot showing Applied policy
```

**Step 1.2: Confirm Files Exist in File Explorer** (2 minutes)
```
LOCATION: Same user device
ACTION: Open File Explorer

NAVIGATE TO: C:\Users\[username]\Desktop

EXPECTED RESULT:
  ✅ You see .lnk files (shortcut files) in folder
  ✅ Files are present but not visible on actual desktop display

CONCLUSION IF TRUE: Files NOT deleted; hidden by policy ✓
CONCLUSION IF FALSE: Files missing → escalate to L2 Infrastructure

EVIDENCE CAPTURE: Take screenshot of File Explorer showing .lnk files
```

**Step 1.3: Verify Group Policy Processed Correctly** (1 minute)
```
LOCATION: Same device, Event Viewer
ACTION: Open Event Viewer (Admin)
  - Press: Win+R
  - Type: eventvwr.msc
  - Press: Enter

NAVIGATE TO: Windows Logs → System
SEARCH: Ctrl+F
SEARCH FOR: "Group Policy" + timestamp Friday 4 PM to Saturday 8 AM
LOOK FOR: Event ID 4098

EXPECTED FINDING:
  ✅ Event ID 4098: "Group Policy successfully processed"
  ✅ Time: Friday 13/08, 15:00–17:00 UTC or Saturday early morning
  ✅ Detail: Mentions "Hide Desktop" or "Desktop Items"

EVIDENCE CAPTURE: Take screenshot of Event ID 4098 entry
```

**Step 1.4: Identify Problematic Policy in Azure Portal** (5 minutes)
```
LOCATION: Your computer (IT Admin)
ACTION: Open https://portal.azure.com
  - Sign in with admin credentials
  - Search bar: "Device configuration"
  - Navigate: Azure Active Directory → Device Management → Device Configuration → Profiles

SEARCH: Look for policy names containing:
  "Floor 6" OR "Legal" OR "Hide" OR "Desktop" OR "Redirect"

CLICK: Policy name that matches findings from Step 1.1

EXAMINE: 
  - "Assignments" tab
  - Find: "Floor 6 Legal" group in assignment list
  - Note: Who assigned this? When? (Check policy history)

QUESTION TO ASK:
  Was this policy intentionally assigned to Floor 6 Legal?
  OR was it accidentally applied to wrong group?

EVIDENCE CAPTURE: 
  - Screenshot of policy name
  - Screenshot of "Floor 6 Legal" in assignments
  - Screenshot of policy settings (Hide Desktop = Enabled)
```

---

### PHASE 2: REMOVE POLICY ASSIGNMENT (10 minutes)

**Step 2.1: Remove Floor 6 Legal from Policy Assignment** (5 minutes)
```
LOCATION: Azure Portal (continuation of Step 1.4)
ACTION: Still viewing policy detail page

CLICK: "Assignments" tab (if not already open)

FIND: "Floor 6 Legal" in the group assignment list

CLICK: The three-dot menu next to Floor 6 Legal assignment
OR: Click "Remove" button if available directly

CLICK: "Remove"

CONFIRM: "Yes, remove this assignment"

WAIT: 15 seconds for save confirmation
VERIFY: See notification: "Assignment removed successfully" ✓

EVIDENCE CAPTURE: Screenshot showing Floor 6 removed from assignments
```

**Step 2.2: Verify Policy No Longer Targets Floor 6** (2 minutes)
```
ACTION: Refresh Azure Portal page (F5)

VERIFY: Assignments list no longer shows "Floor 6 Legal"

RESULT IF TRUE: Removal successful ✓
RESULT IF FALSE: Try removing again OR contact Azure admin for access issues
```

**Step 2.3: Trigger Policy Sync on User Device** (3 minutes)
```
LOCATION: User's Floor 6 Legal device (same as Phase 1)
ACTION: Open Command Prompt as Administrator (again)

EXECUTE:
  gpupdate /force

WAIT: 90 seconds for policy reapplication
EXPECTED OUTPUT:
  "User Policy processed successfully."
  "Computer Policy processed successfully."

RESULT IF TRUE: Policy sync complete ✓
```

---

### PHASE 3: RESTART DEVICE & VERIFY RESOLUTION (8 minutes)

**Step 3.1: Restart Device** (3 minutes restart time)
```
LOCATION: User's Floor 6 device
ACTION: Save all open work first

EXECUTE ONE:
  Option A (Command line):
    shutdown /r /t 60
    (Restart in 60 seconds)
  
  Option B (GUI):
    Start → Power → Restart

WAIT: Device restarts (~2–3 minutes)
USER LOGS IN: After restart completes

TIMING: Monitor restart from 3 min to 5 min total
```

**Step 3.2: Verify Shortcuts Reappeared on Desktop** (2 minutes)
```
LOCATION: User's restarted device
TIMING: Immediately after login

ACTION: Look at physical desktop display

EXPECTED RESULT:
  ✅ Desktop shortcuts are now VISIBLE
  ✅ No shortcuts hidden anymore
  ✅ User can see all previously missing shortcuts

RESULT IF TRUE: Resolution successful! ✓
RESULT IF FALSE: Go to Step 3.3

EVIDENCE CAPTURE: Take screenshot of desktop showing visible shortcuts
```

**Step 3.3: Verify via File Explorer (If Uncertain)** (1 minute)
```
ACTION: Open File Explorer
NAVIGATE TO: C:\Users\[username]\Desktop

VERIFY: Same .lnk files are still there

COMPARE:
  Before (Step 1.2): Files present but hidden
  After (Step 3.2): Files present AND visible on desktop display

CONCLUSION: Policy removal successful ✓
```

**Step 3.4: Confirm No Hide/Redirect Policies Remain** (1 minute)
```
ACTION: Run gpresult again
EXECUTE: 
  gpresult /h C:\temp\gpresult-after.html

OPEN: File in browser
SEARCH: Ctrl+F → "Hide" OR "Redirect" OR "Desktop"

EXPECTED: No matching policies found
  (Or if found, they show "Not Applied" status)

EVIDENCE CAPTURE: Screenshot showing no Hide/Redirect policies
```

---

### PHASE 4: ROLLBACK TO ENTIRE COHORT (30 minutes for 45 users)

**Step 4.1: Remove Policy from All Floor 6 Users** (Completion of Phase 2.1)
```
LOCATION: Azure Portal
CONFIRM: You've already removed Floor 6 Legal from the policy

RESULT: Policy no longer applies to ANY Floor 6 device
SYNC TIME: Intune syncs to all 45 devices within 15–30 minutes
```

**Step 4.2: Monitor Policy Sync Across Cohort** (15 minutes passive monitoring)
```
LOCATION: Azure Portal
NAVIGATE TO: Intune → Devices → All Devices
FILTER BY: "Floor 6" OR Floor 6 tag

CHECK: "Last check-in" timestamp for each device
  - Devices with check-in within last 15 min = policy sync likely in progress
  - Devices offline = policy will sync when they log in

OPTIMAL: Check at 15 min, 30 min marks
EXPECTED: 80–100% of devices checked in and synced within 30 minutes
```

**Step 4.3: Collect Confirmation from Floor 6 Team** (5 minutes preparation)
```
PREPARE MESSAGE:
  To: Floor 6 Legal team lead / All Floor 6 staff
  Subject: Desktop Shortcuts Restored — Issue Resolved

  Message Content:
  ---
  We've identified and resolved an Intune policy that was hiding desktop 
  shortcuts. The policy has been removed from all Floor 6 devices.
  
  Expected Timeline: Shortcuts should appear on your desktop by [HH:MM].
  
  What You Should See:
  ✅ Restart your PC (if not already restarted this morning)
  ✅ Desktop shortcuts appear normally
  ✅ Click shortcuts to open case files as usual
  
  If You DON'T See Shortcuts After Restart:
  1. Wait 10 minutes (policy may still be syncing)
  2. Restart PC again
  3. Call IT Helpdesk at [ext] if still missing
  
  No action needed from you — IT has restored your access.
  ---

SEND: Via email or Teams to Floor 6 team lead

COLLECT CONFIRMATION:
  Request: "Please confirm shortcuts are visible on your team's desktops"
  Timeline: Expect responses within 15 minutes of message
```

**Step 4.4: Log Resolution in Ticket** (5 minutes)
```
LOCATION: Service Desk ticketing system
ACTION: Update original ticket

DOCUMENT:
  ✅ Root cause: Intune policy "Hide Desktop Items" applied to Floor 6 Legal
  ✅ Remediation: Removed Floor 6 from policy assignment
  ✅ Verification: Shortcuts visible on 3+ test devices
  ✅ Rollback: Policy sync complete to all 45 devices (15–30 min)
  ✅ User confirmation: Floor 6 team confirmed shortcuts restored
  ✅ Ticket status: RESOLVED

ATTACH EVIDENCE:
  - Screenshot from Step 1.1 (policy applied)
  - Screenshot from Step 3.2 (shortcuts visible)
  - Screenshot from Step 3.4 (no Hide policies remain)
  - Floor 6 team confirmation message

CLOSE TICKET: Mark as RESOLVED
```

---

## Verification Checklist (Post-Remediation)

| # | Check | Pass Criteria | Evidence | Status |
|---|-------|---------------|----------|--------|
| 1 | Policy Removed | Floor 6 group no longer in assignment list | Azure Portal screenshot | ☐ |
| 2 | Desktop Visible | Shortcuts appear on desktop after restart | Desktop screenshot | ☐ |
| 3 | Files Intact | .lnk files still exist in File Explorer | File Explorer screenshot | ☐ |
| 4 | Policy Report | `gpresult` shows no Hide/Redirect policies | gpresult.html screenshot | ☐ |
| 5 | Event Verification | Event 4098 shows policy processed after removal | Event Viewer screenshot | ☐ |
| 6 | Shortcuts Functional | User can click shortcut to open file/app | User confirmation | ☐ |
| 7 | Cohort-Wide Sync | No new tickets from Floor 6 in 2-hour window | Service Desk ticket log | ☐ |
| 8 | Team Confirmation | Floor 6 team lead confirms all users have shortcuts | Email/Teams message | ☐ |

**Resolution Complete When**: ALL 8 checks marked ☐ (completed)

---

## Preventive Actions (Stop This Recurring)

### PA-1: Policy Intent & Scope Documentation
**Owner**: Intune Administrator  
**Timeline**: Implement by 21/08/2026  
**Action**: Every Intune policy MUST have documented:
```
POLICY DESCRIPTION FORMAT:
========================================
INTENT: Why does this policy exist?
  Example: "Hide desktop to reduce clutter for Executive Office only"

TARGET GROUPS: Who should receive this policy?
  Example: "Executive Office group ONLY"

EXCEPTIONS: Who should NOT receive this policy?
  Example: "Legal, Finance, HR excluded. Floor 6 excluded."

CREATED BY: [Admin name]
APPROVED BY: [Manager name]
DATE: [YYYY-MM-DD]
========================================
```
**Pass Criteria**: 100% of production policies have this documentation

---

### PA-2: Approval Gate Before Policy Assignment
**Owner**: Infrastructure Lead  
**Timeline**: Implement by 21/08/2026  
**Action**: Before applying policy to NEW group:
```
1. Create ticket with template:
   - Policy Name
   - Current Target Groups
   - Proposed NEW Target Groups (Floor 6 Legal?)
   - Policy Intent (read from policy description — PA-1)
   - Impact (what does policy do to desktop/device)
   
2. Infrastructure Lead reviews & approves:
   ✅ "Approved. This policy is correct for Floor 6 Legal."
   OR
   ❌ "Rejected. Do NOT apply to Floor 6 Legal."
   
3. Only assign policy if APPROVED

4. Attach approval screenshot to ticket as audit trail
```
**Pass Criteria**: 100% of policy assignments have approval ticket with manager sign-off

---

### PA-3: Pilot Testing Before Production Deployment
**Owner**: DWP Engineer  
**Timeline**: Implement by 01/09/2026  
**Action**: Test policy on 2–3 pilot users BEFORE rolling out to 45:
```
1. Create test group: "Floor 6 Legal — Pilot"
   (Add 2–3 IT staff or willing volunteers)

2. Assign policy to pilot group FIRST (not production)

3. Wait 24 hours; test on pilot devices:
   ✅ Intended effect works (shortcuts hidden)
   ✅ No side effects (no app crashes, permission errors)
   ✅ User experience acceptable (no confusing messages)

4. Document findings:
   - Test date, pilot users, policy name
   - Results (PASS/FAIL), screenshots
   - Any issues found

5. Only expand to production (45 users) if test PASS
   OR modify policy if test FAIL
```
**Pass Criteria**: 100% of new policies tested on pilot group before production; test report in ticket

---

### PA-4: Post-Deployment Baseline Audit
**Owner**: Access Control Team  
**Timeline**: Implement by 01/09/2026  
**Action**: 24 hours after deployment, audit device state:
```
1. Compare BEFORE vs. AFTER policy deployment:
   - Device settings
   - User group memberships
   - Application availability
   - Desktop display state

2. Look for anomalies:
   ❌ Unexpected changes
   ❌ Missing apps
   ❌ Error messages
   ❌ Permission failures

3. If anomalies found:
   - Create HIGH incident immediately
   - Escalate to Infrastructure
   - Do NOT deploy policy to more groups

4. If no anomalies:
   - Log result: "Policy [name] to Floor 6 — Baseline audit PASS"
   - Close deployment ticket
```
**Pass Criteria**: Baseline audit runs for every new policy; 0 undetected anomalies

---

### PA-5: Intune Policy Quarterly Audit
**Owner**: Security Operations  
**Timeline**: Implement by 01/10/2026 (recurring every 90 days)  
**Action**: Every quarter, audit ALL active Intune policies:
```
1. Run query on all policies:
   - Policy name
   - Assigned groups (current)
   - Policy intent & scope (from PA-1 documentation)

2. Verify each assignment:
   ✅ Is assignment correct? (matches documented scope)
   ✅ Is assignment intentional? (has approval from PA-2)
   ✅ Was assignment tested? (has test report from PA-3)

3. Find errors:
   ❌ Policy assigned to unexpected group (e.g., "Hide Desktop" on Floor 6)
   ❌ No approval ticket found
   ❌ No pilot test report

4. Correct errors:
   - Remove unexpected assignments immediately
   - Flag for enforcement in future deployments

5. Document findings:
   - Audit date, policies reviewed
   - Anomalies found, corrections made
   - Present report to Infrastructure Lead for sign-off
```
**Pass Criteria**: Quarterly audit shows 0 unexpected assignments; 0 unapproved policies

---

## Summary: Remediation + Prevention

| Phase | Duration | Key Actions | Owner | Success Criteria |
|-------|----------|------------|-------|-----------------|
| **Phase 1: Identify** | 15 min | Run `gpresult /h`, Find Hide/Redirect policy | L1/L2 | Policy confirmed in gpresult output |
| **Phase 2: Remove** | 10 min | Delete Floor 6 from Azure policy assignment | Intune Admin | Floor 6 no longer listed in assignments |
| **Phase 3: Verify** | 8 min | Restart device, confirm shortcuts visible | L1/User | Desktop shows shortcuts, gpresult shows no Hide |
| **Phase 4: Rollback** | 30 min | Monitor sync to all 45 devices, collect confirmation | Intune Admin | 0 new tickets from Floor 6 in 2-hour window |
| **Prevent (PA-1)** | Ongoing | Document policy intent/scope in description | Intune Admin | 100% of policies documented |
| **Prevent (PA-2)** | Ongoing | Approval gate before assignment | Infrastructure Lead | 100% assignments have approval ticket |
| **Prevent (PA-3)** | 24 hours | Test on pilot group before production | DWP Engineer | 100% new policies tested; report in ticket |
| **Prevent (PA-4)** | 24 hours | Baseline audit after deployment | Access Control | 0 anomalies detected post-deploy |
| **Prevent (PA-5)** | 90 days | Quarterly audit of all policies | Security Ops | 0 unexpected assignments found |

