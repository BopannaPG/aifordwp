# Version Header
- Title: Runbook - Autopilot Enrolment Failure 0x80180014 (Legacy MDM Conflict)
- Version: 1.0
- Date: 11/08/2026
- Author: Bopanna
- Reviewed: self
- Status: draft
- Change: initial version from RCA

# Runbook: Autopilot Enrolment Failure 0x80180014 (Legacy MDM Conflict)

## 1) Prerequisites
- [ ] Confirm you can sign in to Intune admin center: https://intune.microsoft.com. [ELEVATED]
- [ ] Confirm your role can delete managed devices in Intune (device cleanup rights). [ELEVATED]
- [ ] Confirm you can sign in to Entra admin center: https://entra.microsoft.com. [ELEVATED]
- [ ] Confirm your role can delete Entra device objects. [ELEVATED]
- [ ] Confirm you can open Autopilot devices in Intune at Devices > Windows > Windows enrollment > Devices. [ELEVATED]
- [ ] Confirm you have remote or physical access to the endpoint to use Windows Settings and restart/reset the device. [ELEVATED]
- [ ] Collect mandatory end-user details before starting:
	- Device name: DESKTOP-FB099
	- User: FINBRIDGE\\rthomas
	- Error code/message seen by user: 0x80180014 / "The device is already enrolled in MDM"
	- Date/time of latest failure attempt
- [ ] Confirm incident evidence source is available: MDM Diagnostic Export package captured for this incident.
- [ ] Confirm you know the four required evidence modules to review in that package: EnrollmentStatus, DeviceInfo, PolicyManager, ComplianceEngine.

## 2) Procedure
1. Open the incident's MDM Diagnostic Export package from the ticket attachment store.
Expected result: The package opens and you can browse module outputs.

2. Open the EnrollmentStatus module in the export package.
Expected result: You can see EnrollmentType, EnrollmentState, ErrorCode, ErrorDescription, and timestamp fields.

3. Confirm EnrollmentType is Autopilot and ErrorCode is 0x80180014 with "The device is already enrolled in MDM."
Expected result: The incident matches the known legacy-enrolment conflict signature.

4. Open the DeviceInfo module in the export package.
Expected result: You can see MDMEnrolled and EnrolmentSource values.

5. Confirm DeviceInfo shows MDMEnrolled = Yes and EnrolmentSource = Legacy.
Expected result: Prior legacy enrolment state is confirmed.

6. Open Intune admin center at https://intune.microsoft.com, then go to Devices > All devices.
Expected result: The Intune managed device list is visible.

7. Search for DESKTOP-FB099 in Devices > All devices.
Expected result: Matching managed device record(s) are listed.

8. Delete stale or legacy managed device record(s) for DESKTOP-FB099 in Intune. [ELEVATED]
Expected result: Stale/legacy Intune record(s) are removed.

9. Open Entra admin center at https://entra.microsoft.com, then go to Identity > Devices > All devices.
Expected result: The Entra device object list is visible.

10. Search for DESKTOP-FB099 in Identity > Devices > All devices.
Expected result: Matching Entra device object(s) are listed.

11. Delete duplicate or obsolete Entra device object(s) for DESKTOP-FB099. [ELEVATED]
Expected result: Duplicate/obsolete Entra object(s) are removed.

12. Return to Intune and go to Devices > Windows > Windows enrollment > Devices.
Expected result: Windows Autopilot device list is visible.

13. Search for DESKTOP-FB099 in the Autopilot device list.
Expected result: The device appears in Autopilot registration.

14. Open the DESKTOP-FB099 Autopilot device record.
Expected result: The assignment details pane opens.

15. Confirm assigned profile is FinBridge-Autopilot-Standard. [ELEVATED]
Expected result: Intended Autopilot profile assignment is confirmed.

16. On DESKTOP-FB099, open Windows Settings > Accounts > Access work or school.
Expected result: Connected work/school accounts and MDM connection entries are visible.

17. Remove the legacy work/school MDM connection entry. [ELEVATED]
Expected result: The legacy MDM connection no longer appears.

18. Remove residual enrolment artefacts on DESKTOP-FB099 using your endpoint policy cleanup procedure. [ELEVATED]
Expected result: Legacy enrolment artefacts are cleared according to local policy controls.

19. Restart DESKTOP-FB099 from Windows Start menu > Power > Restart.
Expected result: Device reboots and returns to sign-in/provisioning readiness.

20. Start reset/reprovision from Windows Settings > System > Recovery > Reset this PC.
Expected result: Device enters reset/reprovision workflow.

21. Run Autopilot enrolment on the reprovisioned device.
Expected result: Enrolment proceeds without immediate 0x80180014 conflict.

22. Open the PolicyManager module in the latest diagnostics after the retry.
Expected result: ProfilesAttempted and ProfilesApplied values are available for post-fix comparison.

23. Open the ComplianceEngine module in the latest diagnostics after the retry.
Expected result: EvaluationResult and Reason values are available for post-fix comparison.

## 3) Verification
1. Open Intune admin center at https://intune.microsoft.com and go to Devices > All devices, then search DESKTOP-FB099.
Expected result: A single active managed device record is shown for DESKTOP-FB099.

2. Open Entra admin center at https://entra.microsoft.com and go to Identity > Devices > All devices, then search DESKTOP-FB099.
Expected result: A single active device object is shown for DESKTOP-FB099.

3. Open the latest MDM Diagnostic Export from the post-fix attempt and open the EnrollmentStatus module.
Expected result: EnrollmentState is not Failed for this attempt, timestamp is current, and ErrorCode 0x80180014 is not present.

4. In the same export package, open the PolicyManager module.
Expected result: ProfilesApplied is greater than 0 and no blocking failure state remains at 0/4.

5. In the same export package, open the ComplianceEngine module.
Expected result: EvaluationResult is successful and Reason is not "enrolment not complete."

6. In the same export package, open the DeviceInfo module.
Expected result: The module reflects the current post-fix enrolment context without legacy-conflict indicators driving the failed attempt.

## 4) Rollback
1. Stop active remediation immediately and do not delete any additional Intune or Entra objects.
Expected result: State changes are frozen to prevent further drift.

2. Open Intune admin center at https://intune.microsoft.com > Devices > Windows > Windows enrollment > Devices and search DESKTOP-FB099. [ELEVATED]
Expected result: You confirm the device is still present in Autopilot registration.

3. Open the DESKTOP-FB099 Autopilot record and confirm assigned profile FinBridge-Autopilot-Standard. [ELEVATED]
Expected result: Correct profile assignment is verified in less than one minute.

4. On DESKTOP-FB099, open Windows Settings > Accounts > Access work or school and confirm no additional disconnect/remove actions are pending.
Expected result: Endpoint-side rollback stops further local changes.

5. Open the latest MDM Diagnostic Export and capture screenshots of EnrollmentStatus, DeviceInfo, PolicyManager, and ComplianceEngine.
Expected result: Complete rollback evidence set is ready for escalation.

6. Escalate to endpoint/Intune engineering with subject "Rollback invoked - Autopilot 0x80180014" and attach the four module captures.
Expected result: Handoff is complete within three minutes with actionable diagnostics.

## 5) Notes
- Confirmed RCA scope is a single endpoint instance in the supplied dataset: DESKTOP-FB099 for FINBRIDGE\\rthomas.
- This failure pattern is specifically aligned to pre-existing legacy manual MDM enrolment conflict; licensing and network checks in this incident were healthy.
- Relevant technical signals from this incident: ErrorCode 0x80180014 ("The device is already enrolled in MDM"), PolicyManager LastError 0x80070005 on FinBridge-Win11-Security-Baseline, ComplianceEngine "Could not evaluate" with reason "enrolment not complete."
- Preventive control required by RCA: enforce pre-Autopilot hygiene checks for legacy enrolment markers and duplicate objects, and require Intune/Entra cleanup confirmation before reprovisioning.
- Residual risk from RCA: without preventive controls, devices carrying legacy enrolment artefacts can repeat this failure during reprovisioning.