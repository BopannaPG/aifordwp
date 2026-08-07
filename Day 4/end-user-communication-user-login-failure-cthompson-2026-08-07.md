## Audience 1 - Non-technical executive
Your access and data are safe. Around 08:40, repeated wrong-password attempts locked `cthompson` out, and the account was enabled at 09:08:14 by `FINBRIDGE\helpdesk-admin`. `cthompson` then logged on successfully at 09:09:01 from `DESKTOP-FB022`. If you see the same issue, contact the Service Desk.

## Audience 2 - Affected end-user team
Your access and data are safe. Around 08:40, repeated wrong-password attempts locked `cthompson` out, and the account was enabled at 09:08:14 by `FINBRIDGE\helpdesk-admin`. `cthompson` then logged on successfully at 09:09:01 from `DESKTOP-FB022`. If you see the same issue, contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note
Access and user data were safe; the failure was authentication-only.

Root cause:
- Repeated wrong-password attempts against `FINBRIDGE\cthompson` triggered account lockout.

Exact action taken:
- `FINBRIDGE\helpdesk-admin` enabled the account at `09:08:14`.

Config detail:
- Failure events were recorded at `08:44:01` (`4776`), `08:44:03`, `08:44:28`, and `08:44:55` (`4625`), followed by lockout at `08:44:56` (`4740`).
- Additional wrong-password Kerberos pre-authentication failures were seen from `10.10.8.112` at `08:45:44`, `08:46:01`, and `08:46:33` (`4771`).
- Successful interactive logon was verified from `DESKTOP-FB022` at `09:09:01` (`4624`).

Verification step:
- Confirmed `cthompson` could log on successfully after enablement.

Preventive action needed:
- Identify and remove the stale credential source on `DESKTOP-FB022` and any device or client associated with `10.10.8.112`.
- Clear cached credentials and update dependent sign-in sources before returning the user to normal use.
- Monitor for repeat `4625`, `4776`, `4771`, or `4740` events after recovery.