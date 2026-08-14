# Root Cause Analysis (RCA)

## Incident Title
Legal Floor 6 app crash wave after Document Manager update

## Date/Time Window Reviewed
2024-03-25 08:00 to 11:00

## Analyst
DWP Analyst

## Scope
Investigate crash wave affecting Legal-Win11 (45 devices), determine most likely root cause from provided evidence, define remediation and prevention.

## Executive Summary
A sharp increase in crashes and disk I/O began shortly after Legal Document Manager v2.1 was deployed successfully to all 45 Legal devices. The crash concentration was dominated by DocManager.exe during the same window. The most likely root cause is first-hours auto-save indexing behavior introduced in v2.1, with higher exposure on under-8GB devices in this fleet.

## Supporting Evidence
1. Baseline stability before deployment window:
- 08:00: DEX 91, crashes 0.1%, Disk I/O Normal.
- 09:00: DEX 90, crashes 0.2%, Disk I/O Normal.

2. Post-deployment degradation:
- 10:00: DEX 58, crashes 6.2%, Disk I/O High.
- 11:00: DEX 55, crashes 6.8%, Disk I/O High.

3. Crash concentration:
- 10:00-11:00 top crashing process is DocManager.exe at 74% of all crashes.

4. Deployment evidence:
- 09:38:20 deployment started for Legal Document Manager v2.1 to Legal-Win11.
- 09:44:07 install completed 45/45, success, 0 failures.
- Previous v2.0 described as stable for 6 weeks.

5. Vendor release note and hardware exposure:
- v2.1 includes auto-save feature.
- Known limitation: under 8GB RAM devices can see high disk I/O and intermittent crashes in first hours while initial index builds.
- Legal fleet has 40% devices with 4GB RAM (<8GB).

## Timeline of Events
1. 08:00 - Group healthy; low crash rate and normal I/O.
2. 09:00 - Group still stable.
3. 09:38:20 - v2.1 deployment initiated to all 45 devices.
4. 09:44:07 - v2.1 install completed successfully on all devices.
5. 10:00 - Large negative shift: DEX drops, crash rate spikes, I/O becomes High.
6. 11:00 - Elevated crash rate and High I/O persist.
7. 10:00-11:00 - DocManager.exe accounts for majority of crashes.

## Considered Hypotheses
1. v2.1 auto-save indexing effect on low-memory devices (selected root cause).
2. v2.1 package/configuration enabled overly aggressive indexing settings.
3. Independent storage contention event amplified crashes during same window.

## Selected Root Cause
Most likely root cause:
- Document Manager v2.1 first-hours indexing workload (auto-save feature path) generated high disk I/O and intermittent DocManager.exe crashes, with elevated risk in devices below 8GB RAM.

Root cause confidence:
- High for probable causal link based on timing, process concentration, and vendor limitation alignment.
- Remaining uncertainty is limited to exact per-device distribution without final cohort split report.

## 5 Whys Analysis
1. Why did Legal users see a wave of app crashes?
- Because application crash rate rose sharply in the Legal-Win11 group between 10:00 and 11:00.

2. Why did crash rate rise sharply in that period?
- Because DocManager.exe produced the majority of crashes (74%) during the degraded window.

3. Why did DocManager.exe begin crashing at that time?
- Because the new v2.1 release had just been deployed to all Legal devices, and the degradation started immediately after deployment completion.

4. Why would v2.1 trigger crashes and high disk I/O shortly after installation?
- Vendor documentation states first-hours auto-save indexing can cause high I/O and intermittent crashes on devices with under 8GB RAM.

5. Why was Legal especially exposed to this limitation?
- A significant portion of the fleet (40%) is 4GB RAM, and deployment targeted all 45 devices simultaneously without hardware-based ring control.

## Confirmed Remediation Plan
### Exact Remediation Steps
1. Freeze any additional v2.1 deployment to Legal and related collections.
2. Build SCCM collection for Legal devices with RAM < 8GB.
3. Roll back affected low-memory cohort from v2.1 to v2.0.
4. Apply vendor-supported policy to disable, delay, or throttle first-run auto-save indexing on remaining v2.1 devices.
5. Restart DocManager process/service or reboot endpoints as required by package behavior.
6. Keep incident monitoring active through at least one full business cycle.

### Correct Order of Operations
1. Containment (stop further rollout).
2. Risk segmentation (identify <8GB devices).
3. Stabilization (rollback low-memory cohort).
4. Mitigation on retained v2.1 endpoints (indexing controls).
5. Observation and telemetry validation.
6. Controlled redeploy using phased rings only after success criteria are met.

### Verification Check After Remediation
Telemetry checks (Legal-Win11):
- Crash rate falls from 6.2-6.8% toward baseline range near <=0.2%.
- Disk I/O status returns from High to Normal during active use periods.
- DocManager.exe no longer dominates crash share.

Operational checks:
- SCCM rollback and policy deployment compliance >=95% for targeted cohort.
- Pilot sample of remediated 4GB devices shows stable DocManager usage for at least 2-4 hours post-login.

Exit criteria:
- No recurring crash wave in first-hours post-change window.

## Preventive Actions
1. Enforce hardware-aware deployment rings for Legal business apps:
- Ring 1: >=8GB devices.
- Ring 2: <8GB devices only after pilot and with indexing throttle preset.

2. Add change gate:
- Mandatory review of vendor known limitations and explicit mitigation settings before production deployment.

3. Add automated deployment health guardrail:
- If app crash rate or disk I/O breaches threshold within 2 hours of rollout, auto-pause deployment and alert DWP operations.

4. Improve pre-production validation:
- Include 4GB test endpoints in UAT whenever release notes mention memory or indexing constraints.

## Error Code Interpretation Statement
No explicit error codes were provided in the supplied evidence set for this incident. This RCA does not assign meanings to absent codes.

## Residual Risks
- If rollback coverage is incomplete, localized recurrence may continue.
- If indexing policy is misapplied, retained v2.1 endpoints may still show short-lived instability.

## Closure Recommendation
Proceed with the remediation sequence above, hold broad v2.1 redeployment until verification criteria are met, and retain hardware-aware rollout as a standing control for future releases.