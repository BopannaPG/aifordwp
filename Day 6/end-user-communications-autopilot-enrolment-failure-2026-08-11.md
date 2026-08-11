# End-User Communication Pack

## Audience 1 - Non-technical executive
Your access and data are safe. One device (DESKTOP-FB099, user FINBRIDGE\\rthomas) failed automatic setup on 2024-03-15 because an older setup record from 2023-11-04 was still attached, and the system returned "already enrolled" (0x80180014). As a result, 0 of 4 policy settings applied and device checks could not complete. License and connection checks were normal. IT is removing old records, resetting the device, and rerunning setup. You do not need to do anything.

## Audience 2 - Affected end-user team (10 people, non-technical)
Hi team - this issue happened because one computer (DESKTOP-FB099) still had an older device setup record from 2023-11-04, so when setup was run again on 2024-03-15 it was blocked as "already enrolled" (0x80180014). In that state, 0 of 4 policy settings applied and checks could not finish, while license and connection checks were normal. If you see the same message, stop and contact IT so they can remove old records, reset the device, and rerun setup. Please contact the endpoint/Intune support team.

## Audience 3 - Engineer-to-engineer internal note
Incident/device/user: DESKTOP-FB099 / FINBRIDGE\\rthomas.

Root cause (verified): pre-existing legacy manual MDM enrolment state/record (dated 2023-11-04) conflicted with Autopilot enrolment, resulting in EnrollmentState Failed with ErrorCode 0x80180014 and ErrorDescription "The device is already enrolled in MDM" at 2024-03-15 09:18:44.

Downstream impact observed: PolicyManager ProfilesAttempted=4, ProfilesApplied=0, LastError=0x80070005 on FailedProfile FinBridge-Win11-Security-Baseline (2024-03-15 09:19:01); ComplianceEngine EvaluationResult="Could not evaluate" with Reason="Enrolment not complete" (2024-03-15 09:19:45).

Exclusionary checks: IntuneP1License=Yes, AutopilotLicense=Yes, M365LicenseFound=Yes; endpoint reachability OK for login.microsoftonline.com, enrollment.manage.microsoft.com, enterpriseregistration.windows.net; ProxyDetected=No.

Exact action taken/required from RCA corrective path: remove stale/legacy Intune managed device record(s); remove duplicate/obsolete Entra device object(s) if present; validate Autopilot hardware registration/profile assignment (FinBridge-Autopilot-Standard); remove legacy work/school MDM connection and residual enrolment artefacts on endpoint per policy; reboot, reset/reprovision, rerun Autopilot enrolment.

Verification step(s): enrolment completes successfully with current timestamp; no repeat 0x80180014; single intended device object lifecycle state in Intune/Entra (no stale duplicates); policy application progresses beyond 0/4 with baseline deployment success; compliance evaluation completes without "enrolment not complete."

Preventive action needed: enforce pre-Autopilot enrolment hygiene gate for legacy manual enrolment markers and duplicate device objects; add mandatory Intune stale record review + Entra duplicate object review + cleanup confirmation before reprovisioning; retire legacy manual enrolment for Autopilot-targeted cohorts; schedule detection/reporting for legacy+Autopilot overlap and duplicate identities; publish this pattern/runbook to analyst playbook.