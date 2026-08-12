# Intune Win32 App Failure Analysis - Adobe Acrobat Pro v23.6

Date: 2026-08-12  
Analyst context: DWP Intune endpoint incident triage  
Source: Provided Intune Management Extension log excerpt

## 1) Distinct error code(s) present

- 1603 (MSI fatal error during installation)

Notes:
- The provided lines show repeated 1603 on initial install and retry.
- "Detection result: Not detected" is a state/result, not an install error code.
- No additional numeric installer or Intune-specific error code is visible in this excerpt.

## 2) Ranked likely causes (weighted by timing clue: overnight image update to one pool only)

### 1. New base image in that pool introduced a prerequisite gap or MSI custom action failure
Why this cause fits the scope facts:
- Timing strongly matches: failures begin after an overnight image change and are isolated to one pool, which is classic image-drift behavior.
- Install runs in SYSTEM and fails quickly (~40-45 seconds) with 1603 on both initial and retry, consistent with early prerequisite/custom action checks failing before full install.

Fastest single check:
- On one affected VM from that pool, run the same command under SYSTEM with verbose logging and inspect the first "Return value 3" block:
  - msiexec /i AcrobatPro.msi /qn /norestart /L*v C:\Windows\Temp\AcrobatPro-1603.log

### 2. Adobe product conflict on the updated image (Reader/older Acrobat or shared component collision)
Why this cause fits the scope facts:
- Pool-specific overnight image updates commonly add or change preinstalled software, including Reader baselines.
- Acrobat Pro MSI commonly throws 1603 when conflicting Adobe components, mutexes, or upgrade paths are present.

Fastest single check:
- Compare one affected VM vs one unaffected pool VM for installed Adobe products (same timestamp window) and look for version/edition conflict deltas.

### 3. Detection rule points to Reader path while deploying Pro, causing repeated retries and operational noise
Why this cause fits the scope facts:
- Detection checks HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 while the app being installed is Adobe Acrobat Pro v23.6.
- This mismatch does not create 1603 directly, but it guarantees "Not detected" and repeated retries, amplifying impact and obscuring signal.

Fastest single check:
- Validate detection target on a known-good Pro device: confirm whether the configured registry key/value can ever be true for Acrobat Pro.

### 4. Content/path issue in staged Intune payload for this assignment ring (missing MST/CAB/dependency alongside MSI)
Why this cause fits the scope facts:
- Quick-fail 1603 can occur if MSI launches but cannot locate required companion files.
- If the issue aligns to one pool/ring after overnight changes, staged content or package revision drift is plausible without affecting all pools.

Fastest single check:
- From an affected device, inspect IME staging folder for this app and confirm all expected files referenced by MSI (and any transform/dependency) exist at runtime.

### 5. Pending reboot or service state introduced by image maintenance window
Why this cause fits the scope facts:
- Overnight maintenance can leave reboot-pending or transient servicing states that frequently map to generic 1603.
- Repeated hourly retries failing in the same pattern are compatible with an unresolved reboot/service lock condition.

Fastest single check:
- On an affected VM, check reboot-pending markers in registry/CBS, then perform one controlled reboot and immediate retry of the install.

## 3) Immediate triage actions (recommended execution order)

1. Run one controlled SYSTEM-context install with verbose MSI logging on one affected pool VM.
2. Compare Adobe footprint and prerequisite state between affected and unaffected pool images.
3. Validate and correct detection logic for Acrobat Pro (prefer MSI product-code detection where possible).
4. Confirm staged package completeness on an affected endpoint and re-test.

## 4) Confidence and uncertainty

- High confidence: 1603 is the repeated installer failure code in the provided excerpt.
- High confidence: timing/isolation clue (overnight image update, one pool only) should be weighted heavily toward image-specific causes.
- Moderate confidence: detection-rule mismatch is present and operationally important, but may be parallel to (not the direct source of) 1603.
- Uncertain without MSI verbose log: exact failing custom action/prerequisite remains unproven; do not commit to a single cause yet.
