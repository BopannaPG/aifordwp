# Triage Summary: Floor 6 Legal — Desktop Shortcuts Vanished

**Date Reported**: 14/08/2026 (Monday morning)  
**Reported by**: Floor 6 Legal staff (user name/ID to confirm)  
**Analyst**: [Analyst Name]  
**Ticket ID**: To assign  
**Status**: Initial Triage

---

## Summary (One Line)
Desktop shortcuts disappeared on Floor 6 Legal devices after Win11 migration, Intune enrollment, and new document management app deployment on Friday.

---

## Impact

| Dimension | Details |
|-----------|---------|
| **Who** | Floor 6 Legal department (45 people) — to confirm if all affected or subset |
| **How Many** | To confirm: Is this 1 user, multiple users, or all 45? |
| **Business Urgency** | **MEDIUM-HIGH** — Affects end-user productivity (paralegals, legal assistants need quick access to case files). If all 45 affected, escalate to HIGH. If only 1–2 users, escalate to MEDIUM. |
| **Business Context** | Legal department = time-sensitive case work; missing shortcuts delays document access for confidential matters |
| **Estimated Impact** | 15–30 min per user to recreate shortcuts (if they remember what shortcuts existed) |

---

## Known Facts

1. ✅ **Cohort**: Floor 6 Legal team, 45 people total
2. ✅ **Recent changes (last 72 hours)**:
   - Windows 11 migration (date to confirm)
   - Intune enrollment (date to confirm)
   - New document management app deployed Friday afternoon (name/version to confirm)
3. ✅ **Symptom**: Desktop shortcuts disappeared
4. ✅ **Timing**: Reported Monday morning (14/08/2026). When exactly noticed? (Sunday evening, Monday early, or during morning standup?)
5. ⚠️ **Scope**: To confirm — is this affecting only the reporting user or entire Floor 6?

---

## Missing Information to Gather

### Urgent (Ask Now)

| Question | Why | To Confirm |
|----------|-----|-----------|
| **How many people affected?** | If only 1 user → local profile issue; if all 45 → Intune policy or migration-wide problem | 1 user \| multiple \| all 45 |
| **All shortcuts gone or only specific ones?** | App-related shortcut vs. custom shortcuts vs. all shortcuts narrows root cause | All \| specific (which?) \| custom only |
| **Can they see shortcuts in File Explorer?** | If shortcuts exist in `C:\Users\[username]\Desktop` but not displayed → Intune policy hiding desktop or display issue; if files don't exist → deleted/moved | Yes \| No \| Don't know |
| **Did anything uninstall over the weekend?** | Document management app or other software might have removed shortcuts during installation | Yes \| No \| Don't know |
| **Any error messages when they restarted?** | Profile error, policy application error, or app conflict during boot | Error text (to capture) |

### Secondary (Gather If First Set Doesn't Clarify)

1. Are shortcuts in other locations? (Start menu, Quick Launch, pinned to taskbar?)
2. Did they have shortcuts before Win11 migration? (To distinguish migration issue from deployment issue)
3. When exactly did they notice? (Sunday evening? Monday morning? During first logon?)
4. What document management app was installed? (Name, version, vendor — could it have a "clean desktop" feature?)
5. Any recent Intune policy changes to Floor 6 group?

---

## Likely Category

**Primary suspect (Priority Order)**:

1. **🔴 Intune Policy** (40% likelihood if all 45 affected)
   - Intune can enforce desktop folder redirection or hide desktop icons
   - If ALL 45 users affected at same time → almost certainly policy-driven
   - Check: Has Intune policy for "Hide desktop" or "Redirect known folders" been applied to Floor 6 group?

2. **🟠 Windows 11 Migration Profile Issue** (30% likelihood)
   - Win11 migration may have triggered user profile refresh
   - New profile → desktop folder empty → shortcuts not migrated
   - If subset affected or timing doesn't match migration → less likely

3. **🟡 Document Management App Installation** (20% likelihood)
   - App installer may have deleted/moved shortcuts as part of cleanup
   - App may have a "clear desktop" feature
   - Check: App vendor known to do this? Any app documentation?

4. **🟢 File Permissions / Desktop Folder Locked** (5% likelihood)
   - Less common in Intune environment
   - Usually accompanied by error messages or read-only desktop folder

5. **⚪ User Accidental Deletion / Move** (5% likelihood)
   - Shortcuts moved to Downloads or Documents
   - Less likely if cohort-wide

---

## First Diagnostic Step

**Immediate (Before any fixes)**:

1. **Phone the user back**: Ask the three urgent questions above (cohort scope, visibility in File Explorer, uninstall events)
   - If answer is "ALL 45 affected" → escalate to **L2 / Infrastructure** immediately; likely Intune policy
   - If answer is "only me" → continue with local diagnostics below

2. **Remote access (if available)**:
   - Open File Explorer on user's device → navigate to `C:\Users\[username]\Desktop`
   - **If files exist in File Explorer**: Desktop folder redirection or Intune policy hiding display → check Intune policies
   - **If files do NOT exist**: Profile reset during migration or app uninstalled them → check Event Viewer or recovery options

3. **Quick event log check**:
   - Open Event Viewer → Windows Logs → Application
   - Search for events from Friday afternoon (when app deployed) or Sunday/Monday morning
   - Look for: "Uninstall," "Delete," "Profile," "Folder Redirect"

4. **If all 45 affected**:
   - Skip local diagnostics
   - Escalate to: Infrastructure Team / Intune Administrator
   - Attach: Intune device compliance report for Floor 6 devices + recent policy change log

---

## Escalation Criteria

| Condition | Action |
|-----------|--------|
| **All 45 users affected** | **ESCALATE to L2/Infrastructure immediately** — Likely Intune policy or migration-wide issue |
| **Subset (2–10 users)** | Continue local diagnostics; assign to L2 if not resolved in 30 min |
| **Single user** | **RESOLVE via L1** — Ask user to check File Explorer, recreate shortcuts if needed; close if found or escalate if files missing |
| **Multiple error messages** | **ESCALATE** — Possible profile corruption or permissions issue |

---

## Next Steps (After Triage)

- [ ] Confirm scope (1 user, subset, or all 45)
- [ ] Ask urgent questions above
- [ ] Run first diagnostic (File Explorer check or Event Viewer)
- [ ] Log findings in ticket
- [ ] Route to appropriate team (L1 self-help, L2 diagnostics, or Infrastructure escalation)
- [ ] Set callback time (if more info needed)

---

## Notes for Handoff

If escalating to L2 or Infrastructure:
- Reference: Recent Win11 migration, Intune enrollment, document management app (Friday)
- Context: Legal department (time-sensitive work)
- Request: Check Intune policies applied to Floor 6; review migration sync logs; review app deployment logs
