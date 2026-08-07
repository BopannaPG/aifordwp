# Root Cause Analysis (RCA)

## Incident Title
Print Spooler service crash loop and service logon failure

## Date/Time Window Reviewed
2024-03-15 10:01:14 to 10:03:50

## Analyst
DWP Analyst

## Scope
Analyze System log events for a Print Spooler crash loop, explain each event ID, reconstruct the sequence, identify most likely cause with evidence, and provide 5 Whys.

## Note on Request Wording
The supplied data is System log service-failure telemetry, not account lockout telemetry. This RCA identifies the most likely cause of the service crash loop and startup failure.

## Event ID Meaning (What each event records)

### Event ID 7034 (Service Control Manager)
Records that a service terminated unexpectedly.
- In this incident, Print Spooler crashes repeatedly.
- The "It has done this N time(s)" counter indicates repeated terminations over a short period.

### Event ID 7031 (Service Control Manager)
Records unexpected service termination and indicates the configured recovery action.
- In this incident, SCM schedules "Restart the service" after 60000 ms.
- Confirms crash-recovery policy is active while failures continue.

### Event ID 7023 (Service Control Manager)
Records a service termination with a specific service error message.
- In this incident, Print Spooler terminated with: "The specified module could not be found."
- Strong indicator of missing/corrupt dependency module or referenced component.

### Event ID 7038 (Service Control Manager)
Records a service logon failure for the configured service account.
- In this incident, Print Spooler failed to log on as NT AUTHORITY\SYSTEM due to missing requested logon type rights.
- Indicates a security rights/policy misconfiguration affecting service startup context.

## Timeline Reconstruction (Plain English)
1. 10:01:14: Print Spooler crashes unexpectedly (first occurrence, 7034).
2. 10:01:45: Print Spooler crashes again (second occurrence, 7034).
3. 10:02:16: Print Spooler crashes a third time (7034).
4. 10:02:47: Print Spooler crashes a fourth time; SCM confirms it will keep trying recovery by restarting after 60 seconds (7031).
5. 10:03:49: Failure mode is now explicit: service terminated because a required module could not be found (7023).
6. 10:03:50: Additional startup failure occurs because service logon as Local System is denied requested logon type (7038).

## Most Likely Cause (with Evidence)
Most likely primary cause: service configuration/dependency state corruption or tampering, with a missing module causing repeated spooler crashes.

### Evidence for primary cause
1. Repeated 7034/7031 sequence shows true crash loop, not one-time interruption.
2. 7023 provides a concrete technical failure reason: "The specified module could not be found."
3. Timing suggests repeated restart attempts eventually surface explicit dependency/module failure details.

### Secondary/Contributing cause
A concurrent policy/rights misconfiguration likely worsened recovery by blocking service logon context.

### Evidence for contributing cause
1. 7038 states NT AUTHORITY\SYSTEM cannot obtain required logon type for Print Spooler.
2. This is abnormal for default spooler configuration and points to changed local/domain policy or service account rights.

## Root Cause Statement
Primary root cause: Print Spooler entered a restart loop because a required module/dependency was missing or inaccessible (Event 7023), while a concurrent service logon rights issue (Event 7038) likely compounded restart failures and recovery instability.

## 5 Whys Analysis
1. Why was printing unavailable?
- Print Spooler was repeatedly terminating and not staying running.
2. Why did the service keep terminating?
- A required module could not be found during service operation/startup.
3. Why was the module not found?
- Service dependency path or referenced component became missing/corrupted/unregistered.
4. Why did recovery not stabilize service quickly?
- SCM restarted the service, but a service logon rights issue also appeared, preventing normal startup context.
5. Why did both technical conditions exist?
- Most likely unmanaged configuration drift (policy changes and/or component state change) affecting spooler runtime and service rights.

## Corrective Actions (Immediate)
1. Verify spooler binary and dependency integrity:
- Confirm spoolsv.exe path and file presence.
- Check printer driver/print processor modules under spool directories.
2. Remove or isolate recently added/updated print drivers and third-party print processors.
3. Restore default Print Spooler service account/startup configuration.
4. Validate Local Security Policy or GPO rights for Local System service logon behavior.
5. Restart service and confirm sustained uptime beyond recovery interval.

## Preventive Actions
1. Enforce print driver governance (approved/signed drivers only).
2. Monitor for SCM 7034/7031 burst patterns and auto-alert on crash loops.
3. Baseline and monitor service rights assignments for critical built-in accounts.
4. Use change control for GPO/security template updates impacting service rights.

## Validation Checklist
1. No new 7034/7031 events for Print Spooler after remediation window.
2. No recurrence of 7023 module-not-found for spooler.
3. No recurrence of 7038 logon-rights failure for Print Spooler.
4. Print test job succeeds and queue processing is stable.

## Incident Conclusion
Incident behavior is consistent with a Print Spooler crash loop caused by missing module/dependency, with additional service logon-rights misconfiguration contributing to failed recovery attempts. Service should stabilize after dependency repair and rights correction.
