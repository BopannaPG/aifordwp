# AVD Black Screen Incident Analysis and Hypothesis

## Context
- Symptom: blank screen post login, clears after ~30 seconds for some users and persists for others.
- Impact: about 40% of users in `POOL-FIN-01`.
- Control group: `POOL-FIN-02` is completely unaffected.
- Timing: issue began around 07:00.
- Change clue: overnight image update to `POOL-FIN-01` at 02:00. `POOL-FIN-02` was not updated.

## Key Inference from Timing and Isolation
The strongest signal is that only the updated pool is affected and the non-updated pool is unaffected. This strongly favors image-linked causes over environment-wide causes.

## Re-ranked Most Likely Causes (Most Probable First)

### 1. Golden image regression in POOL-FIN-01
Why this fits:
- The symptom appears after the 02:00 update.
- Impact is isolated to the updated pool.
- The untouched pool has zero impact, creating a strong A/B contrast.
Single fastest check:
- Deploy one test host in `POOL-FIN-01` from the last known-good image and validate affected users against it.

### 2. FSLogix profile/container attach delay or failure introduced by new image
Why this fits:
- Black screen after login with delayed recovery is consistent with slow profile attach or shell start waiting on profile.
- Pool-specific timing still aligns with image-side change.
Single fastest check:
- Review FSLogix operational logs for affected users on an impacted `POOL-FIN-01` host and compare attach time/failure events.

### 3. AVD agent or bootloader version drift on updated hosts
Why this fits:
- Image refresh can alter agent stack/runtime dependencies.
- Post-login black screen can occur when brokering succeeds but session shell initialization is delayed.
Single fastest check:
- Compare AVD agent and bootloader versions and host health between one affected host in `POOL-FIN-01` and one healthy host in `POOL-FIN-02`.

### 4. Logon policy or script processing behavior triggered by updated image context
Why this fits:
- Partial impact (~40%) can map to user-targeted policy/script combinations.
- Could still be update-linked if image change altered policy processing path.
Single fastest check:
- Compare RSOP and user logon processing duration for one affected and one unaffected user on `POOL-FIN-01`.

### 5. Graphics/render path issue introduced in updated image
Why this fits:
- Black screen can come from graphics initialization delays/failures.
- Still compatible with image change if display driver/settings changed.
Single fastest check:
- Force software rendering for a controlled test on an affected `POOL-FIN-01` host and retest affected users.

## Current Hypothesis
Primary working hypothesis: a regression introduced by the 02:00 image update on `POOL-FIN-01` is causing delayed or failed post-login session initialization, with FSLogix/session stack paths as likely sub-components.

## Confidence Statement
- High confidence that root cause is pool-update-linked due to timing and unaffected control pool.
- Medium confidence on exact sub-component until targeted checks are completed.
- Do not commit to a single underlying subsystem until validation checks are run.

## Event Details Reviewed

### Affected Session Host: SHFIN-01-A
- `07:02:10` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 21`
	- Session logon succeeded for `FINBRIDGE\mlopez`, Session ID `3`, Source `10.10.1.55`.
- `07:02:14` `Microsoft-Windows-Kernel-General` `Event 1`
	- System boot time recorded as `2024-03-15 02:03:11`, consistent with post-image-update restart.
- `07:02:16` `Application Error` `Event 1000`
	- `dwm.exe` crashed.
	- Faulting module: `igdumd64.dll` version `31.0.101.4146`.
	- Exception code: `0xc0000005`.
- `07:02:17` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 40`
	- Session disconnected for `FINBRIDGE\mlopez`, Session ID `3`.
- `07:02:18` `Desktop Window Manager` `Event 9009`
	- DWM exited with code `0x40010004`.
- `07:02:44` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 21`
	- Reconnect logon succeeded for `FINBRIDGE\mlopez`, Session ID `3`.
- `07:02:46` `Application Error` `Event 1000`
	- Second `dwm.exe` crash with same faulting module and same exception family.
- `07:02:47` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 40`
	- Session disconnected again.
- `07:03:01` `Desktop Window Manager` `Event 9009`
	- DWM exited again.
- `07:03:10` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 21`
	- Second reconnect succeeded for `FINBRIDGE\mlopez`, Session ID `4`.
- `07:08:22` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 21`
	- Session logon succeeded for `FINBRIDGE\akapoor`, Session ID `5`, Source `10.10.1.61`.
- `07:08:24` `Application Error` `Event 1000`
	- Third observed `dwm.exe` crash in `igdumd64.dll`, now affecting a different user.

### Comparison Host: SHFIN-02-A (POOL-FIN-02 Unaffected)
- `07:01:44` `Microsoft-Windows-TerminalServices-LocalSessionManager` `Event 21`
	- Session logon succeeded for `FINBRIDGE\bwalker`, Session ID `2`.
- `07:01:46` `Desktop Window Manager` `Event 9011`
	- DWM started successfully.
- No `Application Error` events were observed in the same review window.

## Reviewed Hypotheses Against Event Evidence

### 1. Golden image regression in POOL-FIN-01
Judgement: `Support`

Why:
- The affected host rebooted shortly after the overnight image update window.
- Repeated failures appear only on the updated pool host.
- The unaffected pool host shows normal DWM startup and no matching crashes.

Determining events:
- `07:02:14` `Kernel-General Event 1`
- `07:02:16` `Application Error Event 1000`
- `07:02:46` `Application Error Event 1000`
- `07:08:24` `Application Error Event 1000`
- `07:01:46` on comparison host `Desktop Window Manager Event 9011`

### 2. FSLogix profile/container attach delay or failure introduced by new image
Judgement: `Contradict`

Why:
- The supplied evidence shows successful session logon followed by immediate `dwm.exe` crash and disconnect.
- No FSLogix or profile attach failures are present in the supplied logs.

Determining events:
- `07:02:10` `TerminalServices-LocalSessionManager Event 21`
- `07:02:16` `Application Error Event 1000`
- `07:02:17` `TerminalServices-LocalSessionManager Event 40`

### 3. AVD agent or bootloader version drift on updated hosts
Judgement: `Neutral to slight contradict`

Why:
- Session logons are succeeding, which weakens a broker/agent establishment failure theory.
- The visible fault occurs after logon in the desktop rendering process.

Determining events:
- `07:02:10` `TerminalServices-LocalSessionManager Event 21`
- `07:02:44` `TerminalServices-LocalSessionManager Event 21`
- `07:03:10` `TerminalServices-LocalSessionManager Event 21`
- `07:08:22` `TerminalServices-LocalSessionManager Event 21`
- `07:02:16` `Application Error Event 1000`

### 4. Logon policy or script processing behavior triggered by updated image context
Judgement: `Contradict`

Why:
- The logs show a concrete graphics-path crash rather than a long-running policy or script delay.
- DWM exits immediately after successful sign-in, which is more direct evidence than a policy-processing theory.

Determining events:
- `07:02:10` `TerminalServices-LocalSessionManager Event 21`
- `07:02:16` `Application Error Event 1000`
- `07:02:18` `Desktop Window Manager Event 9009`
- `07:03:01` `Desktop Window Manager Event 9009`

### 5. Graphics/render path issue introduced in updated image
Judgement: `Support`

Why:
- `dwm.exe` is crashing in `igdumd64.dll`, the Intel graphics user-mode driver.
- DWM exits immediately after the crash.
- The same failure repeats across reconnects and across different users on the affected host.
- The unaffected pool host shows successful DWM startup instead.

Determining events:
- `07:02:16` `Application Error Event 1000`
- `07:02:18` `Desktop Window Manager Event 9009`
- `07:02:46` `Application Error Event 1000`
- `07:03:01` `Desktop Window Manager Event 9009`
- `07:08:24` `Application Error Event 1000`
- `07:01:46` on comparison host `Desktop Window Manager Event 9011`

## Surviving Hypothesis After Evidence Review
The hypothesis that survives the evidence review is:

`Graphics/render path issue introduced in the updated image, specifically an Intel graphics user-mode driver regression involving igdumd64.dll crashing dwm.exe after login.`

Why this survives:
- The affected host shows repeated `dwm.exe` crashes in `igdumd64.dll` with exception code `0xc0000005`.
- DWM exits immediately after each crash.
- The comparison host in the unaffected pool shows normal DWM startup and no matching failures.

## Detailed Resolution Steps

### 1. Contain user impact
- Stop directing new sessions to `POOL-FIN-01` if operationally possible.
- Drain affected hosts and prefer `POOL-FIN-02` for new user sessions.
- Notify operations that `POOL-FIN-01` is under image remediation.

### 2. Confirm the graphics driver delta
- On one affected `POOL-FIN-01` host, capture the installed Intel graphics driver version and the file version for `igdumd64.dll`.
- Compare those values to a healthy `POOL-FIN-02` host.
- Confirm whether the updated pool introduced or changed the driver package.

### 3. Use the fastest safe recovery path
- Build one test session host for `POOL-FIN-01` from the last known-good pre-update image.
- Validate with one previously affected user.
- If black-screen symptoms disappear and no DWM crashes recur, use image rollback as the production fix.

### 4. Apply an interim workaround if rollback is delayed
- On a test host, force software rendering or disable the accelerated graphics path used by sessions.
- Retest with an affected user.
- If stable, use this only as a temporary mitigation while the image is corrected.

### 5. Correct the golden image
- Open the `POOL-FIN-01` golden image.
- Remove, roll back, or replace the Intel graphics driver associated with `igdumd64.dll` version `31.0.101.4146` if it is the changed component.
- If the driver arrived via update tooling, block that driver version from automatic reapplication until validated.

### 6. Validate the fix on a remediated host
- Test repeated user logons on the fixed host.
- Confirm no new `Application Error Event 1000` for `dwm.exe`.
- Confirm no new `Desktop Window Manager Event 9009`.
- Confirm users reach the desktop without prolonged black screen.

### 7. Roll out the corrected image to the pool
- Publish the corrected image only after successful host-level testing.
- Rebuild or redeploy remaining `POOL-FIN-01` hosts from the corrected image.
- Keep rollback path available until the full pool is stable.

### 8. Add a release gate for future image updates
- Add a post-image validation step before pool-wide rollout.
- Require at least one live logon test and DWM/Application log review on a canary host.
- Do not promote the image if DWM or graphics-driver crashes are present.

## Success Criteria
- No recurring `Application Error Event 1000` for `dwm.exe` on remediated `POOL-FIN-01` hosts.
- No recurring `Desktop Window Manager Event 9009` after user sign-in.
- User sessions land successfully without black screen or forced reconnect.
- `POOL-FIN-01` behavior matches healthy `POOL-FIN-02` behavior.
