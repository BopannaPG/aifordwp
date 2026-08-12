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

## 2) Ranked remediation plan (most likely fix first)

### 1. Fix packaging/context mismatch and command-line prerequisites
Why this is first:
- 1603 is most commonly caused by install context issues, bad command line, missing source files, or prerequisite/custom action failure.

Specific checks:
- Confirm Intune install command in app configuration exactly matches tested command line.
- Validate that AcrobatPro.msi exists in the extracted content root used by Intune IME at install time.
- Confirm SYSTEM-context install succeeds locally using the same command line (PsExec SYSTEM test).
- Add full MSI logging to command for one test deployment:
  - msiexec /i AcrobatPro.msi /qn /norestart /L*v C:\Windows\Temp\AcrobatPro-Install.log
- Review MSI verbose log for first "Return value 3" block and failing custom action.

Status against Microsoft docs:
- [VERIFY AGAINST MICROSOFT DOCS] MSI 1603 troubleshooting patterns and verbose log interpretation.
- [VERIFY AGAINST MICROSOFT DOCS] Intune Win32 app command-line and content staging behavior.

### 2. Correct detection rule targeting (possible product mismatch)
Why this is second:
- Detection is currently checking HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 while the app is "Adobe Acrobat Pro". Reader vs Pro key mismatch can cause endless retry behavior even if install partially succeeds.

Specific checks:
- Confirm correct product edition key/path for Acrobat Pro (not Reader).
- Prefer MSI product code detection where possible for reliability.
- If using registry detection, verify:
  - Correct hive (including WOW6432Node considerations)
  - Correct key for installed edition/version
  - Correct value name/type/expected data
- Re-run detection script/check manually on a known-good machine.

Status against Microsoft docs:
- [VERIFY AGAINST MICROSOFT DOCS] Recommended Win32 app detection rule design (MSI/product-code vs registry).

### 3. Remove conflicting pre-existing Adobe components and pending reboot state
Why this is third:
- 1603 frequently occurs when older Adobe products/components, running Adobe processes, or pending reboot state blocks installation.

Specific checks:
- Check for installed Adobe Reader/Acrobat versions and uninstall conflicts.
- Check for running Adobe-related processes/services during install window.
- Verify pending reboot indicators:
  - HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired
  - Component Based Servicing pending reboot markers
- Reboot device, then force policy sync and retry deployment.

Status against Microsoft docs:
- [VERIFY AGAINST MICROSOFT DOCS] Known 1603 causes: conflicting versions, in-use files, pending reboot.

### 4. Validate assignment filters, requirement rules, and architecture targeting
Why this is fourth:
- Incorrect requirements can result in inappropriate targeting and repeated failed retries on unsupported device states.

Specific checks:
- Confirm requirement rules match endpoint architecture/OS version.
- Verify install behavior is set for system install as intended.
- Confirm no conflicting supersedence or dependency app states.
- Validate assignment scope and exclusion groups.

Status against Microsoft docs:
- [VERIFY AGAINST MICROSOFT DOCS] Intune Win32 requirement/dependency/supersedence evaluation order.

### 5. Repackage app content if hash/corruption/source path issues are suspected
Why this is fifth:
- If content extraction is incomplete/corrupted, MSI can fail with generic 1603.

Specific checks:
- Rebuild .intunewin package from clean source media.
- Ensure MSI and transform/files are in expected relative paths.
- Redeploy as a new app revision and test on pilot device.

Status against Microsoft docs:
- [VERIFY AGAINST MICROSOFT DOCS] IntuneWin packaging best practices and content validation.

## 3) Immediate triage actions (recommended execution order)

1. Run one controlled install with full MSI verbose logging under SYSTEM context.
2. Correct detection rule to confirmed Acrobat Pro detection target.
3. Remove conflicting Adobe versions and clear reboot-pending state.
4. Re-test deployment on one pilot endpoint, then expand.

## 4) Confidence and uncertainty

- High confidence: 1603 is the distinct repeated install code in the provided excerpt.
- Moderate confidence: detection rule likely mismatched (Reader key for Pro package), but this must be confirmed on a successfully installed reference endpoint.
- Uncertain without additional logs: exact failing MSI custom action or prerequisite; MSI verbose log is required for definitive root cause.
