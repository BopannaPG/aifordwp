# Known Error Record - Finance Shared Drives (Intune SYSTEM Context Regression)

Symptom: Finance users on affected endpoints cannot access the Finance shared drive, and drive S: is not mapped at sign-in. Users experience failed access to `\\finbridge-fs01\Finance` during the incident window.

Cause: Verified root cause is an execution-context regression: drive mapping was moved from a user logon method to an Intune PowerShell script running as SYSTEM without adapting for SYSTEM identity/session behavior and startup timing. Contributing design gap: no retry configured after first failure.

Scope: Affected population is Finance users (about 45 users) on DESKTOP-FB* devices in OU=Finance. Evidence was captured from Intune Management Extension and System logs, including DESKTOP-FB041 and change reference DESKTOP-FB022.

Workaround: Apply the incident resolution that restores drive-mapping behavior for the affected Finance scope. Service restoration was verified at 07:40:05 AM and Group Policy was confirmed healthy.

Permanent fix: Use a user-session-safe mapping execution path (or equivalent user-context mechanism) for Finance drive mapping. Add startup dependency checks and retry/backoff, and require change-gate plus pilot validation for USER-to-SYSTEM script-context migrations.

How to spot it: Intune Management Extension ScriptRunner shows `Map-FinBridgeDrives.ps1` running as SYSTEM (08:00:02), UNC inaccessible warning for `\\finbridge-fs01\Finance` (08:00:03), and error "network name cannot be found" with exit code 1 (08:00:03), followed by "No retry configured" (08:00:04). System log signals include Service Control Manager Event 7036 (Workstation service running at 08:00:05), GroupPolicy Event 1500 success (08:00:06), and Ntfs Event 98 warning for S: not assigned (08:00:07).