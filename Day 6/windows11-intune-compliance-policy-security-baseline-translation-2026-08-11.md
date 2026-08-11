# Windows 11 Intune Compliance Policy Mapping (Security Baseline)

Date: 2026-08-11  
Scope: Windows 11 corporate devices  
Policy type: Intune Device Compliance Policy (Windows 10 and later)

## Recommended Intune UI Path (latest known)
Intune admin center > Devices > Compliance > Policies > Create policy > Platform: Windows 10 and later > Profile type: Compliance policy.

> Note on UI drift: Intune UI labels and section names change periodically. Paths below are the latest commonly used paths, but you should verify in your tenant.

## Requirement Mapping

| Requirement | Settings name (exact Intune setting name) | Value | Effect (plain English) | False-positive risk | Recommendation (reduce false positives without weakening security) | UI path and drift flag |
|---|---|---|---|---|---|---|
| 1. BitLocker must be enabled on the OS drive | Device health > Require BitLocker | Require | Device is compliant only if BitLocker protection is active and attested. | Encryption completed but compliance still stale until reboot/check-in; suspended protection after BIOS/firmware work. | Keep this setting, and add runbook guidance: reboot once after encryption and force sync before incident escalation. | Devices > Compliance > Policies > Windows 10 and later policy > Compliance settings > Device health > Require BitLocker. Drift risk: Low. |
| 2. Secure Boot must be enabled | Device health > Require Secure Boot to be enabled on the device | Require | Device is compliant only when Secure Boot is enabled in UEFI. | Legacy BIOS installs, unsupported TPM scenarios, and some VM templates without Secure Boot report noncompliant. | Assign to supported hardware groups first; keep temporary exception group with expiry for legacy remediation. | Devices > Compliance > Policies > Windows 10 and later policy > Compliance settings > Device health > Require Secure Boot to be enabled on the device. Drift risk: Low. |
| 3. Minimum OS build N-1 (22621.2861) | Device properties > Minimum OS version | 10.0.22621.2861 | Devices below the defined build are noncompliant. | Device patched but pending reboot; delayed inventory update right after quality update install. | Keep N-1 floor and combine with Update Rings deadlines; allow short operational buffer before enforcement actions. | Devices > Compliance > Policies > Windows 10 and later policy > Compliance settings > Device properties > Minimum OS version. Drift risk: Low. |
| 4. Windows Defender real-time protection must be on | System security > Defender > Real-time protection | Require | Real-time malware scanning must be enabled. | Defender can report unhealthy during AV engine startup or when third-party AV takes primary role. | Keep this as Require and standardize one AV strategy. If third-party AV is used, verify it is properly registered with Windows Security Center. | Devices > Compliance > Policies > Windows 10 and later policy > Compliance settings > System security > Defender > Real-time protection. Drift risk: Medium (Defender subsection can appear collapsed/renamed by UI refresh). |
| 5. Firewall must be enabled for all profiles | System security > Device security > Firewall | Require | Firewall must be on and users cannot turn it off. | Sync immediately after reboot/sleep can briefly show Error/Not compliant; conflicting GPO may override local state. | Keep as Require; remove conflicting legacy GPO and enforce profile-specific rules through Endpoint security firewall policy. | Devices > Compliance > Policies > Windows 10 and later policy > Compliance settings > System security > Device security > Firewall. Drift risk: Medium (section layout can move). |
| 6. A PIN or password must be configured | System security > Password > Require a password to unlock mobile devices | Require | User must have a sign-in credential configured before device access. | Kiosk/autologon/shared devices, or policies that intentionally disable interactive credential prompts. | Keep as Require for user endpoints. For stronger control without extra false positives: Password type = Device default, Minimum password length = organization standard. | Devices > Compliance > Policies > Windows 10 and later policy > Compliance settings > System security > Password > Require a password to unlock mobile devices. Drift risk: Medium (wording is legacy but still used in Windows policy). |
| 7. Device must not be jailbroken or rooted | No direct Windows compliance setting named Jailbroken devices | N/A | Windows compliance profile has no jailbreak/root toggle. | Auditors may expect parity with mobile platforms and treat this as missing. | Use compensating control: Microsoft Defender for Endpoint > Require the device to be at or under the machine risk score = Medium (or stricter). Document mapping in security baseline exceptions register. | Devices > Compliance > Policies > Windows 10 and later policy > Compliance settings > Microsoft Defender for Endpoint > Require the device to be at or under the machine risk score. Drift risk: Low-Medium. |

## Grace Period (all settings)

| Setting area | Settings name (exact Intune setting name) | Value | Effect | False-positive risk | Recommendation | UI path and drift flag |
|---|---|---|---|---|---|---|
| Actions for noncompliance | Mark device noncompliant | 7 days | Device is given 7 days to remediate before noncompliant state is enforced for access decisions. | High-risk devices can retain access during grace window if Conditional Access is linked only to compliance state. | Keep 7 days as requested; add immediate notification action and escalation reminders during grace period. | Devices > Compliance > Policies > Select policy > Properties > Actions for noncompliance > Mark device noncompliant. Drift risk: Low. |

## Notes for Implementation
- Apply this policy to a pilot group first, validate reporting for 5-7 days, then expand assignment.
- Ensure device check-in frequency and update ring cadence support the OS minimum-build objective.
- For Requirement 7, record the compensating control decision in governance documentation to satisfy audit traceability.

## UI Validation Notes (based on current Microsoft reference)
- Correct setting label is Real-time protection (not Require real-time protection).
- Firewall is under System security > Device security.
- Password requirement label remains Require a password to unlock mobile devices for Windows compliance UI.
- Platform string is Windows 10 and later.

## Correct UI Steps for BitLocker (current portal flow)
1. Go to Intune admin center > Devices > Compliance > Policies.
2. Select Create policy.
3. In Create a policy:
	Platform = Windows 10 and later
	Profile type = Compliance policy
4. Select Create.
5. On Basics, enter name/description, then select Next.
6. On Compliance settings, expand Device health.
7. Set Require BitLocker = Require.
8. Select Next through remaining pages, set Actions for noncompliance (7 days), assign groups, then Create.

## If You Still Do Not See Require BitLocker
- Confirm you selected Platform: Windows 10 and later and Profile type: Compliance policy. Other policy types do not show this control.
- Confirm you are editing a Compliance policy, not Endpoint security policy or Configuration profile.
- On Compliance settings page, expand Device health (it may be collapsed by default).
- If policy was created earlier with different platform/profile, create a new policy with the exact selections above.

## Equivalent Backup Check (if attestation control is unavailable in your tenant)
- Use System security > Encryption > Encryption of data storage on a device = Require.
- Keep this as fallback only; preferred control for your requirement remains Device health > Require BitLocker.

## Post-Assignment Validation Steps (after device sync)

### 1) Where to check this device status for this specific policy
Primary path (policy-centric):
1. Intune admin center > Devices > Compliance > Policies.
2. Select your Windows 10 and later compliance policy.
3. Open Device status.
4. Search for the test device name.
5. Select the device row to view setting-level results (including BitLocker row status/reason).

Alternative path (device-centric):
1. Intune admin center > Devices > All devices.
2. Open the test device.
3. Open Device compliance.
4. Select the same policy to view per-setting results.

### 2) Meaning of Compliant, Not compliant, and In grace period (Conditional Access impact)
- Compliant: Device satisfied required settings. If Conditional Access requires compliant device, access is allowed (subject to other CA controls).
- Not compliant: Device failed one or more required settings and grace period has expired or no grace is configured. If Conditional Access requires compliant device, access is blocked.
- In grace period: Device currently fails one or more settings but is still inside configured remediation window (7 days in this policy). Access impact depends on tenant behavior and CA evaluation timing; operationally treat as at-risk and remediate before grace expiry to avoid automatic transition to blocked state.

### 3) If BitLocker shows Not compliant but BitLocker is enabled: top 3 false-positive causes and fastest check
1. Cause: Health attestation is stale because compliance is measured at boot.
	Fastest check: Reboot once, then force Intune sync from Company Portal (or Settings > Accounts > Access work or school > Info > Sync), then recheck policy Device status after next check-in.

2. Cause: BitLocker state changed recently (encryption just completed or protection was suspended/resumed) but attestation not refreshed yet.
	Fastest check: Run manage-bde -status on OS drive and confirm Protection Status = Protection On and Conversion Status = Fully Encrypted; then reboot and sync.

3. Cause: Reporting latency or identity mismatch (recent rename/re-enrollment/dual records) causes stale device object result.
	Fastest check: Verify the same Entra/Intune device object is being reviewed (last check-in time is current), and compare compliance timestamp against latest sync time.

## 24-Hour Safety Monitoring After Broad Assignment
- Monitor policy Device status counts every 2-4 hours: Compliant vs Not compliant vs In grace period.
- Monitor setting-level failure concentration for Require BitLocker specifically.
- Track median time from first noncompliant to compliant after reboot+sync guidance.
- Sample failed devices and confirm local BitLocker truth (manage-bde) vs Intune result mismatch rate.
- Alert threshold recommendation: if BitLocker noncompliance spikes above expected baseline for a rollout wave, pause new assignments and trigger triage runbook.
