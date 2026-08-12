# Phased Intune Deployment Plan - FinBridge Connect v3.1

Date baseline: 2026-08-12  
Overall deadline: 3 weeks (complete by 2026-09-02)  
Total scope: 10,000 Win11 endpoints

## 1. RING STRUCTURE

| Ring | Target Size | Duration | Who to Include | Purpose | Intune Assignment Group Type |
|---|---:|---|---|---|---|
| Ring 1 (Pilot) | 300 devices (3%) | Day 1 to Day 4 (4 days) | IT support, endpoint engineering, app owners, 50 finance champions, mixed hardware including at least 30 devices with 4GB RAM | Validate install, detection rule behavior, launch stability, and early support impact before wider exposure | Assigned (static) Azure AD Security Group: `SG-APP-FinBridge-v3_1-Ring1-Pilot` |
| Ring 2 (Early) | 2,200 devices (22%) | Day 5 to Day 10 (6 days) | Remaining 450 finance users (to complete 500 total by end of week 1), operations teams, and a representative cross-section of business units and geographies | Confirm scale behavior, verify finance-critical workflows, and test service desk volume at moderate scale | Dynamic Azure AD Device Group with inclusion rule for approved departments and exclusion of Ring 1: `DG-APP-FinBridge-v3_1-Ring2-Early` |
| Ring 3 (Broad) | 7,500 devices (75%) | Day 11 to Day 21 (11 days) | All remaining in-scope Win11 endpoints not in earlier rings; phased in 3 waves of 2,500 every 3 to 4 days | Complete enterprise rollout while preserving containment points between waves | Dynamic Azure AD Device Group for all remaining eligible devices, excluding rollback/hold groups: `DG-APP-FinBridge-v3_1-Ring3-Broad` |

Hardware risk control across all rings:
- Maintain a dedicated dynamic device group for low-memory endpoints: `DG-APP-FinBridge-v3_1-4GB-AtRisk`.
- In Ring 3, deploy to this group 48 hours after each corresponding standard-hardware wave.

## 2. ADVANCE CRITERIA

Evaluation source: Intune Win32 app install status, device install error codes, and service desk ticket dashboard tagged `FinBridge v3.1`.

### Ring 1 -> Ring 2 (Go/No-Go Gate)
- Install success rate: at least 97.0% across Ring 1 devices.
- Error rate: at most 3.0% total failed installs.
- User-reported issue rate: at most 1.0% of Ring 1 users opening P2+ tickets (max 3 tickets per 300 users).
- Monitoring period: minimum 48 continuous hours after 95% of Ring 1 devices have attempted install.
- Time bound: gate decision made by Day 4 17:00 local.

### Ring 2 -> Ring 3 (Go/No-Go Gate)
- Install success rate: at least 98.0% across cumulative Ring 1 and Ring 2 devices.
- Error rate: at most 2.0% cumulative failed installs.
- User-reported issue rate: at most 0.7% of Ring 2 users with P2+ tickets (max 15 tickets per 2,200 users).
- Monitoring period: minimum 72 continuous hours after 95% of Ring 2 devices have attempted install.
- Time bound: gate decision made by Day 10 17:00 local.

### Hold Condition (Pause Without Full Rollback)
Trigger a deployment hold if any single high-severity install error code exceeds 1.5% of targeted devices in the active ring within a 24-hour window, while overall success remains above gate threshold.

Specific example:
- If Intune reports error `0x87D1041C` on 40 out of 2,200 Ring 2 devices (1.82%) in 24 hours, pause new assignments to Ring 3, isolate affected devices into `SG-APP-FinBridge-v3_1-Hold`, and continue remediation without reverting already healthy devices.

## 3. ROLLBACK TRIGGERS

### Trigger A: Install Failure Rate Automatic Halt
- Condition: install failure rate reaches 8.0% or higher in any active ring over a rolling 12-hour period.
- Decision authority: Endpoint Platform Lead + Major Incident Manager.
- Decision window: 30 minutes from threshold breach alert.
- Exact Intune action:
  - Remove `Required` assignment for FinBridge Connect v3.1 from the affected ring group.
  - Assign FinBridge Connect v3.0 as `Required` to the same ring group.
  - If uninstall command is validated, set FinBridge Connect v3.1 to `Uninstall` for that ring group.

### Trigger B: Application Crash Rate Rollback Consideration
- Condition: crash rate above 2.0 crashes per 100 active devices per day for 2 consecutive days in the same ring.
- Decision authority: Endpoint Platform Lead + App Product Owner + Service Desk Manager.
- Decision window: 4 hours after second-day confirmation.
- Exact Intune action:
  - Freeze forward assignments (do not target next ring/wave).
  - Reassign affected ring from v3.1 `Required` to v3.0 `Required`.
  - Keep unaffected prior ring stable if below threshold.

### Trigger C: Business-Critical Immediate Rollback
- Condition: confirmed inability for Finance users to submit production payment batches in FinBridge Connect v3.1 (core transaction workflow blocked).
- Decision authority: Finance Service Owner can invoke immediate rollback with Endpoint Platform Lead approval.
- Decision window: immediate, within 15 minutes of validated incident.
- Exact Intune action:
  - Remove v3.1 `Required` from all Finance-targeted groups (`Ring 0/1/2 Finance segments`).
  - Assign v3.0 `Required` to the same Finance groups immediately.
  - Leave non-Finance rings on hold pending incident bridge decision.

### Trigger D: 4GB RAM At-Risk Device Failures (Ring Isolation)
- Condition: failure rate in `DG-APP-FinBridge-v3_1-4GB-AtRisk` reaches 12.0% or higher within 24 hours in any wave.
- Decision authority: Endpoint Engineering Duty Lead.
- Decision window: 1 hour.
- Exact Intune action:
  - Exclude `DG-APP-FinBridge-v3_1-4GB-AtRisk` from all active v3.1 assignments.
  - Assign v3.0 `Required` to `DG-APP-FinBridge-v3_1-4GB-AtRisk`.
  - Continue v3.1 rollout for non-4GB groups if their thresholds remain healthy.

## 4. FINANCE DEADLINE RESOLUTION

### Option A - Compress Pilot to Fit Finance into Ring 2 by End of Week 1
- Minimum safe pilot duration: 48 hours with at least 300 pilot devices and one business-day cycle.
- Risk introduced: reduced time to detect low-frequency defects (for example, next-day startup issues, policy refresh edge cases, delayed post-install crashes).
- Compensating control: enforce 4-hour telemetry checkpoints, pre-approved halt criteria, and no Ring 2 expansion until two consecutive checkpoints meet thresholds.

### Option B - Separate Priority Ring 0 for Finance Before Main Pilot
- Structure:
  - Ring 0a: 100 finance power users (Day 1 to Day 2).
  - Ring 0b: remaining 400 finance users (Day 3 to Day 6), only if Ring 0a gates pass.
- Ring 0 advance conditions:
  - Install success at least 98.0%.
  - Error rate at most 2.0%.
  - P2+ finance ticket rate at most 1.0%.
  - Monitoring period 24 hours after 95% install attempt in Ring 0a.
- Ring 0 rollback plan:
  - If any business-critical Finance workflow fails, remove v3.1 `Required` from Ring 0 groups and reassign v3.0 `Required` within 15 minutes.
  - Pause main Ring 1 pilot start until incident closure and approved re-test.

### Recommendation
Recommend Option B (Finance Ring 0) as the primary strategy.

Justification:
- It guarantees the Finance end-of-week-1 commitment with explicit containment.
- It avoids weakening the enterprise pilot evidence needed for the remaining 9,500 endpoints.
- It reduces blast radius by isolating finance-critical risk from broad rollout timing pressure.
- It preserves the 3-week enterprise deadline while providing a cleaner decision path for rollback vs continue.
