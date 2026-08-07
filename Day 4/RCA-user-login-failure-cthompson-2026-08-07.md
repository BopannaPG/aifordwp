# Root Cause Analysis (RCA)

## Incident Title
User `cthompson` unable to log in until account remediation on 2024-03-15

## Incident Date
2024-03-15

## Analyst
DWP Analyst

## Summary
At approximately `08:40`, user `FINBRIDGE\cthompson` began failing to log in from `DESKTOP-FB022`. Security event evidence showed repeated wrong-password authentication failures, followed by account lockout at `08:44:56`. Additional Kerberos pre-authentication failures were later recorded from `10.10.8.112`, indicating the bad credentials were still being submitted from another source during the incident window.

The suggested remediation was applied. At `09:08:14`, the account was enabled by `FINBRIDGE\helpdesk-admin`, and at `09:09:01` `cthompson` successfully logged on interactively to `DESKTOP-FB022`. The issue was therefore resolved by restoring account access and eliminating the blocking account state.

## Scope Facts
- Symptom: user `cthompson` could not log in.
- Impact: single-user incident.
- Start time: about `08:40`.
- Change: none reported at the time of the incident.

## Root Cause Statement
Primary root cause: `cthompson` was unable to log in because repeated wrong-password attempts triggered an account lockout, blocking interactive sign-in until the account was re-enabled and access was restored.

## Supporting Evidence

### Authentication failure chain on `DESKTOP-FB022`
1. `08:44:01` - `Security Event 4776`
- The domain controller attempted to validate credentials.
- Account: `FINBRIDGE\cthompson`
- Error code: `0xC000006A (wrong password)`
- Source workstation: `DESKTOP-FB022`

2. `08:44:03` - `Security Event 4625`
- Interactive logon failed.
- Account: `FINBRIDGE\cthompson`
- Failure reason: `Unknown user name or bad password`
- Logon type: `2 (Interactive)`

3. `08:44:28` - `Security Event 4625`
- Repeated interactive failure for the same account and source workstation.

4. `08:44:55` - `Security Event 4625`
- Repeated interactive failure immediately before lockout.

5. `08:44:56` - `Security Event 4740`
- A user account was locked out.
- Account: `FINBRIDGE\cthompson`
- Caller computer: `DESKTOP-FB022`

6. `08:45:10` - `Security Event 4625`
- Unlock attempt failed because the account was already locked out.
- Logon type: `7 (Unlock attempt)`

### Additional credential failures from another source
7. `08:45:44` - `Security Event 4771`
- Kerberos pre-authentication failed.
- Account: `FINBRIDGE\cthompson`
- Failure code: `0x18 (wrong password)`
- Source IP: `10.10.8.112`

8. `08:46:01` - `Security Event 4771`
- Repeat Kerberos pre-authentication failure for the same account from `10.10.8.112`.

9. `08:46:33` - `Security Event 4771`
- Repeat Kerberos pre-authentication failure for the same account from `10.10.8.112`.

### Resolution evidence
10. `09:08:14` - `Security Event 4722`
- A user account was enabled.
- Account: `FINBRIDGE\cthompson`
- Done by: `FINBRIDGE\helpdesk-admin`

11. `09:09:01` - `Security Event 4624`
- An account was successfully logged on.
- Account: `FINBRIDGE\cthompson`
- Logon type: `2 (Interactive)`
- Source: `DESKTOP-FB022`

## Timeline
1. `08:40`
- User-reported login failure begins.

2. `08:44:01`
- First recorded wrong-password validation failure on `DESKTOP-FB022`.

3. `08:44:03` to `08:44:55`
- Repeated interactive logon failures continue for `cthompson`.

4. `08:44:56`
- Account lockout occurs.

5. `08:45:10`
- Unlock attempt fails because the account remains locked.

6. `08:45:44` to `08:46:33`
- Additional wrong-password Kerberos pre-authentication failures are recorded from `10.10.8.112`.

7. During remediation
- Helpdesk intervention is applied to restore account access.

8. `09:08:14`
- `cthompson` account is enabled by `FINBRIDGE\helpdesk-admin`.

9. `09:09:01`
- `cthompson` successfully logs on interactively to `DESKTOP-FB022`.

10. `09:09`
- Issue is confirmed resolved; user login is verified and no further issues are reported.

## 5 Whys Analysis
1. Why was `cthompson` unable to log in?
- The account could not complete authentication.

2. Why could authentication not complete?
- The account was locked out after repeated failed sign-in attempts.

3. Why was the account locked out?
- Multiple wrong-password submissions were made against `FINBRIDGE\cthompson`.

4. Why were wrong-password submissions still occurring?
- The same bad credentials were being entered or retried from `DESKTOP-FB022` and also observed from `10.10.8.112`.

5. Why did the issue persist until helpdesk action?
- The blocking account state remained in place until the account was enabled and the stale credential source was remediated.

## Incident Classification
- Type: single-user authentication failure.
- Failure mode: account lockout caused by repeated wrong-password attempts.
- Recovery method: account enabled by helpdesk and successful re-logon verified.

## Resolution Applied
1. The account was enabled by `FINBRIDGE\helpdesk-admin` at `09:08:14`.
2. The user performed a successful interactive logon at `09:09:01` from `DESKTOP-FB022`.
3. Service was verified as restored after the successful logon.

## Preventive Actions
1. Identify and remove the stale credential source.
- Review `DESKTOP-FB022` for cached credentials, saved passwords, mapped resources, and any automation using `cthompson` credentials.
- Investigate the `10.10.8.112` source for any client, app, or device still using an old password.

2. Reduce repeat lockout risk.
- After password resets or account recovery, require the user to update all dependent devices and applications before resuming normal use.
- Instruct helpdesk to verify common retry sources before re-enabling the account.

3. Add better lockout telemetry.
- Alert on `4740` events for user accounts with the caller computer and source IP included in the review notes.
- Correlate `4625`, `4776`, and `4771` events so the source of repeated bad credentials is easier to isolate.

4. Improve endpoint credential hygiene.
- Clear saved credentials from Windows Credential Manager, mapped drives, RDP profiles, email clients, and scheduled tasks where user credentials are stored.
- Revalidate any scripts or services running under the user identity after recovery.

5. Introduce a post-recovery verification step.
- Confirm one clean interactive logon after unlock or enablement.
- Confirm no new lockout or bad-password events appear during the monitoring window.

## Verification Criteria
1. `FINBRIDGE\cthompson` logs on successfully without account lockout.
2. No new `4740` events appear for the account after remediation.
3. No further `4625`, `4776`, or `4771` failures appear from `DESKTOP-FB022` or `10.10.8.112`.
4. User confirms access to the expected desktop and resources.

## Conclusion
This was a single-user authentication incident caused by repeated wrong-password attempts that locked `FINBRIDGE\cthompson` out. Helpdesk remediation enabled the account at `09:08:14`, and successful interactive logon at `09:09:01` confirmed recovery.