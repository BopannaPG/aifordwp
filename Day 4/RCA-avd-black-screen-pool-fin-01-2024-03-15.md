# Root Cause Analysis (RCA)

## Incident Title
AVD black screen after login on POOL-FIN-01 following overnight image update

## Incident Date
2024-03-15

## Analyst
DWP Analyst

## Summary
Beginning around 07:00, users logging in to AVD session hosts in `POOL-FIN-01` experienced a blank or black screen immediately after login. For some users, the session recovered after about 30 seconds. For others, the session remained unusable or disconnected. Approximately 40% of users in `POOL-FIN-01` were affected. `POOL-FIN-02` was fully unaffected.

The incident correlated directly with an overnight image update applied to `POOL-FIN-01` at 02:00. Event log evidence from an affected session host showed repeated `dwm.exe` crashes in Intel graphics module `igdumd64.dll`, followed by Desktop Window Manager exits and session disconnects. The issue was resolved by applying the recommended graphics/image remediation. Service was confirmed restored at `10:00`, with users successfully logging in to `POOL-FIN-01` and no further issues reported.

## Scope Facts
- Symptom: blank screen post login.
- User impact: clears after about 30 seconds for some users; persists for others.
- Affected population: about 40% of users on `POOL-FIN-01`.
- Control comparison: `POOL-FIN-02` completely unaffected.
- Start time: approximately `07:00`.
- Known change: overnight image update to `POOL-FIN-01` at `02:00`.
- No corresponding image update was applied to `POOL-FIN-02`.

## Root Cause Statement
Primary root cause: an image-linked graphics/render-path regression on `POOL-FIN-01` caused `dwm.exe` to crash in Intel graphics user-mode driver `igdumd64.dll` after user login, producing black-screen symptoms and session instability.

## Detailed Supporting Evidence

### Pool-level evidence
1. Only `POOL-FIN-01` was updated overnight.
2. Only `POOL-FIN-01` showed black-screen symptoms.
3. `POOL-FIN-02`, which was not updated, remained unaffected.

### Affected host evidence: SHFIN-01-A
1. `07:02:10` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 21`
- Session logon succeeded for `FINBRIDGE\mlopez`, Session ID `3`, Source `10.10.1.55`.

2. `07:02:14` `Microsoft-Windows-Kernel-General` `Event 1`
- System boot time was `2024-03-15 02:03:11`.
- This is consistent with a host restart following the overnight image update.

3. `07:02:16` `Application Error` `Event 1000`
- Faulting application: `dwm.exe`
- Faulting module: `igdumd64.dll`
- Module version: `31.0.101.4146`
- Exception code: `0xc0000005`

4. `07:02:17` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 40`
- Session disconnected for `FINBRIDGE\mlopez`.

5. `07:02:18` `Desktop Window Manager` `Event 9009`
- DWM exited with code `0x40010004`.

6. `07:02:44` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 21`
- Reconnect logon succeeded for `FINBRIDGE\mlopez`.

7. `07:02:46` `Application Error` `Event 1000`
- Second `dwm.exe` crash with the same failure signature.

8. `07:02:47` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 40`
- Session disconnected again.

9. `07:03:01` `Desktop Window Manager` `Event 9009`
- DWM exited again.

10. `07:03:10` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 21`
- Second reconnect succeeded, new session ID `4`.

11. `07:08:22` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 21`
- Session logon succeeded for `FINBRIDGE\akapoor`, Session ID `5`, Source `10.10.1.61`.

12. `07:08:24` `Application Error` `Event 1000`
- Third observed `dwm.exe` crash in `igdumd64.dll`, now affecting a second user.

### Unaffected host evidence: SHFIN-02-A (POOL-FIN-02)
1. `07:01:44` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 21`
- Session logon succeeded for `FINBRIDGE\bwalker`, Session ID `2`.

2. `07:01:46` `Desktop Window Manager` `Event 9011`
- Desktop Window Manager started successfully.

3. No `Application Error Event 1000` entries were observed in the same review window.

## Timeline
1. `02:00`
- Overnight image update applied to `POOL-FIN-01`.

2. `02:03:11`
- `SHFIN-01-A` boot time recorded after image update.

3. `~07:00`
- User-facing incident begins; black screen after login starts being observed on `POOL-FIN-01`.

4. `07:02:10`
- Affected user `FINBRIDGE\mlopez` logs in successfully to `SHFIN-01-A`.

5. `07:02:16`
- `dwm.exe` crashes in `igdumd64.dll`.

6. `07:02:17` to `07:03:01`
- Session disconnects and DWM exits repeat across reconnect attempts.

7. `07:08:22` to `07:08:24`
- A second user `FINBRIDGE\akapoor` experiences the same crash pattern on the same affected host.

8. During investigation
- Competing hypotheses reviewed against evidence.
- Non-graphics hypotheses weakened or contradicted by successful session logon followed by immediate DWM/graphics faults.

9. Remediation window
- Recommended graphics/image resolution applied to affected pool.

10. `10:00`
- Issue confirmed resolved.
- Users successfully logging in to hosts in `POOL-FIN-01`.
- No issues reported after remediation.

## Hypothesis Review Summary

### 1. Golden image regression in POOL-FIN-01
Status: Supported
- Supported by pool-specific timing and control-group comparison.
- Strongly linked to updated image state.

### 2. FSLogix profile/container attach delay or failure
Status: Contradicted
- Session logon succeeds before failure.
- Supplied evidence shows crash in graphics path, not profile attach failure.

### 3. AVD agent or bootloader version drift
Status: Neutral to weakly contradicted
- AVD sessions are created successfully.
- Failure occurs after login in desktop rendering.

### 4. Logon policy or script processing issue
Status: Contradicted
- Event trail shows direct `dwm.exe` crash and DWM exit rather than long policy or script delay.

### 5. Graphics/render-path issue introduced in updated image
Status: Supported and surviving hypothesis
- Repeated `dwm.exe` crashes in `igdumd64.dll` across multiple users on the affected host.
- Unaffected pool shows DWM startup success and no equivalent errors.

## 5 Whys Analysis
1. Why did users see a black screen after login?
- Because the desktop composition process failed shortly after session logon.

2. Why did the desktop composition process fail?
- Because `dwm.exe` crashed repeatedly.

3. Why did `dwm.exe` crash repeatedly?
- Because it encountered an access violation in Intel graphics module `igdumd64.dll`.

4. Why was that graphics module in a failing state on affected hosts?
- Because the overnight image update introduced a graphics/render-path regression on `POOL-FIN-01`.

5. Why did the regression reach production users?
- Because the updated image was promoted without a canary validation step that exercised real user logon and checked DWM/Application event logs before full pool use.

## Resolution Applied
The recommended graphics/image remediation was applied to `POOL-FIN-01`. Based on the validated hypothesis and prior resolution plan, the effective remediation path was:
1. Isolate impact to the updated pool.
2. Correct the image-linked graphics component or roll back to the known-good image state.
3. Restore stable DWM startup and user session rendering on remediated hosts.

## Resolution Outcome
- Issue resolved at `10:00`.
- Users verified as logging in successfully to hosts in `POOL-FIN-01`.
- No further black-screen issues reported after remediation.

## Preventive Actions
1. Add a canary validation step for all AVD image updates.
- Deploy the new image to one non-production or limited-production host first.
- Perform at least one full AVD user logon test.
- Review `Application` and `Desktop Window Manager` events before broad rollout.

2. Add graphics-driver delta checks to image change control.
- Record pre/post image versions for display drivers and key rendering components.
- Flag any graphics driver version change for explicit validation.

3. Require pool-to-pool comparison before incident escalation closes.
- Compare updated and non-updated pools for event signatures, installed drivers, and session behavior.

4. Add monitoring for DWM crash patterns on AVD hosts.
- Alert on repeated `Application Error Event 1000` involving `dwm.exe`.
- Alert on repeated `Desktop Window Manager Event 9009` after session logon.

5. Document rollback criteria for image releases.
- Define exact rollback triggers such as repeated post-logon black screen, repeated DWM crash, or multi-user impact on a single updated pool.

6. Include graphics stack testing in UAT for pooled hosts.
- Validate software rendering and accelerated rendering paths where applicable.
- Test reconnect behavior and multi-user session stability.

## Verification Criteria
1. No recurring `Application Error Event 1000` for `dwm.exe` on remediated `POOL-FIN-01` hosts.
2. No recurring `Desktop Window Manager Event 9009` after user sign-in.
3. Users can log in repeatedly to `POOL-FIN-01` without black screen or disconnect.
4. `POOL-FIN-01` behavior matches healthy `POOL-FIN-02` behavior.

## Conclusion
The incident was caused by a graphics/render-path regression introduced with the overnight image update to `POOL-FIN-01`. The evidence shows repeated `dwm.exe` failures in Intel graphics module `igdumd64.dll` immediately after successful user session logon. After remediation of the image-linked graphics issue, service was restored and confirmed stable by `10:00`.