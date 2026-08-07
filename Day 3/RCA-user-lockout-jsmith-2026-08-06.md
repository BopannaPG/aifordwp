# Root Cause Analysis (RCA)

## Incident Title
User lockout incident for account `jsmith` on `DESKTOP-FB001`

## Date/Time Window Reviewed
30-minute window (08:02 to 08:23)

## Analyst
DWP Analyst

## Scope
Review Windows Security events provided for the lockout period, reconstruct event sequence, identify most likely cause, and define corrective/preventive actions.

## Event ID Meaning (What each event records)

### Event ID 4625 (Audit Failure)
Records a failed logon attempt.
- In this case:
  - Account: `jsmith`
  - Failure reason at 08:02 and 08:04: `Unknown username or bad password`
  - Source: `DESKTOP-FB001`
  - Logon type `2`: interactive local/console sign-in attempt
  - At 08:07 failure reason changed to `Account locked out`
  - Logon type `7` at 08:07: workstation unlock attempt

### Event ID 4740 (Account lockout)
Records that an account was locked out by policy.
- In this case:
  - Account: `jsmith`
  - Caller/source system: `DESKTOP-FB001`

### Event ID 4722 (Audit Success)
Records that a user account was enabled by an administrator/process.
- In this case:
  - Account: `jsmith`
  - Performed by: `FINBRIDGE\helpdesk-admin`

### Event ID 4624 (Audit Success)
Records a successful logon.
- In this case:
  - Account: `jsmith`
  - Logon type `2`: successful interactive sign-in

## Timeline Reconstruction (Plain English)
1. At 08:02, `jsmith` attempted an interactive sign-in on `DESKTOP-FB001` and failed due to bad credentials (4625).
2. At 08:04, a second interactive sign-in attempt from the same machine failed for the same reason (4625).
3. At 08:06, the account was locked out (4740), called from `DESKTOP-FB001`, indicating lockout threshold was reached.
4. At 08:07, an unlock attempt on the workstation failed because the account was still locked (4625, logon type 7).
5. At 08:22, `FINBRIDGE\helpdesk-admin` enabled the account (4722).
6. At 08:23, `jsmith` successfully signed in interactively (4624).

## Most Likely Cause of Lockout
Most likely cause: repeated bad-password interactive sign-in attempts from the user device (`DESKTOP-FB001`) triggered domain/local lockout policy.

### Evidence
- Multiple 4625 failures with `Unknown username or bad password` before lockout.
- 4740 explicitly states account lockout was called from the same endpoint (`DESKTOP-FB001`).
- Post-lockout 4625 reason changes to `Account locked out`, confirming policy lock state.
- Administrative intervention (4722) is followed by immediate successful sign-in (4624), supporting that lock state (not account compromise) was the immediate blocker.

## 5 Whys Analysis
1. Why was `jsmith` unable to access the machine?
- Because the account entered a locked-out state.
2. Why did the account lock out?
- Because failed sign-in attempts exceeded lockout threshold.
3. Why were there repeated failed sign-ins?
- Interactive attempts from `DESKTOP-FB001` used invalid credentials (`Unknown username or bad password`).
4. Why were invalid credentials used repeatedly?
- Most probable: user entered an incorrect password multiple times during sign-in/unlock.
- Alternate possibility to validate: stale cached credentials/credential provider mismatch on unlock path.
5. Why did this become a service incident?
- Lockout policy prevented further attempts until admin action, and user required helpdesk recovery.

## Root Cause Statement
Primary root cause: repeated invalid interactive credential attempts for `jsmith` on `DESKTOP-FB001` resulted in account lockout per configured lockout policy.

## Contributing Factors
- No immediate self-service recovery path in the moment (user required helpdesk action).
- Potential user confusion between sign-in and unlock credential entry (to verify).

## Corrective Actions (Immediate)
1. Confirm account status and unlock/enable via standard IAM/AD process.
2. Confirm successful post-recovery interactive logon.
3. Ask user to verify keyboard layout/Caps Lock and credential format before retrying.

## Preventive Actions (Recommended)
1. User guidance: short awareness note on lockout thresholds and safe retry behavior.
2. Improve helpdesk playbook: include fast triage checks for lockout source host and logon type.
3. Consider enabling/advertising self-service password reset/unlock if policy allows.
4. Monitor repeated 4625 + 4740 patterns per endpoint to identify recurring training or device issues.

## Validation / Follow-up Checks
1. Check if additional 4625 events occurred before 08:02 from the same host/account (to confirm full failure count).
2. Confirm account lockout threshold policy settings applied to `jsmith`.
3. Verify whether event 4767 (account unlocked) exists in full logs; provided sample shows 4722 (enabled).
4. Confirm no parallel lockout sources (mobile, VPN, mapped drives, services) in the same window.

## Incident Conclusion
Incident resolved after administrative account recovery action and successful user sign-in. Evidence supports accidental repeated bad-password attempts from the user endpoint as the most likely trigger.
