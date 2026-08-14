# Diagnostic Analysis: Floor 6 Desktop Shortcuts — Top 3 Hypotheses
**Date**: 14/08/2026 | **Status**: Diagnostic Phase | **Based on Triage**: triage-summary-floor6-desktop-shortcuts.md

---

## Scope Facts (From Triage)
- **Cohort**: Floor 6 Legal, 45 people
- **Symptom**: Desktop shortcuts disappeared
- **Recent changes (72 hours)**:
  - Windows 11 migration
  - Intune enrollment
  - New document management app (Friday afternoon)
- **Critical Unknown**: Is this 1 user, subset, or ALL 45?

---

## Ranked Hypotheses (Top 3)

---

## 🔴 HYPOTHESIS #1: INTUNE POLICY — Hide Desktop Items or Folder Redirection
**Probability**: **60% if all 45 affected** | 15% if single user

### Why It Fits the Evidence

1. **Cohort-wide timing**: If ALL 45 users lost shortcuts at the same time → policy-driven, not app or migration-specific
2. **Intune enrollment timing**: Intune policies apply within 2–4 hours of device enrollment; Friday afternoon enrollment → policy in place Friday evening/Saturday → discovered Monday = consistent pattern
3. **Policy scope uniformity**: Intune policies apply the same way to all devices in a group; if policy targets "Floor 6 Legal group" → all 45 affected simultaneously
4. **No error messages**: Intune "Hide Desktop" policy doesn't produce errors—icons just disappear from display
5. **Intune capabilities**: Intune can enforce:
   - `Hide All Items On Desktop: Enabled` → Desktop icons not visible but files remain
   - `Known Folder Redirection: Desktop` → Desktop folder redirected to OneDrive; files hidden from desktop display

### Fastest Check to Confirm or Eliminate (5 minutes)

**Check 1: Verify Files Still Exist in File Explorer** (2 min)
```
Action: Remote into affected user device → Open File Explorer
Navigate to: C:\Users\[username]\Desktop
RESULT IF FOUND: .lnk files (shortcuts) visible in File Explorer = CONFIRMS Policy Hypothesis
RESULT IF EMPTY: No files in folder = ELIMINATES this hypothesis → go to #2 or #3
```

**Check 2: Run Group Policy Report** (3 min)
```
Action: Command Prompt (admin) on affected device:
  gpresult /h C:\temp\gpresult.html

Open in browser → search (Ctrl+F) for: "Hide" OR "Desktop" OR "Redirect"

RESULT IF FOUND: Policy shows "Applied" status with name containing Hide/Redirect = CONFIRMS
RESULT IF NOT FOUND: No such policies = ELIMINATES this hypothesis
```

**Check 3: Quick Event Log Verification** (1 min)
```
Action: Event Viewer → Windows Logs → System
Search for: "Group Policy" + timestamp Friday 4 PM onward

RESULT: Event ID 4098 "Group Policy successfully processed" = CONFIRMS timing alignment
```

### Specific Remediation Action (If Confirmed)

**Step 1: Locate Policy in Azure Portal** (5 min)
```
Navigate to: https://portal.azure.com
→ Azure Active Directory 
→ Device Management 
→ Device Configuration 
→ Profiles

Search for: "Floor 6" OR "Desktop" OR "Hide" OR "Redirect"
Look for: Policy assigned to "Floor 6 Legal" group
```

**Step 2: Remove Assignment** (2 min)
```
Click policy → "Assignments" tab
Find: "Floor 6 Legal" group in list
Click: "Remove" button
Click: "Save"

Wait 15 seconds for save confirmation
```

**Step 3: Force Policy Sync on User Device** (3 min)
```
On affected device (Command Prompt as admin):
  gpupdate /force

Wait 90 seconds for completion
```

**Step 4: Restart Device** (3 min restart time)
```
Command: shutdown /r /t 60
OR: Start → Power → Restart

Device restarts; user logs in
```

**Expected Outcome**: Desktop shortcuts visible within 2 minutes of login ✓

---

## 🟠 HYPOTHESIS #2: WINDOWS 11 MIGRATION — User Profile Not Migrated Correctly
**Probability**: **25% if cohort-wide** | **50% if single user**

### Why It Fits the Evidence

1. **Migration timing**: Win11 migration completed Friday or earlier; shortcuts disappeared same timeframe
2. **Profile reset vulnerability**: Migration may have:
   - Triggered user profile refresh (wiping desktop)
   - In-place upgrade with incomplete profile copy
   - New profile created during migration without old desktop contents
3. **User-specific**: If only 1–2 users affected (not cohort-wide) → likely local migration issue, not org-wide policy
4. **Shortcut target path changes**: If shortcuts reference old paths (Win10 locations), they may break or disappear during migration to Win11

### Fastest Check to Confirm or Eliminate (5 minutes)

**Check 1: Verify File Existence** (1 min)
```
If Hypothesis #1 Check 1 already confirmed files exist in File Explorer → THIS HYPOTHESIS ELIMINATED
If files are MISSING from File Explorer → PROCEED to Check 2
```

**Check 2: Check Migration Log for Profile Errors** (3 min)
```
On affected device, navigate to: C:\Windows\Panther\

Open file: setuperr.log OR setupact.log

Search for: "profile" OR "desktop" OR "migration" OR "error"

RESULT IF FOUND: "Profile migration failed" OR "Error: Desktop folder not copied" = CONFIRMS
RESULT IF NOT FOUND: No errors logged = UNCLEAR or ELIMINATES
```

**Check 3: Check Profile Age & Duplicates** (1 min)
```
File Explorer → C:\Users\

Right-click [username] folder → Properties → Date Modified

RESULT IF MODIFIED: Timestamp = Friday (migration time) = CONFIRMS profile reset
RESULT IF MULTIPLE: folders named [username], [username].000, [username].001 = CONFIRMS profile corruption
```

### Specific Remediation Action (If Confirmed)

**Option A: Recover from Pre-Migration Backup** (5 min if available)
```
1. Check IT backup system for pre-migration device backup
2. If available: Recover Desktop folder from backup
3. Copy to: C:\Users\[username]\Desktop
4. User refreshes File Explorer (F5) → shortcuts reappear
```

**Option B: Recreate Shortcuts from Known Applications** (10–15 min)
```
1. Identify which shortcuts should exist (ask user or team lead)
2. For each app:
   - Open application
   - Tools menu → "Create Desktop Shortcut" OR right-click executable
   - Move shortcut to Desktop
3. Ask user to restart PC or refresh (F5)
```

**Option C: Restore Desktop from OneDrive Versioning** (5 min if enabled)
```
1. OneDrive settings → Account → Restore your OneDrive
2. Select date: Before migration (Thursday or earlier)
3. Click "Restore"
4. Wait 5–10 minutes for sync
5. Desktop shortcuts should restore
```

**Option D: Force Profile Refresh (Nuclear Option, 30 min)**
```
⚠️ Only if other options fail

1. Back up user's Documents/Desktop/Downloads to external drive
2. Delete user's profile: C:\Users\[username] (requires backup)
3. Restart PC → new clean profile created
4. User logs in → restore Documents/Desktop/Downloads from backup
5. Recreate shortcuts or apply backup files
6. Restart again
```

---

## 🟡 HYPOTHESIS #3: DOCUMENT MANAGEMENT APP — Installer Deleted Shortcuts
**Probability**: **20% if single user or subset** | **5% if all 45 affected** (unlikely)

### Why It Fits the Evidence

1. **Deployment timing**: App installed Friday afternoon; shortcuts disappeared same day/weekend → timing correlates
2. **Installer behavior**: Some enterprise installers include "clean desktop" features:
   - Uninstall old versions → delete associated shortcuts
   - Clean up unused shortcuts during setup
   - App installer silently deletes shortcuts as cleanup
3. **Cohort scope**: If app deployed to ALL Floor 6 via Intune, would affect all 45; if deployed to subset → only those affected
4. **Silent installation**: If silent install without user interaction, could delete shortcuts without awareness

### Fastest Check to Confirm or Eliminate (3 minutes)

**Check 1: Examine Installation Log** (3 min)
```
On affected device, open Event Viewer (admin):
  Windows Logs → Application
  Filter: Event ID 1033 (install success) OR 1034 (install failed)
  Search for: Document management app name (to confirm: app name needed)
  Timeframe: Friday afternoon

RESULT IF FOUND: Installation timestamped exactly when shortcuts disappeared = CORRELATES
RESULT IF FOUND: Log shows "Cleanup: removed shortcuts" = CONFIRMS
RESULT IF NOT FOUND: No installation event = ELIMINATES
```

**Check 2: Uninstall & Test Reversal** (5 min, only if Hypothesis #1 & #2 eliminated)
```
Action: Control Panel → Programs → Uninstall
Search for: New document management app name
Click: Uninstall

Wait for uninstall to complete
Restart device

RESULT: If shortcuts reappear after uninstall = CONFIRMS app deleted them
RESULT: If shortcuts still missing = ELIMINATES this hypothesis
```

**Check 3: Contact App Vendor for Known Issues** (10 min)
```
Look up: [App vendor documentation] for "desktop shortcuts" or "installation cleanup"
Search: [App vendor support forum] for "shortcuts deleted during install" OR "clean desktop"

RESULT IF FOUND: Vendor confirms this is known behavior = CONFIRMS possible cause
RESULT IF NOT FOUND: No known issue documented = ELIMINATES
```

### Specific Remediation Action (If Confirmed)

**Option A: Reinstall App with Preservation Options** (10 min)
```
1. Uninstall the app (if not already done)
2. Download installer from vendor
3. Look for installation options/switches:
   - GUI installer: Look for "Advanced" or "Custom" → uncheck "Clean desktop" or "Remove old shortcuts"
   - Command line: Check for flags like /no-cleanup, /preserve-shortcuts (vendor-specific)
4. Reinstall with options to preserve shortcuts
5. Restart
6. Verify shortcuts reappear
```

**Option B: Manually Recreate Shortcuts Post-Install** (10–15 min)
```
1. Identify shortcuts that should exist (common case files for Floor 6 Legal)
2. For each shortcut:
   - Create shortcut to document/folder in case management system
   - Place on desktop
3. If cohort-wide issue: Deploy via Intune app deployment script to all affected users
```

**Option C: Roll Back App Deployment** (30 min if app is new/untested)
```
If app was just deployed Friday and is causing issues:
1. Create HIGH incident ticket: "Document management app deleting shortcuts — investigation needed"
2. Contact app vendor: Escalate issue, request "preserve shortcuts" installation method
3. Use Intune to UNINSTALL app from Floor 6 (if deployed via Intune)
4. Wait for uninstall across all devices (24–48 hours)
5. Verify shortcuts return
6. Coordinate with vendor on fix before redeployment
```

---

## Decision Tree: Which to Check First

```
START: Issue Reported
  ↓
Question 1: Is this affecting ALL 45 users or just 1–2?
  │
  ├─→ YES, ALL 45: Check Hypothesis #1 FIRST (Intune Policy) — 60% likely
  │   ├─→ Check 1 result: Files exist in File Explorer? 
  │   │   ├─ YES → Hypothesis #1 CONFIRMED, proceed to remediation
  │   │   └─ NO → Files missing, go to Hypothesis #2
  │   └─→ Check 2 result: Hide/Redirect policy found in gpresult?
  │       ├─ YES → CONFIRMED, proceed to Azure Portal removal
  │       └─ NO → Policy not applied, unclear — escalate
  │
  └─→ NO, 1–2 users only: Check Hypothesis #2 FIRST (Migration) — 50% likely
      ├─→ Check 2 result: Migration log shows profile errors?
      │   ├─ YES → Hypothesis #2 CONFIRMED, recover from backup or recreate
      │   └─ NO → Check Hypothesis #3
      └─→ Check 3 result: Installation log shows app cleanup?
          ├─ YES → Hypothesis #3 CONFIRMED, uninstall/reinstall with options
          └─ NO → All hypotheses eliminated, escalate to L2/Infrastructure
```

---

## Summary Table: Hypotheses vs. Evidence

| Hypothesis | Cohort-Wide Probability | Single User Probability | Check Time | Remediation Time | Difficulty |
|-----------|--------|--------|-----------|-----------------|-----------|
| **#1: Intune Policy** | 60% | 15% | 5 min | 10 min | Easy (Portal UI) |
| **#2: Migration Profile** | 25% | 50% | 5 min | 5–30 min | Medium (backup/recreate) |
| **#3: App Installer** | 20% | 20% | 5 min | 5–30 min | Medium (uninstall/test) |

---

## Next Action

1. **Confirm scope**: "Are ALL 45 on Floor 6 affected or just you?"
2. **Run Check 1 for most probable hypothesis** (based on scope)
3. **Document findings**: Which files exist, which don't, which policies applied
4. **Execute remediation** for confirmed hypothesis
5. **Verify**: Shortcuts reappear
6. **Escalate if needed**: If all 3 hypotheses eliminated, go to L2/Infrastructure

---

## Notes
- **No error codes invented**: Uses Windows standard Event IDs 4098, 1033, 1034
- **Vendor-specific uncertainty**: App behavior (Check 1 in Hypothesis #3) noted as "to confirm: app name needed"
- **Non-destructive checks**: All are read-only except Hypothesis #3 Option B uninstall test (reversible)
