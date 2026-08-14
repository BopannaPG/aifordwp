# Prevention: The Single Control That Would Have Stopped This

## The Control: Mandatory Smoke Test Gate (Login Performance Checkpoint)

**What it is:**
A rule that blocks any broad app deployment to a business department until an automated test confirms the app doesn't break login performance. One test. One gate. One rule.

**Exactly when it fires:**
- Friday 4 PM: App deployed to pilot group (5-10 IT staff devices)
- Saturday 10 AM: Automated test runs on pilot devices, measures login time
- Saturday 10:30 AM: Results come back
- **GATE DECISION:** If login time > 120 seconds on ANY device → **BLOCK floor-wide deployment; escalate to vendor**
- If login time ≤ 90 seconds on ALL devices → **APPROVE floor-wide deployment**

**What it actually checks:**
Not a vague "monitor for issues." Specific: The test remotely connects to 5 pilot devices, forces a reboot, measures time from credential entry to Windows explorer opening (first sign that login completed), and records results in a spreadsheet.

**Why it catches this incident:**
- Friday 4 PM: Document Management System v2.0 installed on FLOOR6-LGL-IT-001 through FLOOR6-LGL-IT-005 (IT pilot devices)
- Saturday 10 AM: Automated test runs login cycle on each pilot device
- **Test times show:**
  - FLOOR6-LGL-IT-001: 247 seconds ❌
  - FLOOR6-LGL-IT-002: 234 seconds ❌
  - FLOOR6-LGL-IT-003: 19 seconds ✓ (one device unaffected; app installation variable)
  - FLOOR6-LGL-IT-004: 256 seconds ❌
  - FLOOR6-LGL-IT-005: 212 seconds ❌
- **Result: GATE BLOCKS DEPLOYMENT.** Broad Floor 6 assignment never happens. Incident never occurs.
- Vendor is contacted Saturday, informed: "Startup process is blocking login on 80% of devices. Fix or we reject the release."
- Monday morning: No outage. Floor 6 has old app or alternative. No impact to business.

---

## The Implementation

**Owner:** Release Engineer (runs test); Change Advisory Board (enforces gate)

**Tool needed:** PowerShell script (20 lines) + deployment checklist rule  
**Cost:** ~4 hours to build; ~15 minutes per deployment to run

**The Rule (in plain English):**
> "No production app can be assigned to a department of 20+ users until: (1) app is deployed to 5-10 pilot devices, (2) 24 hours pass, (3) automated login performance test runs and logs results, (4) login time ≤ 90 seconds on 100% of pilot devices. If test fails, escalate to vendor. If test passes, gate opens. Change approval team checks this gate before approving broad rollout."

**Where it goes:**
- Add to app deployment workflow checklist (Intune apps release process)
- Add to change management approval template (CAB checklist before Stage 1→2 transition)
- Add to release engineer's pre-deployment validation script

---

## Why This Single Control Works

It doesn't rely on:
- Subjective judgment ("does this look safe?")
- Manual testing ("IT team please test logging in")
- Retrospective monitoring ("let's watch after we release")

It delivers:
- **Objective signal:** Login time in seconds (not subjective)
- **Early timing:** Catches the problem Saturday morning, not Monday morning
- **Automatic enforcement:** Gate blocks release unless gate passes
- **One clear trigger:** 24 hours after pilot deployment (predictable)

---

## Estimated Impact

**This incident:**
- Detected: Monday 9:15 AM (72+ hours after deployment)
- Impact: ~2 hours until resolved (45 users × 2 hours = 90 lost staff-hours)
- Cost: Productivity loss, risk of missed compliance deadlines, Service Desk overhead

**With this control:**
- Detected: Saturday 10 AM (40 hours before deployment would have reached production)
- Impact: Zero (release blocked before reaching Floor 6)
- Cost: Saved ~90 staff-hours + zero business risk

**Implementation cost:** 4 hours build time + 15 min per app release  
**ROI:** 1 prevented incident = 90+ hours saved + eliminated floor-wide outage risk

---

**Next step:** Assign Release Engineer to build the PowerShell test script. Target: in place by September 1, 2026. First use: next floor-wide app deployment (estimated: September 15).

