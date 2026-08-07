# Root Cause Analysis (RCA)

## Incident Title
Repeated Outlook application crash on Windows 11 endpoint

## Date/Time Window Reviewed
2024-03-15 09:13 to 09:18

## Analyst
DWP Analyst

## Scope
Analyze Application log events related to repeated Outlook crashes, explain event IDs, reconstruct sequence, identify most likely cause with evidence, and provide 5 Whys.

## Note on Request Wording
The provided logs are Application crash events, not account lockout events. No Security lockout events (such as 4740) are present in this dataset. This RCA therefore identifies the most likely cause of the crash.

## Event ID Meaning (What each event records)

### Event ID 1000 (Source: Application Error)
Records that an application crashed and captures fault signature details.
- Includes:
  - Faulting application and version
  - Faulting module and version
  - Exception code
  - Fault offset
  - Process ID and report ID
- In this incident:
  - Application: OUTLOOK.EXE 16.0.17126.20132
  - Module: KERNELBASE.dll 10.0.22621.3155
  - Exception code: 0xc0000005

### Event ID 1001 (Source: Windows Error Reporting)
Records that Windows Error Reporting processed a crash report and assigned a fault bucket/event classification.
- In this incident:
  - Event Name: APPCRASH
  - Fault bucket present, Cab Id 0

### Event ID 1026 (Source: .NET Runtime)
Records an unhandled .NET runtime exception that terminated the process.
- In this incident:
  - Process terminated due to unhandled exception
  - Exception type: System.AccessViolationException

## Timeline Reconstruction (Plain English)
1. 09:13:44: Outlook process starts.
2. 09:14:22: Outlook crashes (Event 1000) with exception 0xc0000005 in KERNELBASE.dll.
3. 09:17:45: Outlook crashes again with the same signature (same app version, module, exception code, and fault offset), indicating repeatable failure pattern.
4. 09:18:01: Windows Error Reporting logs APPCRASH event (1001), confirming crash was captured for reporting.
5. 09:18:05: .NET Runtime logs unhandled System.AccessViolationException (1026), consistent with memory access violation behavior.

## Most Likely Cause
Most likely cause: repeatable access violation in Outlook runtime path, commonly triggered by unstable add-in interaction, corrupted Outlook profile/data interaction, or Office binary/state corruption. The crash is surfaced through KERNELBASE.dll, which is frequently the faulting module boundary rather than the true business-logic origin.

## Evidence Supporting Most Likely Cause
1. Two Event 1000 crashes within minutes with identical crash signature:
- Same application version
- Same faulting module version
- Same exception code 0xc0000005
- Same fault offset 0x000000000003a4b2
2. Event 1026 reports unhandled System.AccessViolationException, aligning with 0xc0000005 memory access violation class.
3. Event 1001 APPCRASH confirms OS-level crash classification and reporting pipeline.

## Confidence and Uncertainty
- High confidence that immediate failure mode is access violation.
- Moderate confidence on exact underlying trigger without add-in list, dump analysis, and Office diagnostics.
- Must verify exact fault bucket mapping and known-issue correlation against Microsoft documentation and symbolized dump analysis.

## 5 Whys Analysis
1. Why did the user experience Outlook failure?
- Outlook process terminated unexpectedly.
2. Why did Outlook terminate unexpectedly?
- It encountered an unhandled exception (System.AccessViolationException / 0xc0000005).
3. Why did an access violation occur?
- Outlook attempted invalid memory access in a repeatable code path (same fault offset).
4. Why was the same code path repeatedly hit?
- Startup or post-start workflow likely loaded the same component/state each launch (for example add-in load path, profile initialization, mailbox/data access path).
5. Why was the issue not self-recovered?
- The exception was unhandled and caused hard process termination before graceful recovery.

## Root Cause Statement
Primary root cause: reproducible Outlook process access-violation crash (0xc0000005) on the same runtime path, evidenced by repeated Event 1000 signatures and corroborated by Event 1026 unhandled AccessViolationException.

## Contributing Factors
1. Potential add-in instability in Outlook load path.
2. Potential profile or data-store corruption impacting startup operations.
3. Potential Office client corruption or mismatch state.

## Recommended Verification Checks (Next Technical Steps)
1. Launch Outlook in safe mode and verify stability (isolates add-ins).
2. Disable non-Microsoft add-ins and re-test normal launch.
3. Run Office Quick Repair then Online Repair if required.
4. Create a new Outlook profile and test with same mailbox.
5. Collect and analyze WER dump for OUTLOOK.EXE and correlate fault bucket with Microsoft known issues.
6. Validate current Office build channel and compare against known bad build advisories.

## Incident Conclusion
The incident is a repeated Outlook APPCRASH, not an account lockout. Evidence indicates a deterministic access violation path in Outlook execution. Additional targeted diagnostics are required to isolate whether the trigger is add-in, profile/data, or Office binary state.
