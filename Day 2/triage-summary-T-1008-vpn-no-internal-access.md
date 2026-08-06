# Structured Triage Summary

## Summary (one line)
Ticket T-1008 reports VPN connects, but no internal resources are reachable after a Windows 11 upgrade.

## Impact (who/how many/business urgency)
- Who is affected: Reported user/device (to-verify).
- How many affected: One reported case (to-verify if multiple post-upgrade users).
- Business urgency: User may be blocked from internal systems despite VPN connection (urgency to-verify).

## known facts
- Ticket reference: T-1008.
- VPN connection succeeds.
- Internal resources are not reachable.
- Issue context is after Windows 11 upgrade.

## Missing information to gather
- Which internal resources are unreachable (file shares, intranet, line-of-business apps).
- Whether name-based access, IP-based access, or both fail.
- Whether issue occurs on home Wi-Fi only or other networks as well.
- VPN client type/version and any visible client warnings.
- Whether user can reach any internal endpoint at all.
- Whether split/full tunnel expectations are documented for this profile.
- Whether other users with same upgrade/build see identical behavior.

## likely catagory
- Remote Access / VPN Post-Upgrade Connectivity Routing or Resolution Issue (to-verify).

## First diagnostic step
- Validate whether any internal resource is reachable by both hostname and direct internal address while VPN is connected, to quickly determine if the primary fault is general routing versus name resolution (to-verify result).
