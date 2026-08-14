# Floor 6 Incident: Technical & End-User Communications

---

## TECHNICAL ACTION (Intune Admin Execution)

### Remove Floor 6 from "Hide Desktop Items" Policy Assignment

**Step 1: Azure Portal**
```
Navigate to: https://portal.azure.com
→ Azure Active Directory
→ Device Management
→ Device Configuration
→ Profiles
→ [Select policy: "Hide All Items On Desktop" OR similar]
→ Assignments tab

ACTION: Find "Floor 6 Legal" group → Click Remove → Save
CONFIRM: "Assignment removed successfully" notification appears

TIME: 2 minutes
```

**Step 2: Force Policy Sync on Devices (choice of two methods)**

**Method A (Recommended): Group Policy Update on Sample Devices**
```PowerShell
# Run on 3–5 representative Floor 6 devices (via RMM or remote console):
gpupdate /force

# Wait 90 seconds for completion
# User will see: "User Policy processed successfully"
#               "Computer Policy processed successfully"

# Then restart device:
shutdown /r /t 60

# Alternatives for remote execution:
# If using ConfigMgr: Invoke-CMDevicePolicyRetrieval -CollectionName "Floor6Legal"
# If using Intune: Sync via Intune portal → Devices → Device Actions
```

**Method B (Fastest for 45 devices): Intune Portal Sync**
```
Azure Portal → Intune → Devices → All Devices
→ Filter: Floor 6 tag
→ Select all devices (or use bulk action)
→ Device Actions → Sync
→ All 45 devices will sync within 15–30 minutes
```

**Step 3: Verification (Choose One)**
```PowerShell
# Check one device:
gpresult /h C:\temp\gpresult.html
# Open in browser → Search (Ctrl+F): "Hide" OR "Redirect"
# Expected: NO policies found with these names

# OR check Event Viewer on device:
# Event ID 4098 should show "User Policy processed successfully" 
# within last 10 minutes
```

**Step 4: Confirm Rollout Complete**
```
Azure Portal → Intune → Devices → All Devices
→ Check "Last Check-In" column
→ Devices with check-in within last 30 minutes = synced
→ When 80%+ of Floor 6 devices show recent check-in: Remediation complete

Timeline: 30 minutes from policy removal
```

---

## END-USER COMMUNICATION (Send to Floor 6 Team Lead & Staff)

---

**Subject: Desktop Shortcuts Issue — RESOLVED** ✅

Dear Floor 6 Legal Team,

**What happened:** A computer update Friday accidentally hid your desktop shortcuts, but the files are still there and safe.

**You're all set:** Our IT team removed the setting that was hiding your shortcuts. Your desktop should look normal again.

**What to do:**
- Restart your PC (if you haven't already this morning)
- Wait 10–15 minutes for the update to reach your device
- Desktop shortcuts should appear automatically

**Still don't see shortcuts?**
- Restart one more time
- Call IT Helpdesk at **[ext. XXX]** if shortcuts still missing after second restart
- (Usually takes 1–2 restarts; we apologize for the inconvenience)

**Questions?** Contact IT Service Desk  
**Ext.** [XXX] | **Email:** ithelp@finbridge.com | **Teams:** #IT-Support

---

**Word count**: 98 words | **Jargon**: None | **Tone**: Friendly, reassuring, action-oriented

