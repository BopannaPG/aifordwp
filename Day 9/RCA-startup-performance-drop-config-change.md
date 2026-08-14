# Root Cause Analysis (RCA)

## Incident Title
Startup Performance Drop Following Configuration Change

## Date/Time Window Reviewed
- Relative timeline used from available scope facts.
- Exact timestamps were not provided in the source summary.

## Analyst
DWP Analyst

## Scope
Assess startup-performance degradation in an affected group, correlate with configuration-change timing, compare with unaffected no-change group, determine most likely root cause, and define remediation and preventive controls.

## Executive Summary
The startup-performance drop is most likely caused by a newly introduced startup-related configuration that increased synchronous startup workload and/or blocking waits. Confidence is high because symptom onset followed the configuration-change window, while a clean comparison group with no configuration change remained stable.

## Supporting Evidence
1. Temporal alignment evidence:
- Startup degradation appears after the configuration change was applied.

2. Counterfactual comparison evidence:
- Unaffected comparison group had no configuration change and did not show equivalent startup degradation.

3. Differential change evidence:
- The main known variable between groups is the configuration state, which strongly prioritizes config-driven causes over broad environmental causes.

4. Domain consistency evidence:
- Startup latency is commonly sensitive to startup scripts, synchronous policy processing, dependency checks, and task ordering introduced by configuration.

## Timeline Reconstruction
1. Baseline period:
- Affected and unaffected cohorts operate without reported startup degradation.

2. Change event:
- New configuration is deployed to affected group.

3. Post-change observation:
- Startup-performance drop appears in affected group.

4. Comparison observation:
- Unaffected group (no config change) remains stable.

5. Correlation conclusion stage:
- Pattern indicates strong config-linked association requiring targeted rollback/trace verification.

## Root Cause Statement (Most Likely)
Primary root cause:
- A startup-related configuration change introduced an excessive or blocking startup workload (for example synchronous startup tasks, dependency waits, or over-broad assignment), resulting in increased startup duration for the affected group.

## Considered Hypotheses
1. Misconfigured or overly heavy startup policy introduced by new config (selected primary root cause).
2. New dependency wait states introduced by config (service/network/resource checks) causing startup stalls.
3. Scoping/assignment error applying unintended startup workload to affected devices.

## Why Hypothesis 1 Is Most Likely
- Best fit to both core facts: timing after change and stability in no-change comparison group.
- Requires the fewest assumptions.
- Consistent with common startup degradation behavior from startup policy/script changes.

## 5 Whys Analysis
1. Why did users experience slower startup?
- Startup duration increased significantly in the affected group.

2. Why did startup duration increase in that group?
- The slowdown emerged after a new configuration was applied to that group.

3. Why is configuration implicated rather than broad environment issues?
- The unaffected comparison group had no configuration change and did not show the same degradation.

4. Why would the new configuration degrade startup?
- It likely introduced heavy synchronous startup processing, blocking checks, or additional ordered tasks at boot/logon.

5. Why did this reach production impact?
- Deployment controls did not sufficiently gate startup-cost validation (for example staged ring validation, startup-time budget checks, and effective-policy diff review) before full rollout.

## Confirmatory Checks (Fastest)
1. Pilot rollback test:
- Disable or revert only the new startup-related config on a small affected subset.
- Measure next startup duration against unchanged affected devices and unaffected group.
- Recovery after rollback strongly confirms config causality.

2. Startup trace differential:
- Compare affected vs unaffected startup traces/logs to isolate new long-duration stages/timeouts.

3. Effective policy diff:
- Compare resultant policy, script order, and assignment scope between groups.

## Remediation Actions (If Confirmed)
1. Immediate containment:
- Pause further rollout of the new configuration.

2. Stabilization:
- Roll back the startup-impacting config from affected cohort.

3. Targeted fix:
- Remove or redesign high-cost startup tasks.
- Convert blocking synchronous tasks to asynchronous/background where safe.
- Add sane timeout and retry controls for dependency checks.

4. Controlled reintroduction:
- Re-deploy corrected config through phased rings with explicit startup-time acceptance criteria.

## Order of Operations
1. Freeze rollout.
2. Pilot rollback on affected subset.
3. Validate startup recovery metrics.
4. Broad rollback if confirmed.
5. Implement corrected configuration.
6. Ring-based redeployment with gates.

## Verification of Resolution
Success criteria:
- Startup duration for affected group returns to baseline or agreed SLO threshold.
- No recurrence after corrected config deployment.
- Affected and unaffected group startup distributions converge to expected variance.

Operational checks:
- Compliance reports confirm rollback and corrected policy application.
- Follow-up startup trace samples show no abnormal blocking stage.

## Preventive Actions
1. Change governance:
- Require startup-impact assessment for any config touching boot/logon/policy processing.

2. Ring and guardrails:
- Enforce staged deployment (pilot -> limited ring -> broad ring) with auto-halt on startup KPI regression.

3. Pre-deployment technical gate:
- Mandatory effective-policy diff and startup script/task cost review.

4. Observability:
- Add startup-duration and boot-stage latency alerts tied to change windows.

5. Rollback readiness:
- Maintain tested one-click rollback path for startup-related configurations.

## Confidence and Uncertainty
- Confidence: High that configuration change is primary driver due to timing and clean no-change comparison.
- Uncertainty: Exact low-level blocking component requires trace/policy diff confirmation if not already captured.

## Closure Recommendation
Proceed with pilot rollback confirmation immediately, execute broad remediation on confirmation, and enforce startup-safe deployment controls before reintroduction.