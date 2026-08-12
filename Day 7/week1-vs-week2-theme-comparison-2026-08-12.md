# Week 1 vs Week 2 Theme Comparison
Date: 2026-08-12

## Week 1 Themes and Week 2 Status

### Theme 1: Login / Account Lockouts
Week 1 signal: Users reporting slow login on new Windows 11 machines and account lockouts disrupting access (T-1001 BitLocker prompts contributing to lockout pattern; outlook/performance slowness on new Windows 11 device).
Week 2 status: **Resolved**
Evidence from Week 2 comments:
- ID 1: "Login is back to normal now, thanks for the fix!"
- ID 7: "No more lockouts this week, good improvement."
- ID 12: "Login speed is back to what it used to be, thank you."
- ID 15: "Whatever was fixed with login has definitely helped, much better."
- ID 19: "Account lockouts have completely stopped, appreciate the fix."
- ID 22: "Login fast and reliable this week."
- ID 29: "Login working well, no complaints from me this week."
- ID 34: "Login and lockout issues from week 1 are fully resolved for me."

---

### Theme 2: Floor 3 Printer (Mapping / Unavailability)
Week 1 signal: Main printer on 3rd floor reported unavailable, whole team affected, urgent due to client meeting (Day 1 triage-summary-printer-3rd-floor).
Week 2 status: **Worsening**
Evidence from Week 2 comments:
- ID 2: "Still can't get the printer on floor 3 to map, this is week 2 now."
- ID 5: "Printer issue on floor 3 still not resolved, very frustrating."
- ID 9: "Floor 3 printer -- can someone just replace the thing at this point."
- ID 14: "Still walking to floor 2 to print, floor 3 printer a lost cause at this point."
- ID 18: "Printer floor 3 is now a running joke on our team, still broken."
- ID 23: "Floor 3 printer still not mapped automatically, third week now actually."
- ID 28: "Printer on floor 3 -- genuinely considering escalating this to my manager."
- ID 31: "Everything mostly smooth except that printer on floor 3."
- ID 35: "Printer floor 3 still broken, at this point just send us a new printer."
- ID 40: "Floor 3 printer unresolved for two weeks running now, needs escalation."
Note: User frustration and escalation language is intensifying week on week. Requires urgent action.

---

### Theme 3: VDI / Remote Access Connectivity
Week 1 signal: User cannot connect to VDI from home on Wi-Fi; separate ticket T-1008 for VPN not providing internal access after Windows 11 upgrade (Day 1 triage-summary-vdi-connectivity, T-1008).
Week 2 status: **Resolved**
Evidence from Week 2 comments:
- ID 10: "VPN has been rock solid this week, no complaints."
- ID 27: "VPN stable, no drops this week at all."
- ID 36: "VPN and login both solid this week, thank you."
No negative VPN or VDI comments in Week 2.

---

### Theme 4: OneDrive Sync / Missing Files
Week 1 signal: T-1007 reports OneDrive stuck on "processing changes" post-migration with files missing locally.
Week 2 status: **Resolved**
Evidence from Week 2 comments:
- ID 3: "OneDrive files all showing up fine now."
- ID 11: "Files are all there now, no more OneDrive issues for me."
- ID 21: "OneDrive sync working perfectly now."
- ID 26: "No file issues anymore, all resolved."
- ID 32: "Files all present, sync working as expected."
- ID 39: "OneDrive fully working, no more missing file reports from me."

---

### Theme 5: Windows 11 General Slowness (Post-Upgrade)
Week 1 signal: T-1006 reports overall slowness after Windows 11 upgrade completed two days ago.
Week 2 status: **Resolved / Unchanged**
Evidence from Week 2 comments:
- ID 6: "Overall much smoother now, appreciate the quick turnaround."
- ID 17: "No issues to report this week, all smooth."
- ID 25: "Great improvement overall since last week."
- ID 38: "No further issues on my end, all good."
No specific performance complaints referencing slow Windows 11 in Week 2. General positive sentiment suggests resolution.

---

## New Theme in Week 2 (Not Present in Week 1)

### NEW Theme: Excel Crashing on Large Files
First appeared: Week 2 only. No Excel crash reports in Week 1 data.
Week 2 status: **Emerging / High Priority**
Evidence from Week 2 comments:
- ID 4: "New issue: Excel crashes when opening large spreadsheets."
- ID 8: "Excel keeps crashing on our biggest budget spreadsheet, happened 3 times today."
- ID 13: "Excel crash is really disruptive, losing unsaved work each time."
- ID 16: "New problem -- Excel freezes for 30 seconds then crashes on large files."
- ID 20: "Excel crashing has become a real productivity problem for finance team."
- ID 24: "Excel large-file crash happened again, please look into this urgently."
- ID 30: "Excel keeps crashing, this is now my biggest issue with the new setup."
- ID 33: "New Excel crash issue -- happens specifically with files over 10MB."
- ID 37: "Excel crash is new and quite disruptive, please prioritise."
Pattern: Multiple users, finance team specifically affected, consistent trigger of large files (>10MB), repeated crashes with unsaved-work loss. High priority for Week 3.

---

## Summary Table

| Week 1 Theme                        | Week 2 Status | Action Required              |
|-------------------------------------|---------------|------------------------------|
| Login / Account Lockouts            | Resolved      | None - monitor only          |
| Floor 3 Printer Mapping/Unavailable | Worsening     | Escalate urgently            |
| VDI / VPN Remote Access             | Resolved      | None - monitor only          |
| OneDrive Sync / Missing Files       | Resolved      | None - monitor only          |
| Windows 11 General Slowness         | Resolved      | None - monitor only          |
| **Excel Large-File Crashes (NEW)**  | **Emerging**  | **Raise new ticket - urgent**|
