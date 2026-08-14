# Day 9 - JAMF Configuration Profile Mapping (macOS Security Baseline)

Date: 2026-08-14  
Scope: 25-device macOS Design team fleet  
Policy type: JAMF Pro Configuration Profiles plus Smart Group and update policy enforcement

## Recommended JAMF UI Path (latest known)

Computers > Configuration Profiles > New.

For OS version enforcement and automated remediation targeting:
Computers > Smart Computer Groups, and Computers > Policies or Software Updates (depending on your JAMF update workflow).

> Note on UI drift: JAMF Pro UI labels, payload names, and page structure can change by version. Paths below are the latest commonly used patterns, but verify in your JAMF instance before production rollout.

## Requirement Mapping

| Requirement | Payload type | Value | Effect (plain English) | False-positive risk | Recommendation (reduce false positives without weakening security) | UI path and drift flag |
|---|---|---|---|---|---|---|
| 1. FileVault disk encryption must be enabled | Security and Privacy payload (FileVault), or dedicated Disk Encryption method in your JAMF release | Enable FileVault; escrow personal recovery key to JAMF; require enablement at next logout/restart; limit deferment to approved window | Startup disk remains encrypted at rest, protecting data if device is lost or stolen | Encryption started but not finished, user has not completed logout/restart prompt, key escrow not yet reported, inventory timestamp stale | Keep enforcement enabled and add operational rule: require one reboot or logout and one recon cycle before incident escalation; track escrow status separately from encryption status | Computers > Configuration Profiles > profile > Security and Privacy (or Disk Encryption workflow). Drift risk: Medium-High. Verify exact FileVault payload names and escrow options in your JAMF version. |
| 2. Gatekeeper must be enabled (identified developers only) | Restrictions payload or Security and Privacy controls, depending on JAMF release | Allow apps from App Store and identified developers only | Unsigned and untrusted apps are blocked while signed developer apps remain allowed | Local admin override for troubleshooting, stale inventory, app quarantine behavior interpreted as control failure | Keep strict Gatekeeper state and document temporary exception process with expiry and approval; force inventory update after exception removal | Computers > Configuration Profiles > profile > Restrictions or Security and Privacy section. Drift risk: High. Verify exact Gatekeeper control label and value options in your JAMF version. |
| 3. Minimum macOS version: current stable minus one point release | Not a single profile payload. Enforce with Smart Group criteria plus update policy and reporting | Smart Group includes only devices at stable-1 point release or newer; non-compliant group receives remediation update policy | Outdated OS versions are continuously identified and remediated | New Apple release timing variance by hardware model, pending reboot after update, stale software inventory after install | Use staged rings for 25 devices: pilot 5, wave 10, wave 10; evaluate compliance after reboot-required updates before marking incident | Computers > Smart Computer Groups (criteria: Operating System Version), then scope update policy under Computers > Policies or managed software update controls. Drift risk: Medium-High. Verify where your JAMF version exposes update scheduling and version criteria fields. |
| 4. Firewall must be enabled | Security and Privacy payload (Firewall) | Enable application firewall; enable stealth mode unless business app dependency requires adjustment | Reduces unsolicited inbound connection exposure on endpoints | Third-party endpoint security controls overriding firewall state, profile conflicts, check-in lag after change | Keep firewall required; review and remove duplicate or conflicting payloads; validate one test device per network segment used by design team | Computers > Configuration Profiles > profile > Security and Privacy > Firewall. Drift risk: Medium. Verify option names such as stealth mode and incoming rule handling in your JAMF version. |
| 5. Login password required after sleep or screen saver | Security and Privacy payload (General), or Login Window/Restrictions controls based on OS and JAMF version | Require password immediately after sleep or screen saver begins; enforce short idle lock timer per policy | Prevents unattended unlocked session access | Device sampled while still in grace delay, overlapping profiles with conflicting idle settings, user recently changed local lock settings before profile re-apply | Set a single authoritative profile for lock behavior; avoid duplicate controls; monitor profile install status before treating as non-compliant | Computers > Configuration Profiles > profile > Security and Privacy and possibly Login Window or Restrictions. Drift risk: High. Verify exact payload location for sleep and screen saver password controls in your JAMF version. |
| 6. Automatic security updates enabled | Software Update payload or managed update settings area, depending on JAMF release | Enable automatic security updates and automatic background update checks/download/install behavior according to baseline | Devices receive security fixes quickly with minimal user intervention | Device offline, power constraints, update deferral windows, restart pending after update install | Keep auto security updates enabled and pair with restart communications; measure compliant only after post-update inventory refresh | Computers > Configuration Profiles > Software Update payload, or Computers > Software Updates/update management pages. Drift risk: High. Verify update payload key names and available controls in your JAMF version. |

## Enforcement Timing (JAMF equivalent to compliance grace behavior)

JAMF does not always expose a single compliance grace switch identical to Intune compliance policy behavior. Use staged enforcement timing through scope and Smart Groups.

| Enforcement area | Control | Value | Effect | False-positive risk | Recommendation | UI path and drift flag |
|---|---|---|---|---|---|---|
| Baseline rollout timing | Pilot-to-broad scope progression | 3 business days pilot, then phased broad rollout to remaining 20 devices | Reduces blast radius while preserving baseline intent | Short pilot can miss edge cases if design tooling not represented | Keep pilot device mix representative of design apps, VPN usage, and peripherals | Computers > Configuration Profiles > Scope and Computers > Smart Computer Groups. Drift risk: Low-Medium. |
| Remediation trigger window | Non-compliant smart group reassessment | Re-evaluate after each inventory update and after reboot-required actions | Devices naturally converge without immediate false incident creation | Inventory latency may keep healthy devices in non-compliant group briefly | Require two consecutive failed inventories before opening incident for requirements 1, 3, and 6 | Computers > Smart Computer Groups and inventory schedules. Drift risk: Medium. |

## Notes for Implementation

1. Build one baseline profile for security controls and keep update orchestration separate for clearer troubleshooting.
2. Assign to a 5-device pilot first, then expand to the full 25-device fleet in two waves.
3. Record three statuses per control: configured, applied, and verified.
4. For FileVault and software updates, include reboot or logout dependency in the support runbook.
5. Maintain one time-bound break-glass exclusion Smart Group with approval logging.

## UI Validation Notes

1. Gatekeeper and sleep-password controls are common drift areas across JAMF releases and macOS generations.
2. OS version minimum is usually enforced operationally through Smart Group criteria and policy scope, not a single profile toggle.
3. Software update controls can appear under profile payloads or separate update-management areas depending on JAMF version and feature licensing.

## Correct UI Steps for FileVault (current known flow pattern)

1. Go to Computers > Configuration Profiles.
2. Select New profile for macOS.
3. Configure General payload with clear name and scoped assignment to pilot Smart Group.
4. Open Security and Privacy payload or Disk Encryption workflow in your JAMF version.
5. Enable FileVault and escrow recovery key to JAMF.
6. Set user interaction and deferment values per baseline.
7. Save and deploy, then force inventory update on pilot devices.

## If You Do Not See the Expected FileVault or Gatekeeper Control

1. Confirm the profile platform is macOS and not another Apple platform profile type.
2. Confirm you are in Configuration Profiles, not only in Policies, unless your JAMF version intentionally manages this setting elsewhere.
3. Confirm required payload is enabled inside the profile editor and not collapsed or hidden by UI filters.
4. If label mismatch persists, validate against your JAMF release notes and admin guide for your exact version.

## Post-Assignment Validation Steps (after inventory update)

### 1) Where to check status for this specific baseline

Primary path (profile-centric):
1. Open Computers > Configuration Profiles.
2. Select baseline profile.
3. Review device-level install status and failed installs.
4. Cross-check with Smart Group membership for non-compliant criteria.

Alternative path (device-centric):
1. Open Computers > Search Inventory.
2. Select a test Mac.
3. Review Profiles and security state indicators (FileVault, firewall, OS version, update state).

### 2) Meaning of configured, applied, and verified

1. Configured: Setting exists in profile definition.
2. Applied: Profile installed on target endpoint.
3. Verified: Endpoint state confirms expected behavior after required reboot or logout events.

### 3) If FileVault shows unhealthy but encryption is expected to be on: top 3 false-positive causes and fastest check

1. Cause: Encryption still in progress or user not completed required logout/restart.
Fastest check: Validate local FileVault status, then perform logout or restart and force inventory.

2. Cause: Recovery key escrow has not yet posted to JAMF.
Fastest check: Confirm escrow record timestamp and trigger new inventory submission.

3. Cause: Stale inventory record or duplicate device record after re-enrollment.
Fastest check: Verify latest check-in timestamp and confirm analyst is reviewing the active record.

## 24-Hour Safety Monitoring After Broad Assignment

1. Monitor profile install success and failure rates every 2 to 4 hours.
2. Track Smart Group counts for each control condition, especially OS version and FileVault.
3. Measure median remediation time from first detected non-compliance to verified healthy state.
4. Sample flagged endpoints to compare local truth against JAMF inventory data.
5. Pause next rollout wave if false-positive rate exceeds expected baseline for pilot results.
