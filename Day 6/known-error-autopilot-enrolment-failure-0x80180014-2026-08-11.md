# Known Error Record

Symptom: Users attempting to provision DESKTOP-FB099 through Autopilot experience enrolment failure, and policy/compliance progression does not complete. In the verified incident, Autopilot enrolment failed, 0 of 4 policies applied, and compliance could not be evaluated.

Cause: The verified root cause is a pre-existing legacy manual MDM enrolment state/record on the device that conflicts with new Autopilot enrolment. The failure is explicitly reported as 0x80180014 with the message "The device is already enrolled in MDM."

Scope: Confirmed scope in the RCA is a single endpoint instance: DESKTOP-FB099 for user FINBRIDGE\\rthomas. Impact is limited in the evidence set to this device’s Autopilot provisioning flow and downstream policy/compliance steps.

Workaround: Remove stale/legacy Intune managed device record(s), remove duplicate/obsolete Entra device object(s) if present, and clear the legacy work/school MDM connection and residual enrolment artefacts on the endpoint per policy. Then reboot, reset/reprovision, and rerun Autopilot enrolment.

Permanent fix: Enforce a pre-Autopilot hygiene gate that checks for and remediates legacy manual MDM enrolment markers and stale duplicate device objects before reprovisioning. Embed mandatory Intune/Entra cleanup checklist steps in the Autopilot workflow and standardize away from legacy manual enrolment for Autopilot-targeted cohorts.

How to spot it: In EnrollmentStatus, look for EnrollmentType Autopilot with EnrollmentState Failed, ErrorCode 0x80180014, and ErrorDescription "The device is already enrolled in MDM." Corroborate with DeviceInfo showing MDMEnrolled Yes and EnrolmentSource Legacy, plus downstream signals in PolicyManager (ProfilesAttempted 4, ProfilesApplied 0, LastError 0x80070005 on FinBridge-Win11-Security-Baseline) and ComplianceEngine (EvaluationResult "Could not evaluate", Reason "Enrolment not complete").