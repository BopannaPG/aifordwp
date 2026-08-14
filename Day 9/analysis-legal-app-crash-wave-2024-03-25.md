# Detailed Analysis - Legal App Crash Wave (Floor 6)

## Incident Summary
- Reported issue: wave of application crashes affecting Legal (Floor 6).
- Device group in scope: Legal-Win11 (45 devices).
- Observation window in provided telemetry: 2024-03-25 08:00 to 11:00.

## Evidence Baseline (Scope Facts)
### Nexthink DEX export
- 08:00: DEX 91, app crash rate 0.1%, Disk I/O Normal.
- 09:00: DEX 90, app crash rate 0.2%, Disk I/O Normal.
- 10:00: DEX 58, app crash rate 6.2%, Disk I/O High.
- 11:00: DEX 55, app crash rate 6.8%, Disk I/O High.
- Top crashing process from 10:00 to 11:00: DocManager.exe (74% of all crashes in that window).

### SCCM deployment log
- 09:38:20: Deployment started for Legal Document Manager v2.1 to Legal-Win11 (45 devices).
- 09:44:07: Install completed on 45/45 devices.
- Install result: Success, 0 failures.
- Previous version: Document Manager v2.0 (stable, deployed 6 weeks earlier).
- Vendor note for v2.1: new auto-save feature.
- Vendor known limitation: devices with under 8GB RAM may see high disk I/O and intermittent crashes during first hours after install while initial index builds.
- Fleet RAM profile: 60% with 8GB, 40% with 4GB.

## Ranked Most Likely Causes

### 1) Post-upgrade DocManager v2.1 auto-save indexing stress on sub-8GB devices (Most probable)
Why it fits the evidence:
- Timing alignment: deployment completed at 09:44; crash and I/O spike appears by 10:00.
- Process concentration: DocManager.exe accounts for 74% of crashes in the peak window.
- Symptom match: vendor explicitly documents high disk I/O plus intermittent crashes in first hours after install on under-8GB devices.
- Exposure exists in this fleet: 40% of devices are 4GB RAM.

Fastest check to confirm or eliminate:
- Segment Legal-Win11 into <8GB vs >=8GB and compare 10:00-11:00 DocManager.exe crash incidence and disk I/O elevation by segment.
- Confirm affected devices have v2.1 installed and are in initial index-build window after install.

Specific remediation action if confirmed:
- Immediately pause or roll back v2.1 on 4GB devices to v2.0.
- Disable or defer auto-save indexing policy/job for low-memory devices before controlled redeployment.
- Reintroduce v2.1 in phased rings starting with >=8GB devices, then validated pilot on 4GB with indexing throttled.

### 2) v2.1 deployment-side configuration triggered heavy indexing workload across all devices
Why it fits the evidence:
- Broad and near-simultaneous onset follows a 45/45 successful deployment.
- Disk I/O changes from Normal to High at same time crash rate surges.
- Could occur if v2.1 auto-save/indexing defaults were enabled at aggressive settings at install.

Fastest check to confirm or eliminate:
- Compare v2.0 and v2.1 deployment parameters, post-install scripts, and policy/config values related to auto-save/indexing.
- Verify whether indexing concurrency/throttle settings were changed in v2.1 package or post-install baseline.

Specific remediation action if confirmed:
- Correct package or policy configuration (throttle indexer, lower concurrency, delayed first-run indexing).
- Redeploy corrected configuration package and trigger controlled re-index.

### 3) Co-incident storage pressure event in Legal-Win11 amplified DocManager crash susceptibility after upgrade
Why it fits the evidence:
- Disk I/O High appears exactly during crash window.
- App crash surge could be amplified by storage contention when a newly installed app initiates heavy first-run tasks.
- Still plausible as a contributing condition even if v2.1 change is primary trigger.

Fastest check to confirm or eliminate:
- Review endpoint storage telemetry in same 09:30-11:30 window for queue length/latency spikes and check whether non-DocManager processes also show fault increases.
- Compare to adjacent device groups not receiving Legal package at that hour.

Specific remediation action if confirmed:
- Apply immediate I/O relief actions (pause nonessential high-I/O scheduled tasks in Legal ring).
- Re-time indexing and large background jobs to non-business hours.

## Error Code Handling Note
- No explicit crash error codes were provided in the shared dataset.
- Therefore no error-code meaning is interpreted in this analysis.

## Finalized Working Hypothesis (Selected)
Most likely single hypothesis:
- Legal Document Manager v2.1 first-hours auto-save indexing behavior on under-8GB devices produced high disk I/O and intermittent DocManager.exe crashes after rollout.

## Exact Remediation Steps
1. Open change bridge and announce incident containment for Legal-Win11.
2. Create an SCCM dynamic collection for Legal devices with RAM < 8GB (4GB cohort).
3. Stop further v2.1 targeting to Legal collections.
4. Deploy rollback package to affected cohort: v2.1 -> v2.0.
5. On remaining v2.1 devices, apply vendor-approved setting to disable/defer first-run auto-save indexing (or throttle index concurrency) until off-hours.
6. Reboot or restart DocManager service/process where required by vendor guidance.
7. Monitor for 2 business hours, then complete phased redeploy plan only after stability criteria are met.

## Correct Order of Operations
1. Contain blast radius: freeze deployment expansion.
2. Protect highest-risk cohort: isolate <8GB devices.
3. Stabilize service: roll back low-memory cohort first.
4. Mitigate remaining v2.1 footprint: throttle/disable indexing temporarily.
5. Validate stability with telemetry gates.
6. Plan controlled redeployment with corrected settings and ring rollout.

## Verification Checks After Remediation
Primary success criteria (Legal-Win11):
- App crash rate trend returns near pre-incident baseline (from 6.2-6.8% toward <=0.2%).
- Disk I/O state returns from High to Normal in business-hour checks.
- DocManager.exe share of total crashes drops materially from 74% and remains low.
- No new concentrated post-install crash wave within first 2-4 hours on remediated devices.

Operational checks:
- SCCM confirms rollback completion success for targeted cohort.
- Spot-check 5-10 representative 4GB devices for DocManager usability and absence of repeated crash dialogs.

## Preventive Action
- Implement hardware-aware deployment rings and guardrails:
  - Ring A: >=8GB devices first.
  - Ring B: <8GB devices only after pilot pass and with indexing throttle preset.
- Add pre-deployment gate requiring vendor known-limitations review and explicit mitigation settings in package.
- Add automated telemetry alert: if crash rate or disk I/O crosses threshold within 2 hours of deployment, auto-pause rollout and open incident.

## Analyst Note
This document intentionally separates likelihood-based hypotheses from proven root cause. Final root-cause confirmation requires the fast checks listed above.