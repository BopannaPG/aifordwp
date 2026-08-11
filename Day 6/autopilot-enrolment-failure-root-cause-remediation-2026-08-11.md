# Autopilot Enrolment Failure: Confirmed Root Cause, Remediation, and Prevention

Date: 2026-08-11
Device: DESKTOP-FB099
User: FINBRIDGE\\rthomas

## 1. Executive Summary

Confirmed root cause:
- Autopilot enrolment failed because the device already had an existing legacy manual MDM enrolment (from 2023-11-04).
- The failure code in scope is 0x80180014 with description: device already enrolled in MDM.

What this means:
- Autopilot enrolment cannot complete while a conflicting prior enrolment state/record still exists.

## 2. Evidence Basis (Scope Facts Used)

- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription: The device is already enrolled in MDM
- MDMEnrolled: Yes (previous enrolment)
- EnrolmentSource: Legacy manual MDM enrolment (2023-11-04)
- AzureADJoined: Yes
- ProfilesApplied: 0 of 4
- LastError: 0x80070005 (Access denied)
- IntuneP1License: Yes
- AutopilotLicense: Yes
- Network: Required endpoints reachable, no proxy

Interpretation boundary:
- This document uses only confirmed facts above and finalized root cause direction.

## 3. Exact Remediation Steps

Legend:
- [ADMIN] = Intune/Entra admin center only, no device handling required
- [DEVICE] = requires physical or remote access to endpoint

### Phase A: Remove stale management records in cloud

1. [ADMIN] Identify all records for the device
- In Microsoft Intune admin center, go to Devices > All devices.
- Search by device name (DESKTOP-FB099), serial number, and if available Azure AD device ID.
- Note every matching record and its enrolment date/management state.

2. [ADMIN] Retire/delete stale Intune managed device record(s)
- Open stale/legacy-managed record associated with pre-Autopilot manual enrolment.
- Select Retire (if available) to issue cleanup.
- After retire state updates, delete the stale record.
- If duplicate records exist, keep only the intended current identity path for re-enrolment.

3. [ADMIN] Remove duplicate/obsolete Entra device object if conflicting
- In Microsoft Entra admin center, go to Devices > All devices.
- Locate duplicate or obsolete object tied to old enrolment state.
- Delete only stale/duplicate objects after confirming which object should represent the fresh Autopilot lifecycle.

4. [ADMIN] Validate Autopilot registration is present and correctly assigned
- In Intune admin center, go to Devices > Windows > Windows enrollment > Devices (Windows Autopilot devices).
- Confirm the target hardware hash entry exists and is assigned to the correct Autopilot profile.
- Ensure intended user assignment/group targeting is correct for this device.

### Phase B: Clear device-side legacy enrolment artefacts

5. [DEVICE] Remove legacy work/school MDM connection
- On device, open Settings > Accounts > Access work or school.
- Disconnect any legacy/manual MDM work account related to old enrolment.
- If multiple entries exist, remove only confirmed stale management connection(s).

6. [DEVICE] Remove local MDM enrolment remnants if still present
- Open elevated Command Prompt or PowerShell.
- Validate enrolment artifacts under:
  - Task Scheduler > Microsoft > Windows > EnterpriseMgmt
  - Registry enrolment branches used by MDM client state
- Remove stale entries only when matched to old enrolment GUID/context.
- If operational standard prohibits manual artifact cleanup, proceed directly to reset step below.

7. [DEVICE] Reboot the device
- Restart to ensure old enrolment context is unloaded before reprovisioning.

### Phase C: Reprovision and rerun Autopilot

8. [DEVICE] Reset/reprovision endpoint for clean OOBE
- Use approved method (Autopilot Reset or full Windows reset according to support policy).
- Device must return to OOBE where Autopilot flow is initiated again.

9. [DEVICE] Run through Autopilot sign-in and enrolment
- Sign in with licensed corporate user.
- Allow device setup/account setup phases to complete fully.
- Keep network connected until provisioning completes.

## 4. Correct Order of Operations

Follow this exact order to avoid reintroducing conflict:

1) [ADMIN] Inventory records in Intune and Entra
2) [ADMIN] Retire/delete stale Intune managed device record(s)
3) [ADMIN] Remove stale duplicate Entra device object(s) if present
4) [ADMIN] Confirm Autopilot registration/profile assignment is correct
5) [DEVICE] Disconnect legacy work/school MDM connection
6) [DEVICE] Clear residual local enrolment artefacts as per policy
7) [DEVICE] Reboot
8) [DEVICE] Reset/reprovision to OOBE
9) [DEVICE] Re-run Autopilot enrolment
10) [ADMIN + DEVICE] Verify successful enrolment and policy application

## 5. Verification Checks After Remediation

Success criteria should be checked in both admin center and on device.

### Admin center verification

1. Intune admin center:
- Device appears as enrolled under expected user.
- Enrolment timestamp is current (post-remediation).
- No duplicate stale managed device entry remains.

2. Autopilot deployment status:
- Device shows successful completion for deployment profile flow.
- No repeat 0x80180014 failure signal.

3. Device configuration/policy status:
- Previously failing baseline now applies (not 0 of 4).
- Policy status transitions to Succeeded/In progress then Succeeded.

### Device-side verification

4. Access work or school:
- Only intended active corporate connection is present.

5. MDM diagnostics:
- Enrolment state reports success.
- Prior conflict symptom (already enrolled) is absent.

6. Functional validation:
- Security baseline settings begin enforcing.
- Compliance evaluation runs (no longer blocked by enrolment incomplete).

## 6. Preventive Action for Other Legacy-Enrolled Devices

Implement a pre-Autopilot hygiene control:

1. [ADMIN] Build a pre-flight detection query/report
- Identify devices with legacy/manual enrolment markers and Autopilot targeting overlap.
- Flag duplicates across Intune managed devices and Entra device objects.

2. [ADMIN] Add a mandatory cleanup workflow before Autopilot assignment
- Require stale record retirement/deletion checklist completion before scheduling reprovisioning.
- Track completion in service desk change template.

3. [ADMIN] Standardize single enrolment path policy
- Disable or retire manual legacy enrolment pathways for device cohorts that must use Autopilot.
- Update endpoint build SOP so Autopilot is the only permitted provisioning route.

4. [ADMIN] Add operational guardrail
- Weekly automation/report to detect duplicate device identities and legacy MDM enrolments.
- Route findings to endpoint engineering queue for cleanup before user-impacting reprovision events.

## 7. Closure Statement

Root cause is confirmed as stale legacy MDM enrolment conflict. Remediation requires cloud record cleanup first, then endpoint cleanup/reset, then Autopilot rerun, followed by dual-plane verification (admin center and endpoint). Prevention should focus on pre-flight legacy enrolment detection and enforced cleanup prior to any Autopilot provisioning activity.
