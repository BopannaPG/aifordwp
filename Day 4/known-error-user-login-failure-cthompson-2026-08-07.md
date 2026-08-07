Symptom     : User `cthompson` could not log in from `DESKTOP-FB022`. The failure began around `08:40` and persisted until account remediation.

Cause       : Repeated wrong-password attempts locked `FINBRIDGE\cthompson` out. The lockout was confirmed by `Security Event 4740` at `08:44:56`, with preceding `4776`, `4625`, and `4771` failures showing wrong-password authentication attempts.

Scope       : This affected only `FINBRIDGE\cthompson`. The incident involved `DESKTOP-FB022` and additional wrong-password pre-authentication attempts from `10.10.8.112` during the same window.

Workaround  : Enable or unlock the account to restore access. In this incident, `FINBRIDGE\helpdesk-admin` enabled the account at `09:08:14`, and `cthompson` then logged on successfully at `09:09:01` from `DESKTOP-FB022`.

Permanent fix: Remove the stale credential source that kept submitting the bad password. Clear cached credentials on `DESKTOP-FB022` and review any device or client associated with `10.10.8.112`, then confirm the user can log on normally.

How to spot it: Look for `Security Event 4776` with `0xC000006A (wrong password)`, repeated `Security Event 4625` interactive failures with `Unknown user name or bad password`, `Security Event 4740` lockout, and `Security Event 4771` with `0x18 (wrong password)`. In this incident, the key timestamps were `08:44:01`, `08:44:03`, `08:44:28`, `08:44:55`, `08:44:56`, `08:45:10`, `08:45:44`, `08:46:01`, and `08:46:33`.