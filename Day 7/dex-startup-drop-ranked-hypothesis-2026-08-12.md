# DEX Startup Performance Drop — Ranked Hypothesis Analysis
Date: 2026-08-12
Device group: Finance-Win11 (215 devices)
Incident window: 2026-08-04 onwards (score drop from 84 to 61, +23.8 sec median startup)

---

## Hypothesis 1 (Most Probable): Startup compliance-logging script adding blocking execution time at login
Why it fits the evidence:
- The config change deployed at 02:00 on 2026-08-04 explicitly added a startup script for compliance logging.
- The degradation appeared on exactly the first boot cycle after deployment and persisted identically across three days, consistent with a script that runs at every startup rather than a one-time initialisation event.
- IT-Win11 (40 devices, no config change) showed zero change in startup time across the same window, which eliminates platform-wide or OS-level causes and points directly at what was applied exclusively to Finance-Win11.
- A blocking or synchronous script in the startup phase will delay login-to-usable-desktop time by exactly the duration the script takes to complete, matching the sharp and stable ~24-second increase observed.

Fastest check to confirm or eliminate:
Review the startup script execution log on any affected Finance-Win11 device. In Event Viewer go to Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational and filter for Event ID 4016 (startup script processing started) and Event ID 5016 (startup script processing finished). Calculate the duration between the two events. If the gap is approximately 23–25 seconds, this hypothesis is confirmed.

---

## Hypothesis 2: Additional Defender scan policy triggering a scan during the login/startup phase
Why it fits the evidence:
- The config change also deployed an additional Defender scan policy to Finance-Win11, which could schedule or trigger scan activity at startup.
- Timing is precise: the degradation began on first boot after the 02:00 deployment, with no recovery across three days, consistent with a scan policy set to run at every startup.
- The clean IT-Win11 comparison group eliminates any coincidental Defender update or platform change as the cause and points to the newly applied policy specifically.
- A Defender scan running synchronously or competing for disk I/O during profile load would slow login-to-usable-desktop by a variable but sustained margin.

Fastest check to confirm or eliminate:
On an affected device open Event Viewer > Applications and Services Logs > Microsoft > Windows > Windows Defender > Operational and check for scan start events (Event ID 1000 — scan started) timestamped within the startup window. Cross-reference with Task Manager or Resource Monitor disk I/O during login. If a scan is running during every startup on Finance-Win11 devices and absent on IT-Win11 devices, this hypothesis is confirmed.

---

## Hypothesis 3: Group Policy processing delay caused by the new baseline profile itself
Why it fits the evidence:
- Adding a new security baseline configuration profile increases the number of Group Policy or Intune configuration items processed at startup, which can extend the synchronous policy-application phase before the desktop becomes usable.
- The degradation is stable rather than improving over subsequent days, which is consistent with policy processing overhead that fires on every boot rather than a transient first-application cost.
- Again the IT-Win11 group shows no change, which confirms this is scoped to the Finance-Win11 profile deployment and not a wider policy infrastructure issue.
- This hypothesis is ranked third because the change log names two specific additions (script and Defender policy) that are more directly disruptive than baseline profile processing overhead alone, making them more targeted explanations for a 24-second increase.

Fastest check to confirm or eliminate:
Run the following on an affected device to measure total GP processing time at last startup:

```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-GroupPolicy'; Id=1500,1501,1502} |
  Select-Object TimeCreated, Id, Message |
  Sort-Object TimeCreated
```

Event ID 1500 marks GP processing start, 1502 marks completion. If the gap is approximately 23–25 seconds and this was not present before 2026-08-04, GP processing overhead is the primary contributor. If the gap is short (under 5 seconds), this hypothesis is eliminated and focus returns to Hypotheses 1 and 2.

---

## Summary

| Rank | Hypothesis | Timing fit | Comparison group fit | Fastest check |
|------|-----------|------------|----------------------|---------------|
| 1 | Startup compliance-logging script blocking login | Exact — fires every boot post-deployment | Yes — script not on IT-Win11 | Event ID 4016/5016 in GroupPolicy Operational log |
| 2 | Defender scan policy running at startup | Exact — fires every boot post-deployment | Yes — policy not on IT-Win11 | Event ID 1000 in Windows Defender Operational log |
| 3 | GP/baseline profile processing overhead | Consistent — fires every boot | Yes — profile not on IT-Win11 | Event ID 1500/1502 in System log |
