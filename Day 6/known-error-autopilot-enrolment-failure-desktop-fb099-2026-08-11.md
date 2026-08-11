Symptom: Autopilot enrolment on DESKTOP-FB099 fails and provisioning does not complete. In the verified incident, policy deployment remained at 0/4 profiles and compliance evaluation could not proceed.

Cause: The verified root cause is a pre-existing legacy manual MDM enrolment state/record on the device that conflicts with Autopilot enrolment. EnrollmentStatus reported ErrorCode 0x80180014 with ErrorDescription "The device is already enrolled in MDM."

Scope: Confirmed scope is a single endpoint instance in the supplied dataset: DESKTOP-FB099 for user FINBRIDGE\\rthomas. Impact in this case is limited to this device’s Autopilot enrolment, policy application, and compliance evaluation flow.

Workaround: Remove stale/legacy Intune managed device record(s) and duplicate/obsolete Entra device object(s) if present. Remove legacy work/school MDM connection and residual enrolment artefacts on the endpoint per policy, then reboot, reset/reprovision, and rerun Autopilot enrolment.

Permanent fix: Implement a mandatory pre-Autopilot hygiene gate to detect and remediate legacy manual enrolment markers and duplicate device objects before reprovisioning. Add required workflow checks for Intune stale records, Entra duplicate objects, and cleanup confirmation.

How to spot it: Look for EnrollmentType Autopilot with EnrollmentState Failed, ErrorCode 0x80180014, and ErrorDescription "The device is already enrolled in MDM" (EnrollmentStatus timestamp in this incident: 2024-03-15 09:18:44). Corroborate with DeviceInfo showing MDMEnrolled Yes and EnrolmentSource Legacy (manual enrolment dated 2023-11-04), plus PolicyManager signals (ProfilesAttempted 4, ProfilesApplied 0, LastError 0x80070005 on FinBridge-Win11-Security-Baseline) and ComplianceEngine signals (EvaluationResult "Could not evaluate", Reason "Enrolment not complete").