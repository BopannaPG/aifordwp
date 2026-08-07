# Ranked Hypotheses - Cthompson Login Failure

## Scope Facts
- Symptom: user `cthompson` is not able to log in.
- Who: only one user is affected.
- Since: about `08:40` this morning.
- Change: nil.

## Working Inference
The facts point away from a broad service outage and toward a user-specific or account-specific cause. The strongest signal is the single-user scope with no reported change.

## Re-ranked Most Likely Causes

### 1. Account lockout, disabled state, or sign-in restriction on `cthompson`
Why this fits the scope facts:
- Only one user is affected, which is consistent with an account state issue.
- The failure started at a specific time, which matches the onset of a lockout or restriction.
- No change was reported, so an account-state issue is more plausible than a newly introduced environment change.
Single fastest check:
- Check the account status and sign-in logs for `cthompson` at and after `08:40` for lockout, disablement, or blocked sign-in events.

### 2. Password expired, reset-required, or incorrect cached credentials
Why this fits the scope facts:
- A password or credential problem can affect only one user while leaving everyone else normal.
- The timing can align with the first login attempt after the credential state changes, even if no broader change was reported.
- A nil change record does not rule out an account-level credential problem.
Single fastest check:
- Verify whether `cthompson` is flagged for password expiry or reset, and confirm whether a clean sign-in attempt succeeds with known-good credentials.

### 3. Corrupted user profile or local profile load failure
Why this fits the scope facts:
- Profile corruption usually shows up as a single-user login failure rather than a shared outage.
- The issue starting at a known time can reflect the first time the profile state was exercised.
- No change is needed for a profile to become unusable.
Single fastest check:
- Test whether `cthompson` can log in with a fresh profile or on a different device/session to separate account failure from profile failure.

### 4. Conditional Access, MFA, or other identity policy targeting `cthompson`
Why this fits the scope facts:
- Policy evaluation can fail for one identity while other users remain unaffected.
- A rule-based block can start at a specific time without any reported infrastructure change.
- The scope facts do not show a service-wide pattern, which makes a targeted identity policy plausible.
Single fastest check:
- Review sign-in logs and policy evaluation for `cthompson` around `08:40` to see whether a Conditional Access or MFA rule blocked the sign-in.

### 5. User-specific logon dependency failure, such as a script, mapped resource, or group-based assignment
Why this fits the scope facts:
- Dependencies tied to one user can fail without affecting anyone else.
- The issue can begin at a specific time if the user first hits that path then.
- The lack of a reported change does not eliminate a user-scoped logon dependency problem.
Single fastest check:
- Try a minimal logon path for `cthompson` and compare it with a normal sign-in, then review whether any user-specific scripts, mappings, or assignments are failing.

## Current Position
Do not commit to one cause yet. The best-supported direction is an account-specific or user-specific failure, with account state and credential issues slightly ahead of profile or policy problems.

## Evidence Review Against Each Hypothesis

### 1. Account lockout, disabled state, or sign-in restriction on `cthompson`
Judgement: Support

Why:
- `Security Event 4740` at `08:44:56` shows the account was locked out for `FINBRIDGE\cthompson`.
- `Security Event 4625` at `08:45:10` explicitly says `Account locked out` on an unlock attempt.
- The earlier failures at `08:44:03`, `08:44:28`, and `08:44:55` show the same account failing repeatedly just before the lockout.

Determining events:
- `08:44:56` `Security Event 4740`
- `08:45:10` `Security Event 4625`
- `08:44:03` `Security Event 4625`

### 2. Password expired, reset-required, or incorrect cached credentials
Judgement: Support

Why:
- `Security Event 4776` at `08:44:01` reports `0xC000006A (wrong password)` for `FINBRIDGE\cthompson`.
- `Security Event 4771` at `08:45:44`, `08:46:01`, and `08:46:33` also reports `0x18 (wrong password)` for the same account.
- Those failures are consistent with bad credentials being entered or presented repeatedly.

Determining events:
- `08:44:01` `Security Event 4776`
- `08:45:44` `Security Event 4771`
- `08:46:01` `Security Event 4771`
- `08:46:33` `Security Event 4771`

### 3. Corrupted user profile or local profile load failure
Judgement: Contradict

Why:
- The evidence is centered on authentication failure before a successful logon, not on a profile load problem after sign-in.
- `Security Event 4625` at `08:44:03` and `08:44:28` shows `Unknown user name or bad password`, which points to credential validation rather than profile initialization.
- The lockout at `08:44:56` also occurs at the account-authentication layer, not the profile layer.

Determining events:
- `08:44:03` `Security Event 4625`
- `08:44:28` `Security Event 4625`
- `08:44:56` `Security Event 4740`

### 4. Conditional Access, MFA, or other identity policy targeting `cthompson`
Judgement: Contradict

Why:
- The logs show classic bad-password and lockout behavior, not a policy denial or MFA challenge.
- `Security Event 4776` at `08:44:01` and `Security Event 4771` at `08:45:44` both point to wrong-password validation failures.
- `Security Event 4740` at `08:44:56` confirms the account was locked due to repeated failures, which is more direct than a policy block.

Determining events:
- `08:44:01` `Security Event 4776`
- `08:45:44` `Security Event 4771`
- `08:44:56` `Security Event 4740`

### 5. User-specific logon dependency failure, such as a script, mapped resource, or group-based assignment
Judgement: Contradict

Why:
- The issue occurs during authentication, not after a successful sign-in where scripts or mappings would typically run.
- `Security Event 4625` at `08:44:03`, `08:44:28`, and `08:44:55` shows the sign-in is failing before that later logon path would matter.
- The lockout at `08:44:56` further supports repeated authentication failure as the immediate problem.

Determining events:
- `08:44:03` `Security Event 4625`
- `08:44:28` `Security Event 4625`
- `08:44:55` `Security Event 4625`
- `08:44:56` `Security Event 4740`

## Surviving Hypothesis
The surviving operational hypothesis is: `cthompson` is failing authentication because the account was locked out after repeated wrong-password attempts.

Why this survives:
- The lockout is directly confirmed by `Security Event 4740` at `08:44:56`.
- The repeated wrong-password signals in `Security Event 4776` at `08:44:01` and `Security Event 4771` at `08:45:44`, `08:46:01`, and `08:46:33` explain the lockout path.
- The failure occurs before any profile, policy, or logon-dependency stage would be expected to matter.

## Detailed Resolution Steps

### 1. Restore access safely
- Unlock `FINBRIDGE\cthompson` in the directory if the account is still locked.
- Verify the current password state and require a password reset if policy requires it.
- Do not retry the same stale credential set until the password state is confirmed.

### 2. Identify the source of the bad credentials
- Check whether `DESKTOP-FB022` is the user’s current workstation and whether it has stored or cached credentials for `cthompson`.
- Review the secondary source at `10.10.8.112` from the `4771` events to determine whether another device or session is repeatedly submitting the bad password.
- Look for scheduled tasks, services, mapped drives, saved RDP entries, browser sessions, or mobile mail clients using the old password.

### 3. Eliminate stale credential stores
- Clear cached credentials on the workstation and any other device associated with the user.
- Remove or update saved credentials in Credential Manager, mapped drive connections, and any remote access clients.
- Reconnect any dependent apps only after the password is reset and confirmed.

### 4. Re-test with controlled sign-in
- Have the user perform one clean interactive sign-in after the unlock/reset.
- Confirm that no new `4625`, `4776`, `4771`, or `4740` events appear during the test window.
- If the account locks again, immediately check the same two source paths: `DESKTOP-FB022` and `10.10.8.112`.

### 5. Confirm the fix is durable
- Monitor the account for the rest of the business day to ensure no recurrence.
- Validate that the user can access the expected resources after sign-in.
- If lockout repeats, escalate to the device or automation source that is continuing to submit the wrong password.

## Addendum - Updated Event Details

### Incident Window Evidence
- `08:44:01` `Security Event 4776` - domain controller validation failed for `FINBRIDGE\cthompson` with `0xC000006A (wrong password)` from `DESKTOP-FB022`.
- `08:44:03` `Security Event 4625` - interactive logon failed for `FINBRIDGE\cthompson` with `Unknown user name or bad password` from `DESKTOP-FB022`.
- `08:44:28` `Security Event 4625` - repeated interactive failure for `FINBRIDGE\cthompson` with `Unknown user name or bad password` from `DESKTOP-FB022`.
- `08:44:55` `Security Event 4625` - repeated interactive failure for `FINBRIDGE\cthompson` with `Unknown user name or bad password` from `DESKTOP-FB022`.
- `08:44:56` `Security Event 4740` - `FINBRIDGE\cthompson` account locked out, caller computer `DESKTOP-FB022`.
- `08:45:10` `Security Event 4625` - unlock attempt failed because the account was locked out.
- `08:45:44` `Security Event 4771` - Kerberos pre-authentication failed for `FINBRIDGE\cthompson` with `0x18 (wrong password)` from `10.10.8.112`.
- `08:46:01` `Security Event 4771` - repeat Kerberos pre-authentication failure for `FINBRIDGE\cthompson` from `10.10.8.112`.
- `08:46:33` `Security Event 4771` - repeat Kerberos pre-authentication failure for `FINBRIDGE\cthompson` from `10.10.8.112`.

### Surviving Hypothesis
- `cthompson` is locked out because repeated wrong-password attempts were submitted from one or more sources during the incident window.

### Resolution Summary
- Unlock the account if it is still locked.
- Reset the password if required by policy or if the user cannot confirm a correct current password.
- Identify and clear the source of stale credentials on `DESKTOP-FB022` and any device associated with `10.10.8.112`.
- Remove cached credentials from saved logons, mapped drives, services, RDP entries, or mobile clients.
- Perform one clean sign-in and confirm no new `4625`, `4776`, `4771`, or `4740` events appear.