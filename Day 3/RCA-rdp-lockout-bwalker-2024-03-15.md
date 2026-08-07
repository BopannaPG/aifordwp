# Root Cause Analysis (RCA)

## Incident Title
RDP authentication failures leading to account lockout for FINBRIDGE\\bwalker

## Date/Time Window Reviewed
2024-03-15 14:01:02 to 14:22:09

## Analyst
DWP Analyst

## Scope
Analyze System and Security logs for RDP connection failures, explain event IDs, reconstruct event sequence, determine most likely lockout cause with evidence, and provide 5 Whys.

## Event ID Meaning (What each event records)

### System - TermDD - Event ID 56
Records an RDP transport/security layer protocol-stream error that causes client disconnect.
- In this incident, the disconnect involved client IP `10.10.5.44`.
- This can occur alongside authentication failures and does not by itself prove lockout.

### System - RemoteDesktopServices-RdpCoreTS - Event ID 140
Records an RDP connection failure due to incorrect username or password.
- In this incident, source IP is `10.10.5.44`.
- Indicates credential validation failure during RDP connection workflow.

### Security - Event ID 4625 (Audit Failure)
Records failed logon attempt.
- In this incident:
  - Account: `FINBRIDGE\\bwalker`
  - Failure reason: `Unknown username or bad password`
  - Logon type `10` (RemoteInteractive / RDP)
  - Source IP: `10.10.5.44`
- Multiple occurrences indicate repeated failed RDP authentication attempts.

### Security - Event ID 4740 (Audit Failure)
Records account lockout event.
- In this incident:
  - Locked account: `FINBRIDGE\\bwalker`
  - Caller computer: `10.10.5.44`
- This is the definitive lockout event and source indicator.

### System - RemoteDesktopServices-RdpCoreTS - Event ID 131
Records that the server accepted a new TCP connection from an RDP client.
- In this incident, client `10.10.5.44` reconnects later, showing network path is available.

### Security - Event ID 4624 (Audit Success)
Records successful logon.
- In this incident:
  - Account: `FINBRIDGE\\bwalker`
  - Logon type `10` (RDP)
  - Source IP: `10.10.5.44`
- Confirms eventual successful authentication via RDP.

## Timeline Reconstruction (Plain English)
1. At 14:01:02, RDP session setup from `10.10.5.44` encountered protocol/security stream issues and disconnected (TermDD 56).
2. At the same time, RDP subsystem recorded bad-credential failure from `10.10.5.44` (RdpCoreTS 140).
3. At 14:01:04, Security log recorded first failed RDP logon for `FINBRIDGE\\bwalker` due to bad username/password (4625, logon type 10).
4. Additional failed RDP logons occurred at 14:03:18 and 14:05:33 from the same IP for the same account (4625).
5. At 14:05:34, account lockout was triggered (4740), with caller `10.10.5.44`.
6. At 14:22:07, client `10.10.5.44` established a fresh TCP connection (131).
7. At 14:22:09, `FINBRIDGE\\bwalker` successfully completed RDP authentication (4624).

## Most Likely Cause of Lockout
Most likely cause: repeated incorrect RDP credentials entered (or replayed) from client `10.10.5.44` for account `FINBRIDGE\\bwalker`, exceeding account lockout threshold.

## Evidence
1. Three consecutive Security 4625 failures for the same account and same source IP with reason `Unknown username or bad password`.
2. Security 4740 immediately follows third failed attempt and identifies same caller/source `10.10.5.44`.
3. Later Security 4624 success from same source shows account and access path were valid once correct/authentic credentials were used or lockout was cleared.
4. RdpCoreTS 140 corroborates invalid credentials at RDP layer.

## Confidence and Uncertainty
- High confidence in lockout trigger path (repeated bad password attempts over RDP).
- Moderate confidence on why bad credentials were presented (manual mistype vs stale saved credentials vs script/task), because logs shown do not include credential manager/task artifacts.

## 5 Whys Analysis
1. Why was user `FINBRIDGE\\bwalker` locked out?
- The account exceeded lockout threshold after repeated failed RDP logons.
2. Why were there repeated failed RDP logons?
- Authentication attempts from `10.10.5.44` used incorrect username/password.
3. Why was incorrect credential repeatedly sent?
- Most likely user entered wrong password multiple times, or client retried stale saved credentials.
4. Why did this become an incident?
- Lockout policy intentionally blocked further attempts to protect the account.
5. Why was resolution delayed until later success?
- Correct credentials and/or unlocked account state were not in place until subsequent attempt at 14:22:09.

## Root Cause Statement
Primary root cause: repeated bad-credential RDP authentication attempts from client `10.10.5.44` against account `FINBRIDGE\\bwalker` triggered domain lockout policy.

## Contributing Factors
1. Potential saved/stale credentials on RDP client.
2. Possible user credential entry errors during repeated attempts.
3. Lockout threshold sensitivity (policy behaving as designed, but can increase incident frequency).

## Corrective Actions (Immediate)
1. Confirm account lockout cleared and user can authenticate.
2. On client `10.10.5.44`, remove stale cached credentials for target host/account from Credential Manager.
3. Re-test RDP with explicit `FINBRIDGE\\bwalker` username format.

## Preventive Actions
1. User guidance on lockout-safe retry behavior and domain username format.
2. Endpoint hygiene: periodic cleanup of obsolete saved RDP credentials.
3. Monitoring alert for multiple 4625 (type 10) from same source preceding 4740.
4. Consider conditional access/MFA hardening for remote access flows as policy permits.

## Validation Checklist
1. No additional 4625 bursts for `FINBRIDGE\\bwalker` from `10.10.5.44` after remediation.
2. No recurring 4740 for the same account in the next observation window.
3. Successful 4624 (type 10) logons continue without immediate failures.

## Incident Conclusion
The event chain clearly indicates an RDP bad-credential sequence from one client IP that triggered lockout policy, followed by eventual successful RDP login once credentials/account state were corrected.
