# Root Cause Analysis (RCA)

## Incident Title
Autopilot enrolment failure due to pre-existing legacy MDM enrolment conflict

## Document Control
- RCA Date: 2026-08-11
- Incident Device: DESKTOP-FB099
- Affected User: FINBRIDGE\\rthomas
- Source Data: MDM Diagnostic Export (captured 2024-03-15)

## 1) Executive Summary
Autopilot enrolment failed because the endpoint already had an existing legacy manual MDM enrolment record/state. The export explicitly reports failure code 0x80180014 with message "The device is already enrolled in MDM." As a result, Autopilot could not establish a clean new enrolment session, downstream policy deployment did not apply (0/4 profiles), and compliance evaluation could not proceed.

## 2) Scope and Impact
- Scope: Single confirmed endpoint instance in supplied dataset
- Primary impact:
  - Autopilot enrolment failed
  - Device policy/security baseline did not apply
  - Compliance engine could not evaluate device state
- Business impact:
  - Delayed provisioning and endpoint readiness
  - Manual intervention required by endpoint/Intune administrators

## 3) Supporting Evidence

### 3.1 EnrollmentStatus evidence
- EnrollmentType: Autopilot
- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription: The device is already enrolled in MDM
- Timestamp: 2024-03-15 09:18:44

### 3.2 DeviceInfo evidence
- AzureADJoined: Yes
- MDMEnrolled: Yes (previous enrolment)
- EnrolmentSource: Legacy (manual MDM enrolment, 2023-11-04)
- AutopilotProfile: FinBridge-Autopilot-Standard

### 3.3 PolicyManager evidence
- ProfilesAttempted: 4
- ProfilesApplied: 0
- LastError: 0x80070005 (Access denied)
- FailedProfile: FinBridge-Win11-Security-Baseline
- Timestamp: 2024-03-15 09:19:01

### 3.4 ComplianceEngine evidence
- EvaluationResult: Could not evaluate
- Reason: Enrolment not complete
- Timestamp: 2024-03-15 09:19:45

### 3.5 Licensing and network evidence (exclusionary checks)
- IntuneP1License: Yes
- AutopilotLicense: Yes
- M365LicenseFound: Yes
- Endpoint reachability:
  - login.microsoftonline.com: OK
  - enrollment.manage.microsoft.com: OK
  - enterpriseregistration.windows.net: OK
- ProxyDetected: No

Conclusion from evidence set:
- Licensing and network are healthy and do not explain this failure instance.
- Failure aligns directly with existing enrolment conflict.

## 4) Timeline of Events

- 2023-11-04
  - Legacy manual MDM enrolment created on device (from EnrolmentSource metadata).

- 2024-03-15 09:18:44
  - Autopilot enrolment attempt fails.
  - Reported: EnrollmentState Failed, ErrorCode 0x80180014, already enrolled in MDM.

- 2024-03-15 09:19:01
  - Policy manager attempts 4 profiles; applies 0.
  - LastError 0x80070005 recorded against security baseline profile.

- 2024-03-15 09:19:45
  - Compliance evaluation does not run to completion.
  - Reason logged: enrolment not complete.

- 2026-08-11
  - Analysis finalized; root cause confirmed and remediation/prevention documented.

## 5) Root Cause Statement
The proximate and confirmed root cause is a pre-existing legacy manual MDM enrolment associated with the device, which conflicted with Autopilot enrolment and prevented successful completion of the new enrolment transaction.

## 6) 5-Why Analysis

1. Why did Autopilot enrolment fail?
- Because enrolment returned failed state with 0x80180014 and message indicating the device is already enrolled in MDM.

2. Why was the device considered already enrolled?
- Because the device had a prior legacy manual MDM enrolment record/state (dated 2023-11-04).

3. Why did that prior enrolment block provisioning progress?
- Because Autopilot expected a clean enrolment path, but encountered an existing management context that conflicted with creating/using the intended Autopilot-managed enrolment.

4. Why was the conflicting state not removed before reprovisioning?
- Because no enforced pre-flight cleanup gate was applied to detect and remediate legacy/manual enrolment artefacts before Autopilot execution.

5. Why was no gate enforced?
- Because operational process controls did not require mandatory duplicate/stale enrolment checks and cleanup for legacy-managed devices entering Autopilot flow.

Systemic cause identified:
- Process/control gap in pre-Autopilot hygiene for previously legacy-enrolled devices.

## 7) Corrective Actions (Implemented/Required)

### 7.1 Immediate corrective actions for affected device
- Remove stale/legacy Intune managed device record(s).
- Remove duplicate/obsolete Entra device object(s) if present.
- Validate Autopilot hardware registration/profile assignment.
- On endpoint, remove legacy work/school MDM connection and residual enrolment artefacts per policy.
- Reboot, reset/reprovision, rerun Autopilot enrolment.

### 7.2 Verification criteria after corrective action
- Enrolment completes successfully with current timestamp.
- No repeat 0x80180014 conflict signal.
- Device appears once (no stale duplicates) in Intune/Entra for intended lifecycle state.
- Policy application progresses beyond 0/4 and baseline deployment succeeds.
- Compliance evaluation runs successfully (no "enrolment not complete" blocker).

## 8) Preventive Actions

1. Pre-flight enrolment hygiene control
- Mandate pre-Autopilot check for legacy manual MDM enrolment markers and stale duplicate device objects.

2. Service desk/engineering workflow gate
- Add required checklist step before Autopilot reprovisioning:
  - Intune stale record review
  - Entra duplicate object review
  - Cleanup confirmation

3. Standardize enrolment pathway
- Retire legacy manual enrolment practices for cohorts designated for Autopilot provisioning.

4. Continuous detection and reporting
- Run scheduled report/automation to detect:
  - Devices with both legacy enrolment indicators and Autopilot targeting
  - Duplicate managed identities likely to cause re-enrolment conflicts
- Route findings to endpoint engineering queue for proactive cleanup.

5. Knowledge update
- Publish this failure pattern and response runbook to analyst playbook so first-line triage can identify and escalate quickly.

## 9) Residual Risk
Without preventive controls, any device carrying legacy enrolment artefacts may experience repeat Autopilot enrolment failure during reprovisioning events.

## 10) Closure Recommendation
Close incident after successful re-enrolment verification on DESKTOP-FB099 and confirmation that preventive controls are embedded in the standard Autopilot onboarding workflow.