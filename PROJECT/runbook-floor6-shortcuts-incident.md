# Runbook: Floor 6 Desktop Shortcuts Incident — "Hide Desktop Items" Policy Misconfiguration

| Field | Value |
|---|---|
| Title | Runbook: Floor 6 Desktop Shortcuts Incident — "Hide Desktop Items" Policy Misconfiguration |
| Version | 1.0 |
| Date | 14/08/2026 |
| Author | Bopanna |
| Reviewed | Self |
| Status | Draft |
| Change | Initial version from RCA |

---

## WHEN TO USE THIS RUNBOOK

**Symptom**: Cohort-wide report that desktop shortcuts disappeared after Intune policy deployment

**Example Ticket**: "All 45 Floor 6 Legal users report desktop shortcuts vanished after computer update"

**Root Cause**: Intune policy "Hide All Items On Desktop" applied to wrong group (Floor 6 instead of intended target)

**Expected Duration**: 30–45 minutes from start to full remediation

---

## 1. PREREQUISITES (Verify BEFORE Starting)

Use this as a **hard pre-flight gate**. Do not start remediation until every mandatory item is complete.

### 1.1 Engineer Access Checklist (Mandatory)

- ☐ You can sign in to **Microsoft Intune admin center**: https://intune.microsoft.com
- ☐ Your account has **Intune Administrator** role (required to edit policy assignments) 🔴 **ELEVATED PERMISSION**
- ☐ Backup access exists via **Global Administrator** or **Azure AD Device Administrator** (if assignment removal is blocked) 🔴 **ELEVATED PERMISSION**
- ☐ You can remotely access at least one affected endpoint as local admin (RMM/Quick Assist/Remote Desktop)
- ☐ You can open **Command Prompt (Run as administrator)** on the affected endpoint 🔴 **ELEVATED PERMISSION**
- ☐ You can open **Event Viewer** on the affected endpoint

### 1.2 Tooling Checklist (Mandatory)

- ☐ Browser session ready (Edge/Chrome) with MFA method available
- ☐ Remote support tool confirmed working to affected endpoint
- ☐ Screenshot capability available for evidence capture
- ☐ Ticketing system open for live notes
- ☐ Local working folder exists on affected endpoint for outputs:
   - `C:\temp\gpresult.html`
   - `C:\temp\gpresult-after.html`
   - `C:\temp\gpresult-debug.html` (only if rollback needed)

### 1.3 Mandatory End-User / Requester Information Checklist

Collect and confirm all items below from the end user, team lead, or service desk record **before troubleshooting**:

- ☐ Primary affected user name and UPN (example: jane.doe@contoso.com)
- ☐ Affected device hostname (example: FL6-LGL-WS-014)
- ☐ Physical location (Floor, department, business unit)
- ☐ Exact user symptom wording (example: "Desktop icons disappeared after restart")
- ☐ First observed timestamp (local time + timezone)
- ☐ Last known good timestamp
- ☐ Scope confirmation:
   - Single user
   - Multiple users
   - Entire Floor 6 cohort (~45 users)
- ☐ Confirmation that shortcuts are expected for this user role (Legal workflow requirement)
- ☐ Confirmation user restarted device at least once after issue appeared
- ☐ One sample missing shortcut name (example: `matter-2024-001.lnk`)

### 1.4 Service Desk / Incident Context Checklist

- ☐ Incident/ticket ID recorded
- ☐ Floor 6 team lead contact confirmed (email + Teams)
- ☐ Escalation contact confirmed (Intune admin/on-call infra lead)
- ☐ Change freeze or CAB constraints checked (if required by your org)
- ☐ Related incident check completed (same day, same policy, same cohort)

### 1.5 Readiness Check (Go / No-Go)

Proceed only when ALL are true:

- ☐ Access validated
- ☐ Tools validated
- ☐ End-user mandatory data captured
- ☐ Ticket opened and evidence plan ready

If any item is missing, pause and gather it first.

---

## 2. PROCEDURE (Numbered Steps, Single Action Each)

### PHASE 1: IDENTIFY & CONFIRM POLICY (10 minutes)

**Step 1.1: Confirm Files Still Exist (Eliminates Deletion Hypothesis)**

**Action**: On one affected endpoint, verify shortcuts still exist in the user profile Desktop folder.

**Specific Steps**:
1. Connect to affected endpoint using RMM/Quick Assist/Remote Desktop.
2. Sign in as support engineer with local admin rights (or request UAC approval from user).
3. Open File Explorer.
4. In address bar, paste: `C:\Users\%USERNAME%\Desktop` and press Enter.
5. If support account differs from affected user, browse to affected profile explicitly:
   - `C:\Users\<affected-user-samaccountname>\Desktop`
6. In File Explorer search box (top-right), search `*.lnk`.
7. Record count of `.lnk` files and capture screenshot.

**Expected Result After Step**:
- ✅ You see 5–15 `.lnk` files (shortcut files): case-db.lnk, matter-2024-001.lnk, etc.
- ✅ Files are present in folder but NOT visible on actual desktop display (if you look at desktop)

**If Result ✅ PASS**: Continue to Step 1.2

**If Result ❌ FAIL** (No .lnk files found, folder is empty):
- This indicates files were DELETED, not hidden
- Go to Step Rollback-5 (Files Deleted, Not Hidden)
- Do NOT continue with this runbook

---

**Step 1.2: Run Group Policy Report to Confirm Hide Policy Applied**

**Action**: Generate and inspect `gpresult` report from elevated command prompt.

**Specific Steps**:
1. On affected endpoint, press `Win+R`, type `cmd`, then press `Ctrl+Shift+Enter`.
2. Approve UAC prompt.
3. Ensure `C:\temp` exists:
   ```
   mkdir C:\temp
   ```
4. Run:
   ```
   gpresult /h C:\temp\gpresult.html
   ```
5. Wait for completion message.
6. Open report by running:
   ```
   start "" C:\temp\gpresult.html
   ```
7. In browser, use Ctrl+F and search these terms one by one:
   - `Hide`
   - `Desktop`
   - `Redirect`
   - `Known Folder`
8. In report, review policy scope/details area and confirm whether the hide-desktop setting is **Applied**.
9. Capture screenshot with policy name and applied status visible.

**Expected Result After Step**:
- ✅ Browser search finds at least ONE matching policy
- ✅ Policy name: "Hide All Items On Desktop" OR "Hide desktop icons" OR similar
- ✅ Applied status: "Applied" or "Yes" (not "Not Applied")
- ✅ Policy shows applied to group: "Floor 6" OR "Floor6-Legal" OR similar

**Screenshot**: Take screenshot of matching policy in gpresult output (evidence for ticket)

**If Result ✅ PASS**: Continue to Step 1.3

**If Result ❌ FAIL** (No Hide/Redirect policies found):
- This indicates Hypothesis #1 (Intune Policy) is NOT correct
- Check triage-summary-floor6-desktop-shortcuts.md → escalate to Hypothesis #2 or #3
- OR escalate to L2/Infrastructure for further investigation
- Do NOT continue with this runbook

---

**Step 1.3: Check Event Viewer for Policy Processing Confirmation**

**Action**: Validate Group Policy processing events in exact Windows log locations.

**Specific Steps**:
1. Press `Win+R`, type `eventvwr.msc`, press Enter.
2. In left tree, go to:
   - `Event Viewer (Local) > Windows Logs > System`
3. In right pane, click **Filter Current Log...**
4. Set filters:
   - Event sources: `GroupPolicy`
   - Event IDs: `4098,1502,1503` (include related processing IDs)
   - Logged: `Last 24 hours` (or custom incident window)
5. Click OK.
6. Sort by Date and Time (descending).
7. Open latest Event ID 4098 and review **General** and **Details** tabs.
8. Capture screenshot showing Event ID, source, timestamp, and message.
9. Optional advanced log location for deeper confirmation:
   - `Event Viewer (Local) > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational`
   - Filter by Event IDs `5312,5317,8004` for policy processing detail.

**Expected Result After Step**:
- ✅ Event ID 4098 found with timestamp Friday afternoon (13/08, 15:00–17:00 UTC) OR Saturday morning
- ✅ Event message mentions: "Group Policy successfully processed" or "User Policy processed successfully"
- ✅ Event detail contains: Policy name or group name related to "Hide" or "Desktop"

**Note**: If Event ID 4098 is from MONDAY morning → policy was just reapplied in Step 3.2; that's expected during remediation

**If Result ✅ PASS**: Hypothesis #1 CONFIRMED. Proceed to PHASE 2

**If Result ⚠️ UNCLEAR** (Can't find Event 4098):
- Event logs may have been cleared or older than 7-day retention
- Proceed to PHASE 2 anyway based on File Explorer + gpresult confirmation from Steps 1.1 & 1.2

---

### PHASE 2: REMOVE POLICY FROM FLOOR 6 (10 minutes)

**Step 2.1: Access Azure Portal & Locate Problematic Policy** 🔴 **REQUIRES: Intune Admin Role**

**Action**: Navigate to exact Intune policy path and locate the hiding policy.

**Specific Steps**:
1. On admin workstation, open browser and go to https://intune.microsoft.com.
2. Sign in with Intune Admin account.
3. In left navigation, go to:
   - `Devices > Configuration`
4. Select tab based on tenant layout:
   - `Profiles` (new UI), or
   - `Configuration profiles` (classic wording)
5. In profile list search box, search each term separately:
   - `Hide`
   - `Desktop`
   - `Icons`
6. Open candidate profile and review:
   - Overview
   - Properties
   - Assignments
7. Confirm setting path in profile includes one of:
   - `User Configuration > Administrative Templates > Desktop > Hide and disable all items on the desktop`
   - or equivalent Settings Catalog desktop hide setting
8. Record policy name, profile type, and policy ID in ticket notes.

**Expected Result After Step**:
- ✅ Search returns 1–3 policies matching keywords
- ✅ One policy should have name: "Hide All Items On Desktop" OR "Hide desktop icons" OR similar
- ✅ Assignments show: "Floor 6 Legal" group (this is the WRONG group; verify below)

**Verification**: Click policy to open it; check "Assignments" tab to confirm Floor 6 Legal is listed

**If Result ✅ PASS**: Note the policy name (write it down). Proceed to Step 2.2

**If Result ❌ FAIL** (Multiple policies found, or policy name unclear):
- Ask Intune Admin colleague for help identifying the correct policy
- Confirm with colleague: "Is this policy SUPPOSED to be assigned to Floor 6 Legal?" (Should be NO)
- Once confirmed, proceed to Step 2.2

---

**Step 2.2: Review Policy Intent & Confirm Wrong Audience** 🔴 **REQUIRES: Intune Admin Role**

**Action**: Open policy details; verify it was NOT intended for Floor 6

**Specific Steps**:
1. In selected profile, open **Properties**.
2. Capture the following fields:
   - Name
   - Description
   - Platform
   - Profile type
3. In **Assignments**, list included and excluded groups.
4. Confirm whether `Floor 6 Legal` appears under Included groups.
5. Verify intended audience from description/change record (for example, Executive Office).
6. Document decision statement in ticket:
   - `Policy intended for <target>; Floor 6 assignment is misconfiguration = YES/NO`.

**Expected Result After Step**:
- ✅ Policy description clearly states intended target (e.g., "For Executive Office staff only")
- ✅ Intended target is NOT Floor 6 Legal

**If Result ⚠️ UNCLEAR** (No description or description is vague like "reduce clutter"):
- This is EVIDENCE of missing process control (PA-1 not implemented)
- Ask Intune Admin: "Was this policy meant for Floor 6?"
- Expected answer: "No, it was meant for Executive Office"
- Document answer in ticket
- Proceed to Step 2.3

**If Result ❌ FAIL** (Description says Floor 6 IS intended target):
- This may be a DIFFERENT issue
- Escalate to Infrastructure Lead: "Policy 'Hide Desktop' intentionally assigned to Floor 6?"
- Do NOT proceed with removal until confirmed this is mistake
- If confirmed mistake, proceed to Step 2.3

---

**Step 2.3: Remove Floor 6 Legal from Policy Assignment** 🔴 **REQUIRES: Intune Admin Role**

**Action**: Delete Floor 6 group from policy assignment list

**Specific Steps**:
1. In the policy, open **Assignments** and click **Edit**.
2. Under **Included groups**, locate `Floor 6 Legal`.
3. Remove `Floor 6 Legal` from included targets.
4. Click **Review + save**.
5. Click **Save**.
6. Wait for confirmation banner: `Successfully updated assignment`.
7. Refresh page and re-open **Assignments** to verify removal persisted.
8. Capture screenshot of Assignments page after save.

**Expected Result After Step**:
- ✅ Notification appears: "Assignment removed successfully" or similar
- ✅ "Floor 6 Legal" no longer appears in assignments list
- ✅ Assignments list now shows only other target groups (e.g., "Executive Office", if any)

**Evidence**: Take screenshot of assignments list showing Floor 6 REMOVED

**If Result ✅ PASS**: Policy assignment removed. Proceed to Step 3.1

**If Result ❌ FAIL** (Removal fails with error):
- Read error message (common errors: "Permission denied" → need Intune Admin role OR "Group not found" → cached listing)
- Try refresh (F5) and attempt removal again
- If error persists, escalate to Infrastructure Lead: "Policy removal failed with error: [error message]"
- Do NOT force restart or attempt workarounds without escalation

---

### PHASE 3: TRIGGER POLICY SYNC & RESTART (15 minutes)

**Step 3.1: Force Policy Update on User Device** 🔴 **REQUIRES: Administrator Command Line Access**

**Action**: On affected device, run gpupdate command to force immediate policy reapplication

**Specific Steps**:
1. Return to affected endpoint remote session.
2. Open elevated Command Prompt (`Win+R > cmd > Ctrl+Shift+Enter`).
3. Run:
   ```
   gpupdate /force
   ```
4. Wait until both user and computer policy sections complete.
5. If prompted `Logoff or restart required`, answer `Y` only if user approved; otherwise continue to Step 3.2 where restart is already planned.
6. Capture command output screenshot.

**Expected Result After Step**:
- ✅ Command output shows:
  ```
  User Policy processed successfully.
  Computer Policy processed successfully.
  ```
- ✅ No error messages
- ✅ Command prompt returns to input (ready for next command)

**Common Output**:
- "Policy was applied. (Status code 0x00000000)"
- Takes 60–90 seconds to complete (do NOT interrupt)

**If Result ✅ PASS**: Policy sync triggered. Proceed to Step 3.2

**If Result ❌ FAIL** (Error like "Access denied"):
- User account may not have permission to run gpupdate
- Instead, proceed directly to Step 3.2 (restart device → sync happens automatically)
- Document in ticket: "gpupdate /force failed; proceeded with device restart"

---

**Step 3.2: Restart Device to Apply Policy Change**

**Action**: Restart the affected device; user logs in normally

**Specific Steps**:
1. In elevated Command Prompt, run:
   ```
   shutdown /r /t 60
   ```
2. Inform user they have 60 seconds to save work.
3. Wait for reboot to complete.
4. User signs in.
5. Wait additional 2–3 minutes after login for policy refresh and shell load.

**Alternative Method** (if user is present):
- Start → Power → Restart (GUI method)
- Or ask user to restart PC immediately

**Expected Result After Step**:
- ✅ Device restarts
- ✅ User logs in successfully
- ✅ Desktop displays (may see "Applying policies" notification for 10–30 seconds)
- ✅ Policies reapplied during restart

**Timing**: Wait 3–5 minutes for restart to complete before proceeding to Step 4.1

**If Result ❌ FAIL** (Device won't restart or login fails):
- Document error in ticket
- Ask user to try manual restart (Start → Power → Restart)
- If login fails, escalate to L2/Infrastructure: "Device failed to restart or login after policy change"

---

### PHASE 4: VERIFY RESOLUTION (8 minutes)

**Step 4.1: Confirm Desktop Shortcuts are Now Visible**

**Action**: Look at desktop on restarted device; verify shortcuts visible

**Specific Steps**:
1. After login, minimize all windows (`Win+D`).
2. Check if previously missing shortcuts are visible on desktop.
3. Press `F5` on desktop once to refresh icons.
4. If still hidden, wait 5 minutes and refresh again.
5. Capture before/after evidence if available.

**Expected Result After Step**:
- ✅ Desktop shortcuts are VISIBLE (can see icons: case-file-db, matter-2024-001, etc.)
- ✅ Shortcuts were hidden before; now visible after restart

**Evidence**: Take screenshot of desktop with visible shortcuts (proof of resolution)

**If Result ✅ PASS**: Resolution confirmed visually. Proceed to Step 4.2

**If Result ❌ FAIL** (Shortcuts still NOT visible):
- Wait additional 5 minutes (policy sync may be in progress)
- Manually restart device again (user restarts via Start → Power → Restart)
- Then re-check Step 4.1
- If still no shortcuts after second restart, go to Rollback-2 (Still Hidden After First Remediation)

---

**Step 4.2: Re-run gpresult to Confirm Hide Policy No Longer Applied** 🔴 **REQUIRES: Administrator Command Line**

**Action**: Run gpresult again; verify Hide policy is NO LONGER in list

**Specific Steps**:
1. Open elevated Command Prompt.
2. Run:
   ```
   gpresult /h C:\temp\gpresult-after.html
   ```
3. Open report:
   ```
   start "" C:\temp\gpresult-after.html
   ```
4. Search for `Hide`, `Desktop`, `Redirect`, `Known Folder`.
5. Verify hide-desktop policy is absent or marked Not Applied.
6. Save screenshot with timestamp.

**Expected Result After Step**:
- ✅ Search finds NO matching policies (or finds policies with "Not Applied" status)
- ✅ Policies list does NOT show "Hide All Items On Desktop" policy
- ✅ Indicates policy is no longer targeted to this device

**Evidence**: Take screenshot of gpresult showing NO Hide policies

**If Result ✅ PASS**: Policy confirmed removed. Proceed to Step 4.3

**If Result ❌ FAIL** (Hide policy still shows as "Applied"):
- Wait additional 5 minutes (sync delay possible)
- Run `gpupdate /force` again (Step 3.1 repeat)
- Restart device again (Step 3.2 repeat)
- Re-run gpresult (this step)
- If Hide policy STILL shows "Applied" after second attempt, escalate: "Policy removal not syncing after second attempt"

---

**Step 4.3: Check Event Viewer for Post-Remediation Policy Processing**

**Action**: Verify Event ID 4098 shows policy processed AFTER removal

**Specific Steps**:
1. Open `eventvwr.msc`.
2. Navigate to:
   - `Event Viewer (Local) > Windows Logs > System`
3. Filter Current Log:
   - Source: `GroupPolicy`
   - Event IDs: `4098,1502,1503`
   - Time window: `Last 1 hour`
4. Confirm most recent 4098 timestamp is after assignment removal and reboot.
5. Open Details tab and confirm no hide-desktop setting reapplied.
6. Also review operational channel for evidence:
   - `Event Viewer (Local) > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational`
7. Capture screenshot(s) for ticket evidence.

**Expected Result After Step**:
- ✅ Most recent Event 4098 timestamp is AFTER the policy removal (after Step 2.3)
- ✅ Event message: "Group Policy successfully processed" (without Hide policy applied)
- ✅ Confirms device re-evaluated policies; Hide policy no longer present

**Evidence**: Take screenshot of recent Event 4098 entry

**If Result ✅ PASS**: Device-level verification complete. Proceed to Step 4.4

**If Result ⚠️ UNCLEAR** (Can't see recent Event 4098):
- Event logs may rotate; not critical if Steps 4.1 & 4.2 already passed
- Proceed to Step 4.4 (user-level functional verification)

---

**Step 4.4: Test Shortcut Functionality**

**Action**: Click one shortcut; verify it opens correctly

**Specific Steps**:
1. Select one business-critical shortcut identified by user.
2. Right-click > Properties > verify Target path exists.
3. Double-click shortcut.
4. Confirm app/document/folder opens without error.
5. Record tested shortcut name and result in ticket.

**Expected Result After Step**:
- ✅ Shortcut opens without error
- ✅ Application/file displays normally
- ✅ No permission errors or "file not found" errors

**If Result ✅ PASS**: Functional verification complete. Proceed to Step 5.1 (Rollback to Entire Cohort)

**If Result ❌ FAIL** (Shortcut opens to error):
- This is likely a DIFFERENT issue (not policy-related)
- Document error in ticket
- Contact user: "Try right-clicking shortcut → Properties; does target path look correct?"
- Proceed to Step 5.1 anyway (cohort rollout); investigate shortcut error separately

---

### PHASE 5: ROLLBACK POLICY TO ENTIRE COHORT (15 minutes)

**Step 5.1: Confirm One Device Fully Remediated Before Rolling Out to All 45**

**Action**: Verify all 4 verification checks from Phase 4 show PASS

**Specific Steps**:
1. Review checklist:
   - ☐ Step 4.1 PASS: Shortcuts visible
   - ☐ Step 4.2 PASS: gpresult shows no Hide policy
   - ☐ Step 4.3 PASS: Event 4098 post-remediation
   - ☐ Step 4.4 PASS: Shortcut functions correctly

**If ANY Check ❌ FAIL**:
- Do NOT proceed to Step 5.2
- Troubleshoot failed check (repeat the step)
- Once all checks PASS, then proceed to Step 5.2

**If ALL Checks ✅ PASS**:
- Document test device name: `[device name]` in ticket
- Proceed to Step 5.2

---

**Step 5.2: Confirm Policy Removal is Permanent in Azure Portal** 🔴 **REQUIRES: Intune Admin Role**

**Action**: Re-verify in Azure Portal that Floor 6 is STILL removed from policy assignment

**Specific Steps**:
1. Open https://intune.microsoft.com.
2. Navigate: `Devices > Configuration > Profiles`.
3. Open affected policy.
4. Open Assignments.
5. Verify `Floor 6 Legal` not present in Included groups.
6. Capture screenshot.

**Expected Result After Step**:
- ✅ Floor 6 Legal group does NOT appear in assignments
- ✅ Policy is no longer targeted to Floor 6

**If Result ✅ PASS**: Proceed to Step 5.3

**If Result ❌ FAIL** (Floor 6 somehow re-appeared in assignments):
- This indicates a sync or caching issue
- Refresh Azure Portal (F5)
- Check again
- If Floor 6 still listed, escalate: "Policy removal not persisting in Azure Portal"
- Do NOT proceed to Step 5.3 until removed

---

**Step 5.3: Notify Floor 6 Team Lead to Restart Devices**

**Action**: Send message to Floor 6 team lead; request device restarts

**Specific Steps**:
1. Send email or Teams message to Floor 6 Legal team lead:
   ```
   Subject: Desktop Shortcuts Issue — ACTION REQUIRED (Simple Restart)
   
   Hi [Team Lead Name],
   
   We identified and fixed the issue causing desktop shortcuts to disappear.
   
   NEXT STEP: Please have your team restart their PCs this morning.
   
   Timeline: Restarts can happen anytime between now and 12 PM. After restart,
   shortcuts should appear automatically on desktops.
   
   If anyone still doesn't see shortcuts after restart:
   — Wait 15 minutes
   — Restart PC one more time
   — Call IT Helpdesk if still missing after 2nd restart
   
   Thanks,
   IT Infrastructure Team
   ```

2. Send this message via email or Teams (document in ticket which method used)

**Expected Result After Step**:
- ✅ Team lead receives message
- ✅ Team lead acknowledges receipt
- ✅ Users begin restarting PCs over next 2–4 hours

**Timing Note**: You do NOT need to wait for all users to restart before proceeding to Step 5.4
- Restarts will happen naturally throughout morning
- Intune will sync policy changes gradually
- Step 5.4 monitors this background process

---

**Step 5.4: Monitor Policy Sync Across All 45 Floor 6 Devices** 🔴 **REQUIRES: Intune Admin Role**

**Action**: Check Intune device list; monitor "Last Check-In" timestamps

**Specific Steps**:
1. Open https://intune.microsoft.com.
2. Navigate: `Devices > All devices`.
3. Apply filter by naming convention or group tag for Floor 6 devices.
4. Ensure **Last check-in** column is visible.
5. Set a 30-minute monitoring window and check at:
   - 10 minutes: What % of Floor 6 devices show check-in within last 15 min?
   - 20 minutes: What % of Floor 6 devices show check-in within last 20 min?
   - 30 minutes: What % of Floor 6 devices show check-in within last 30 min?
6. Export list if needed (`... > Export`) and attach to incident notes.

**Expected Result After Step**:
- ✅ At 10 min: 20–40% of devices synced
- ✅ At 20 min: 50–70% of devices synced
- ✅ At 30 min: 80–100% of devices synced
- ✅ By end: All 45 devices have recent check-in timestamp (within last 30 min)

**Evidence**: Take screenshot of device list showing check-in timestamps

**If Result ✅ PASS**: Sync complete. Proceed to Step 5.5

**If Result ⚠️ PARTIAL** (Only 60% of devices synced after 30 min):
- Remaining 40% likely offline or not yet restarted
- Devices will sync when they next restart or check-in (usually within 4 hours)
- Document in ticket: "Partial sync at 30 min (60/45 devices). Remaining will sync on next restart."
- Proceed to Step 5.5

---

**Step 5.5: Collect Confirmation from Floor 6 Team Lead**

**Action**: Ask team lead to confirm users are seeing shortcuts

**Specific Steps**:
1. Send follow-up message to Floor 6 team lead (2 hours after Step 5.3):
   ```
   Subject: Desktop Shortcuts — Confirmation Check
   
   Hi [Team Lead Name],
   
   Can you quickly confirm: Are your team members now seeing desktop
   shortcuts on their screens (after restarting their PCs)?
   
   Please reply with:
   ✓ YES — All team members report shortcuts visible
   ✓ PARTIAL — Most see shortcuts, a few don't yet (they may need restart)
   ✓ NO — Still missing for everyone (escalate immediately)
   
   Thanks,
   IT Infrastructure Team
   ```

2. Wait for response (expect within 1–2 hours)

**Expected Result After Step**:
- ✅ Team lead responds: "YES — shortcuts visible for all"
- ✅ Indicates remediation successful across cohort

**If Result ⚠️ PARTIAL** (Most see shortcuts, a few don't):
- This is normal (some devices restart later or sync delay)
- Document: "Partial user confirmation at [time]. Remaining users expected to resolve on next restart."
- Proceed to Step 6 (Close Ticket)

**If Result ❌ NO** (Shortcuts still missing for everyone):
- This indicates a problem with remediation
- Go to Rollback-4 (Cohort Still Failing After Rollout)
- Do NOT close incident

---

## 3. VERIFICATION (Junior Engineer, Click-by-Click)

Complete V-1 to V-8 in order. Record evidence for each step in the incident ticket.

### V-1 Desktop Visibility Check (Endpoint Console)

**Console location**: Affected device desktop session

1. Remote to affected device.
2. Press `Win+D` to show desktop.
3. Press `F5` once to refresh desktop.
4. Confirm expected icons are visible (for example: case-db, matter-2024-001).
5. Take screenshot named `V1-desktop-visible.png`.

**PASS**: Icons visible on desktop.
**FAIL**: Icons not visible after refresh; go to Rollback-2 quick action.

### V-2 File Presence Check (File Explorer Path)

**Console location**: File Explorer on affected device

1. Open File Explorer.
2. Go to: `C:\Users\<affected-user>\Desktop`
3. In search box, run `*.lnk`.
4. Confirm expected shortcut files exist.
5. Take screenshot named `V2-desktop-folder-lnk.png`.

**PASS**: `.lnk` files exist.
**FAIL**: Folder empty or files missing; go to Rollback-5 quick action.

### V-3 Policy Removal Check (gpresult Output)

**Console location**: Elevated Command Prompt on affected device

1. Press `Win+R`, type `cmd`, press `Ctrl+Shift+Enter`.
2. Run:
   ```
   gpresult /h C:\temp\gpresult-after.html
   ```
3. Open output:
   ```
   start "" C:\temp\gpresult-after.html
   ```
4. In browser, Ctrl+F search for: `Hide`, `Desktop`, `Redirect`, `Known Folder`.
5. Confirm hide-desktop policy is not present or status = `Not Applied`.
6. Screenshot as `V3-gpresult-after.png`.

**PASS**: Hide policy not applied.
**FAIL**: Hide policy still applied; go to Rollback-3 quick action.

### V-4 Event Log Processing Check (System Log)

**Log location 1**: `Event Viewer (Local) > Windows Logs > System`

1. Open Event Viewer: `Win+R` > `eventvwr.msc`.
2. Navigate to log location 1.
3. Click `Filter Current Log...`.
4. Set:
   - Event sources: `GroupPolicy`
   - Event IDs: `4098,1502,1503`
   - Logged: `Last 1 hour`
5. Open most recent Event ID `4098`.
6. Confirm timestamp is after policy removal time.
7. Screenshot as `V4-system-4098.png`.

**PASS**: Post-remediation GroupPolicy processing event exists.
**FAIL**: No recent event; continue to log location 2 check below.

**Log location 2 (deep verification)**: `Event Viewer (Local) > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational`

8. Filter by Event IDs: `5312,5317,8004`.
9. Confirm policy cycle occurred after remediation.
10. Screenshot as `V4-operational-grouppolicy.png`.

### V-5 Shortcut Functional Check (User Desktop)

**Console location**: Desktop shortcut properties + launch

1. Right-click one business-critical shortcut > `Properties`.
2. Confirm `Target` path exists and is reachable.
3. Double-click the same shortcut.
4. Confirm app/folder/document opens.
5. Screenshot as `V5-shortcut-opened.png`.

**PASS**: Shortcut opens without error.
**FAIL**: Target invalid or app fails; log separate app ticket and continue runbook.

### V-6 Assignment Check in Intune Portal

**Portal location**: https://intune.microsoft.com > `Devices > Configuration > Profiles > <Hide policy> > Assignments`

1. Open Intune portal.
2. Navigate to the path above.
3. Confirm `Floor 6 Legal` is not present in Included groups.
4. Screenshot as `V6-intune-assignments.png`.

**PASS**: Floor 6 removed from assignments.
**FAIL**: Floor 6 still included; go to Rollback-1 quick action.

### V-7 Cohort Sync Check in Intune Portal

**Portal location**: https://intune.microsoft.com > `Devices > All devices`

1. Filter for Floor 6 devices (name/group tag/filter).
2. Ensure `Last check-in` column is visible.
3. Count devices with check-in in last 30 minutes.
4. Capture percentage and screenshot as `V7-last-checkin.png`.

**PASS**: 80%+ checked in within 30 minutes.
**FAIL**: Below 80%; continue monitoring and follow Rollback-3 if policy remains applied.

### V-8 User Confirmation Check (Service Desk Evidence)

**Evidence location**: Ticket comments, Teams thread, or email trail

1. Send confirmation request to Floor 6 lead.
2. Record response exactly:
   - `YES` all restored
   - `PARTIAL` some pending restart
   - `NO` still failing
3. Attach response screenshot or message export.

**PASS**: `YES` or `PARTIAL` with clear restart follow-up.
**FAIL**: `NO`; execute Rollback-4 quick action.

### Verification Exit Rule

- Close technical remediation only when V-1 to V-8 are PASS.
- If any step fails, execute matching rollback quick action in Section 4 immediately.

---

## 4. ROLLBACK (3-Minute Operator Instructions)

Use this section when any verification step fails. Each rollback below is designed so the **operator can start the correct recovery action in under 3 minutes**.

### 4.0 Quick Condition Map

- V-3 shows hide policy still applied: run Rollback-3
- V-1 fails and desktop still blank: run Rollback-2
- V-2 shows empty Desktop folder: run Rollback-5
- Intune assignment edit fails (access denied): run Rollback-1
- Full cohort still failing after rollout: run Rollback-4
- No hide policy found in gpresult at all: run Rollback-0

### Rollback-0 (Under 3 Minutes): Wrong Hypothesis

**Trigger**: `gpresult` has no hide-desktop policy entries.

**Do this now**:
1. In ticket, paste: `RB-0: Hide policy not found in gpresult. Escalating to alternate hypothesis.`
2. Attach `C:\temp\gpresult.html` screenshot.
3. Escalate to L2 with subject: `RB-0 Floor 6 shortcut incident - non-policy root cause`.

**Console/log locations to cite**:
- `C:\temp\gpresult.html`
- `Event Viewer (Local) > Windows Logs > System`

### Rollback-1 (Under 3 Minutes): Permission Denied in Intune

**Trigger**: Intune save/remove assignment fails with access denied.

**Do this now**:
1. Open portal: https://intune.microsoft.com.
2. Go to `Devices > Configuration > Profiles > <Hide policy> > Assignments`.
3. Capture error banner screenshot.
4. Paste in ticket:
   - `RB-1: Permission denied removing Floor 6 Legal from <policy-name>.`
   - `Need Intune Administrator to execute assignment removal now.`
5. Mention on-call Intune admin in ticket/Teams and attach screenshot.

### Rollback-2 (Under 3 Minutes): Still Hidden After First Remediation

**Trigger**: Icons still hidden after restart.

**Do this now**:
1. On affected endpoint, open elevated `cmd` and run:
   ```
   gpresult /h C:\temp\gpresult-debug.html
   start "" C:\temp\gpresult-debug.html
   ```
2. Search in report for: `Hide`, `Desktop`, `Redirect`, `Known Folder`.
3. If second hide policy found, immediately open Intune:
   - https://intune.microsoft.com > `Devices > Configuration > Profiles`
   - Open second policy > `Assignments > Edit` > remove `Floor 6 Legal` > `Review + save` > `Save`.
4. Reboot endpoint:
   ```
   shutdown /r /t 60
   ```

**Log location to verify post-action**:
- `Event Viewer (Local) > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational`

### Rollback-3 (Under 3 Minutes): Removed in Intune, Still Applied on Device

**Trigger**: Intune assignment is removed, but V-3 still shows Applied.

**Do this now**:
1. On endpoint elevated `cmd`, run:
   ```
   gpupdate /force
   shutdown /r /t 60
   ```
2. After reboot, regenerate report:
   ```
   gpresult /h C:\temp\gpresult-after.html
   start "" C:\temp\gpresult-after.html
   ```
3. Check logs immediately:
   - `Event Viewer (Local) > Windows Logs > System`
   - Filter source `GroupPolicy`, IDs `4098,1502,1503`, time `Last 1 hour`.
4. If still applied, escalate with message:
   - `RB-3: Policy still applied after forced sync and reboot; possible policy cache or upstream processing issue.`

### Rollback-4 (Under 3 Minutes): Cohort Still Failing After Rollout

**Trigger**: Team lead reports `NO` after full cohort action.

**Do this now**:
1. Open ticket and add: `RB-4 initiated: requesting emergency desktop restore from backup for Floor 6.`
2. Send restore request to infrastructure with exact restore path:
   - `C:\Users\<affected-user>\Desktop`
   - Restore point: `13/08/2026 before 15:00 local`.
3. Attach evidence pack:
   - `V3-gpresult-after.png`
   - `V6-intune-assignments.png`
   - `V7-last-checkin.png`
4. Keep policy assignment removed in Intune until restore completes.

### Rollback-5 (Under 3 Minutes): Files Deleted, Not Hidden

**Trigger**: `C:\Users\<affected-user>\Desktop` contains no expected `.lnk` files.

**Do this now**:
1. Stop policy troubleshooting immediately.
2. Capture folder screenshot from:
   - `C:\Users\<affected-user>\Desktop`
3. Update ticket:
   - `RB-5: Desktop files deleted, not hidden. Requesting immediate backup restore.`
4. Send backup restore request with:
   - Device name
   - User name
   - Restore source time `13/08/2026 before 15:00 local`
   - Destination `C:\Users\<affected-user>\Desktop`

### Rollback Evidence Minimum (Attach Every Time)

- Intune screenshot from `Devices > Configuration > Profiles > <policy> > Assignments`
- gpresult file screenshot (`C:\temp\gpresult*.html`)
- Event Viewer screenshot from one of:
  - `Windows Logs > System`
  - `Microsoft > Windows > GroupPolicy > Operational`
- Ticket note with rollback code (`RB-0` to `RB-5`) and timestamp

---

## 5. NOTES (Edge Cases, Warnings, Related Incidents)

### Edge Case 1: Some Users Still See Shortcuts Hidden (After Removal)

**Situation**: After Phase 5 rollout, 90% of Floor 6 sees shortcuts, but 2–3 users don't

**Cause**: Device policy cache delay OR user hasn't restarted PC yet

**Action**:
1. Ask affected users to restart PCs (if not done yet)
2. Wait 15 minutes after restart
3. If still missing, run Step 4.2 on their device: Check if Hide policy still "Applied"
4. If policy still Applied → Run Rollback-3 (Force sync again)
5. If policy shows "Not Applied" but shortcuts still hidden → May be user profile cache issue; ask user to logout/login or clear browser cache (if shortcuts are app-related)

---

### Edge Case 2: Device Offline — Missed Policy Removal Sync

**Situation**: Some Floor 6 devices are offline (user on vacation, device in storage, etc.) and won't receive policy removal for 2+ weeks

**Cause**: Normal; Intune only syncs to online devices

**Action**:
1. Document in ticket: "Device [name] offline; will sync policy on next login"
2. When device comes online (user returns from vacation), it will automatically sync the policy removal
3. No manual action needed
4. Close incident after V-8 check passes for ONLINE devices

---

### Edge Case 3: Multiple Hide Policies Exist (Organization Deployed Policy Twice)

**Situation**: During Step 4.2, gpresult shows TWO separate Hide policies both applied to Floor 6

**Cause**: Organization may have deployed Hide policy to multiple groups accidentally OR policy cloned/duplicated

**Action**:
1. Document both policy names in ticket
2. Go to Azure Portal
3. Check BOTH policies for Floor 6 assignment
4. Remove Floor 6 from BOTH policies (repeat Step 2.3 for each)
5. Restart device (Step 3.2)
6. Re-verify both policies removed (Step 4.2)
7. Note in ticket: "Two Hide policies were applied to Floor 6. Both removed."

---

### Edge Case 4: User Reports "Shortcuts Hidden BUT Still Accessible Via File Explorer"

**Situation**: User complains: "I can see shortcuts in C:\Users\Desktop folder, but they're not on my actual desktop"

**Cause**: This is CORRECT behavior after remediation; user is seeing the result of hidden-to-visible transition

**Action**:
1. This is NOT a failure
2. Explain to user: "Shortcuts are in the right place (File Explorer); they're just becoming visible on your desktop display. You may need to refresh (F5) or restart once more."
3. Ask user to: Press F5 (refresh) on desktop OR restart PC once more
4. After refresh/restart, shortcuts should be visible on desktop display
5. This is V-1 check passing
6. Document in ticket: "Cosmetic display cache resolved with refresh/restart"

---

### Edge Case 5: Group Policy Applies to Multiple Cohorts

**Situation**: Hide Desktop policy assigned to multiple groups (Floor 6 Legal, Floor 3 Marketing, etc.) and only Floor 6 reports issue

**Cause**: Policy may be intentionally deployed to multiple groups (different contexts)

**Action**:
1. In Step 1.4, confirm which GROUP is actually affected (Floor 6 only? Or also Floor 3/others?)
2. If only Floor 6: Remove Floor 6 from assignment (leave others)
3. If multiple groups have same issue: Check if policy is supposed to apply to those groups
4. If all affected groups report issue, may need to remove policy completely (not just from Floor 6)
5. Escalate to Infrastructure Lead: "Hide policy removed from Floor 6. Confirm if policy should still apply to [other groups]"
6. Document in ticket: "Confirmed policy scope; removed Floor 6 only"

---

### Edge Case 6: User Clicks Shortcut But Gets "File Not Found" Error

**Situation**: After shortcuts reappear, user clicks shortcut but application won't open (file not found, path invalid, etc.)

**Cause**: Shortcut target path may be broken OR application/file moved/deleted

**Action**:
1. This is NOT a policy remediation failure
2. This is a separate troubleshooting ticket (shortcut integrity issue)
3. Document in ticket: "Shortcuts visible on desktop (V-1 PASS), but [specific shortcut] has broken target path"
4. Create NEW ticket: "Shortcut repair: [shortcut name] target path invalid"
5. V-5 check (Shortcut Functional) shows "Manual intervention needed" (not PASS but not FAIL remediation)
6. Close this incident; track shortcut repair separately

---

### Related Incidents (Similar Patterns)

**Incident Type**: Device Policy Misconfiguration

**Related Cases**:
1. **Win10→Win11 Migration (Other Departments)**: Similar pattern where migration policy misapplied to wrong cohort → [Link to other incident if exists]
2. **SharePoint Permission Misconfiguration (2024)**: Policy-based access control accidentally applied to wrong security group → [Link]
3. **Outlook Startup Delay (Q2 2024)**: Post-migration policy deployment affected unintended cohort → [Link]

**Lessons Shared**:
- Policy deployment requires approval + testing before production rollout
- Cohort-wide issues almost always indicate policy misconfiguration, not app/hardware issues
- Missing process controls enable cascading issues (first incident → multiple follow-on incidents)

---

### Warnings & Gotchas

⚠️ **WARNING 1**: Step 2.3 requires Intune Admin role
- Do NOT skip permission checks
- If you don't have role, escalate immediately (Rollback-1)
- Do NOT ask user to remove policy themselves

⚠️ **WARNING 2**: Step 3.1 (`gpupdate /force`) may take 60–90 seconds
- Do NOT interrupt or close Command Prompt early
- Wait for "User Policy processed successfully" message
- Partial sync may leave policy in inconsistent state

⚠️ **WARNING 3**: Step 4.1 verification may show shortcuts NOT reappearing immediately
- Policy cache on device can lag 5–10 minutes post-sync
- Always restart device (Step 3.2) before concluding failure
- If still missing after restart, investigate Rollback-2 or Rollback-3

⚠️ **WARNING 4**: Do NOT remove policy from Azure before verifying it's causing the issue
- Always confirm via gpresult first (Step 1.2)
- Premature removal may cause different problems if policy serves other purpose

⚠️ **WARNING 5**: Group Policy updates apply to ALL devices in group instantly
- Removing policy from Floor 6 group affects 45 devices in ~5 minutes
- If you accidentally remove policy from wrong group, re-add it immediately
- Document corrective action in ticket

---

### Escalation Contacts

**If You Get Stuck At**:
| Step | Issue | Contact | Info |
|------|-------|---------|------|
| 1.2 | Can't confirm Hide policy | L2 Engineer | May be different root cause; escalate to Hypothesis #2 or #3 |
| 2.1 | Can't find policy in Azure | Intune Admin | Check policy naming; may have been renamed or removed |
| 2.3 | Permission denied (Intune Admin role required) | Infrastructure Lead | Request colleague with Intune Admin to complete removal |
| 3.1 | gpupdate hangs or fails | L2 Infrastructure | May indicate domain controller issue or network problem |
| 4.1 | Shortcuts still hidden after restart | L2 Infrastructure | Check for second Hide policy (Rollback-2) or sync issue (Rollback-3) |
| 5.3 | Team lead can't reach users | Floor 6 Manager | May need to send direct user communication OR schedule team meeting |
| V-8 | Users still report shortcuts missing | IT Leadership + Infrastructure | May require backup restore (Rollback-4) |

---

### Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 14/08/2026 | Bopanna | Initial version from RCA |

---

### How to Use This Runbook

1. **Before Starting**: Read entire Section 1 (Prerequisites); confirm you have all access rights
2. **During Execution**: Follow Section 2 (Procedure) step-by-step; do NOT skip steps
3. **After Each Step**: Verify "Expected Result"; document finding in ticket
4. **If Anything Fails**: Refer to Section 4 (Rollback); select matching condition
5. **Before Closing**: Complete all checks in Section 3 (Verification)
6. **Questions**: Refer to Section 5 (Notes) for edge cases; escalate if not covered

---

### Quick Reference: Step Timing

| Phase | Steps | Time |
|-------|-------|------|
| Phase 1: Identify | 1.1 → 1.2 → 1.3 | 10 min |
| Phase 2: Remove | 2.1 → 2.2 → 2.3 | 10 min |
| Phase 3: Sync | 3.1 → 3.2 | 15 min (includes restart) |
| Phase 4: Verify | 4.1 → 4.2 → 4.3 → 4.4 | 8 min |
| Phase 5: Rollout | 5.1 → 5.2 → 5.3 → 5.4 → 5.5 | 15 min (monitoring) |
| **TOTAL** | | **~60 minutes** |

---

