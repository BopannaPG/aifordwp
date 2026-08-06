# Structured Triage Summary

## Summary (one line)
Ticket T-1008 reports VPN connects successfully, but internal resources are unreachable after a Windows 11 upgrade.

## Impact (who/how many/business urgency)
- Who is affected: Reported user/device (to-verify).
- How many affected: One reported case (to-verify if broader post-upgrade pattern).
- Business urgency: User may be unable to access required internal systems despite VPN connection (urgency to-verify).

## known facts
- Ticket reference: T-1008.
- VPN connects.
- Internal resources are not reachable.
- Issue context is after Windows 11 upgrade.

## Missing information to gather
- Which specific internal resources are unreachable.
- Whether failures occur by hostname, by IP, or both.
- Whether issue occurs on multiple networks.
- VPN client type/version and any warning messages.
- Whether any internal resource is reachable at all.
- Expected tunneling behavior for this profile (to-verify).
- Whether similar cases are reported on same upgrade cohort.

## likely catagory
- Remote Access / VPN Post-Upgrade Internal Connectivity Issue (to-verify).

## First diagnostic step
- Test reachability of an internal resource by both hostname and direct internal address while VPN is connected to quickly determine whether the primary issue is name resolution or broader internal path access (to-verify result).
