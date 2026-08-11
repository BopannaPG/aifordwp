# Autopilot Enrolment Failure: Ranked Likely Causes

Date: 2026-08-11
Source: Scope facts from MDM diagnostic export

## 1) Pre-existing MDM enrolment blocking Autopilot enrolment

Why it fits the evidence:
- Enrolment failed with 0x80180014.
- Export explicitly states: "The device is already enrolled in MDM."
- MDMEnrolled = Yes, with legacy manual enrolment from 2023-11-04.

Fastest check to confirm or eliminate:
- In Intune/Entra, verify whether an active/stale pre-existing enrolment record exists for this hardware (serial/hardware hash/device ID) before the Autopilot attempt.

Specific remediation action if confirmed:
- Remove legacy/stale MDM enrolment association and cleanup duplicate/stale device records.
- Reprovision/reset as required and rerun Autopilot so a fresh enrolment path is created.

## 2) Policy/security baseline processing attempted before successful enrolment context

Why it fits the evidence:
- ProfilesApplied = 0 of 4.
- LastError = 0x80070005 (Access denied).
- ComplianceEngine: "Could not evaluate" because "Enrolment not complete."

Fastest check to confirm or eliminate:
- After fixing enrolment, force sync and verify whether profile application progresses from 0/4 and whether 0x80070005 clears for the same baseline.

Specific remediation action if confirmed:
- Complete/correct enrolment first.
- Re-scope/reapply the failing baseline/profile to the correct target context.
- Trigger sync and validate successful policy application.

## 3) Conflicting management path (legacy manual MDM vs Autopilot)

Why it fits the evidence:
- Enrolment source is legacy manual MDM, while current enrolment type is Autopilot.
- This coexistence indicates likely process conflict for device ownership/management state.
- Licensing and network are healthy, making conflict more plausible than entitlement/connectivity issues.

Fastest check to confirm or eliminate:
- Review device history and tenant configuration for dual-management indicators (legacy artefacts plus Autopilot registration for the same device).

Specific remediation action if confirmed:
- Standardize to a single intended path (Autopilot-managed for this endpoint).
- Retire/remove legacy manual enrolment artefacts.
- Confirm Autopilot assignment, then reprovision and enrol cleanly.

## Error code handling note

- 0x80180014: Confirmed from the provided export text as "device is already enrolled in MDM."
- 0x80070005: Confirmed from the provided export text as "Access denied."
- No additional external interpretation was assumed.
