# Root Cause Analysis (RCA)

## Incident Title
Intune Win32 app failure: Adobe Acrobat Pro v23.6 returns MSI 1603 on AVD pool after overnight image update

## Date of RCA
2026-08-12

## Analyst
DWP Engineer

## Incident Scope
- Affected service: Intune Win32 app deployment (Adobe Acrobat Pro v23.6)
- Affected install context: SYSTEM
- Affected target segment: One AVD pool (per scope clue)
- Triggering change clue: Overnight image update to that pool only
- User impact: App install fails and retries hourly; app remains unavailable on affected devices

## Executive Summary
Adobe Acrobat Pro deployment failed repeatedly with MSI return code 1603 in SYSTEM context. The strongest pattern is timing and blast-radius alignment with a single-pool overnight image update, indicating image-specific drift or prerequisite conflict as the primary failure class. A detection-rule mismatch (Reader key used for Pro deployment) is also present and increases retry churn, but does not by itself explain the 1603 install failure.

At this stage, the evidence supports a probable image-related install-path issue, not yet a single proven code-level root cause. Final technical root cause requires MSI verbose log confirmation (first "Return value 3" failure point).

## Evidence Collected

### A. Direct log evidence (provided excerpt)
1. [2024-03-15 10:01:00] Agent starts Adobe Acrobat Pro v23.6 install.
2. [2024-03-15 10:01:01] Install context is SYSTEM.
3. [2024-03-15 10:01:03] Command executed: msiexec /i AcrobatPro.msi /quiet.
4. [2024-03-15 10:01:44] Return code 1603.
5. [2024-03-15 10:01:45] Detection checks HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 and reports value not found.
6. [2024-03-15 10:01:47] Result failed; retry scheduled 60 minutes.
7. [2024-03-15 11:01:47] Retry attempt starts.
8. [2024-03-15 11:02:31] Retry returns 1603 again.

### B. Correlation evidence from scope facts
1. Failures align to an overnight image update window.
2. Issue scope is one pool only, not broad tenant-wide failure.
3. Repeated quick-fail pattern (~40-45 sec) suggests early MSI prerequisite/custom action/dependency failure rather than long-running install timeout.

### C. What is not yet evidenced in provided data
1. No MSI verbose log snippet (missing exact failing custom action).
2. No app content staging listing from affected endpoint.
3. No pre/post image software inventory comparison output.
4. No explicit reboot-pending markers shown.

## Timeline (UTC/local per source log)

1. 10:01:00 - IME begins install workflow for Adobe Acrobat Pro v23.6.
2. 10:01:03 - SYSTEM executes silent MSI install command.
3. 10:01:44 - Installer exits with 1603.
4. 10:01:45 - Detection rule checks Reader registry path; key/value absent.
5. 10:01:47 - Deployment state set to failed; retry planned in 60 minutes.
6. 11:01:47 - Retry cycle begins.
7. 11:02:31 - Retry fails with same 1603 failure code.
8. 11:02:32 - Next retry scheduled.

## Problem Statement
Why does Adobe Acrobat Pro v23.6 fail with MSI 1603 in SYSTEM context on devices in one pool after an overnight image update, while deployment keeps retrying and remaining undetected?

## 5 Whys Analysis

1. Why did users not receive Acrobat Pro?
- Because the Intune Win32 install failed and app stayed undetected.

2. Why did install fail?
- MSI execution repeatedly exited with 1603 during silent SYSTEM install.

3. Why did MSI return 1603 repeatedly on that segment?
- Most likely an image-specific prerequisite/dependency/conflict condition introduced by the overnight pool image update.

4. Why was the issue noisy and persistent?
- Detection rule checked a Reader registry path for a Pro deployment, so state remained "Not detected" and triggered repeated retries.

5. Why was this not prevented before broad pool impact?
- Image change validation and app-detection validation gates were insufficient for this app/pool combination before rollout.

## Root Cause and Contributing Factors

### Probable Root Cause (current confidence: medium-high)
Image-specific application compatibility drift introduced overnight in one pool, causing Acrobat Pro MSI to fail early with 1603 under SYSTEM context.

### Contributing Factors
1. Detection rule mismatch:
- Configured detection target references Acrobat Reader registry path instead of Acrobat Pro signal.
- Effect: retry churn and delayed accurate state interpretation.

2. Validation gap before image rollout:
- No evidence of a successful canary install validation for this exact Win32 app on the updated pool image.

3. Limited diagnostics in initial deployment command:
- Install command omits verbose MSI logging, slowing fault isolation.

## Alternative Hypotheses Considered
1. Package content/path issue in IME staging (missing MST/CAB/dependency): plausible, unproven.
2. Pre-existing Adobe version conflict on updated image: plausible, likely related, unproven.
3. Pending reboot/servicing lock condition after maintenance: plausible, unproven.

## Corrective Actions (Immediate)
1. Run one controlled install on affected pool VM with MSI verbose logging:
- msiexec /i AcrobatPro.msi /qn /norestart /L*v C:\Windows\Temp\AcrobatPro-1603.log
2. Capture first "Return value 3" block and failing custom action.
3. Compare installed Adobe footprint between affected and unaffected pool images.
4. Validate IME staged payload completeness on affected endpoint.
5. Correct detection logic to Acrobat Pro-appropriate rule (prefer MSI product code where possible).

## Preventive Actions (Systemic)

### Change and release controls
1. Introduce mandatory canary validation for top-tier Win32 apps on any new AVD image before pool-wide rollout.
2. Add pool-scoped rollback trigger: if same app returns >N failures with same code within 60 minutes, pause deployment and revert image for that pool.

### Packaging and detection standards
1. Standardize detection design hierarchy:
- Primary: MSI product code
- Secondary: validated Pro-specific registry/file signal
2. Enforce packaging checklist requiring:
- Silent install command tested in SYSTEM context
- Verbose logging switch documented for rapid diagnostics

### Monitoring and alerting
1. Create alert for repeated 1603 bursts by app + pool + image version.
2. Create alert for detection mismatch patterns (install fail + immediate not-detected on known mismatched key family).

### Knowledge and operations
1. Publish runbook for "1603 after image update" triage path.
2. Train service desk on identifying detection-rule mismatch vs installer-failure distinction.

## Validation Plan
1. Technical validation:
- Confirm exact MSI failure mechanism from verbose log and remediate.
2. Functional validation:
- Successful install and detection on at least one affected pool VM and one unaffected control VM.
3. Stability validation:
- No repeat 1603 for 24 hours across affected pool after fix.
4. Governance validation:
- Canary gate and rollback trigger documented and activated for next image cycle.

## Residual Risk
- Until MSI verbose evidence is reviewed, there is residual risk that the actual failure is a packaging/content issue rather than image drift.
- Detection correction alone will not resolve 1603; both installer root cause and detection accuracy must be addressed.

## Final Status
RCA completed with evidence-based probable cause and defined verification path. Final definitive root cause remains conditional on MSI verbose-log confirmation.