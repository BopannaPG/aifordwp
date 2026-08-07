# Ranked Hypothesis - Win11 Floor 3 Black Screen / No Group Policy

Date: 2026-08-07  
Scope: 3 Win11 machines on Floor 3 (same OU/pool) show black screen symptoms with Group Policy failures; 1 peer machine in same OU unaffected.

## Weighting approach
Ranking is weighted heavily by the timing clue: an overnight migration/image/scope change impacted one pool/subnet, and only machines using that path failed.

## Top 5 Most Likely Causes (Most probable first)

### 1) DHCP scope still handing out decommissioned DNS server (primary hypothesis)
Why this fits the scope facts:
- Affected clients received old DNS (example: 10.10.3.250 / 172.16.5.5) that was decommissioned overnight.
- Logs show Netlogon 5719, DNS timeouts, and GP 1058/1030/1129 all consistent with "cannot find DC/SYSVOL because DNS cannot resolve/reach DC".
- Unaffected peer got correct DNS (10.10.0.10) and processed GP successfully.
- Strongest match to "overnight change + one pool/subnet only" pattern.

Single fastest check:
- On one affected machine run `ipconfig /all` and confirm DNS server list; if it shows old/decommissioned DNS, compare to DHCP scope Option 006 for that subnet.

### 2) Overnight pool image/update reverted DNS behavior to DHCP (or removed manual override)
Why this fits the scope facts:
- If a pre-migration manual DNS override existed on some machines, an image refresh could revert adapters to DHCP and expose bad DHCP Option 006.
- Explains why one manually preconfigured machine remained healthy while most peers in same OU failed.
- Timing aligns with overnight update window and pool-limited impact.

Single fastest check:
- Compare adapter DNS source/state on affected vs unaffected host (`Get-DnsClientServerAddress` and adapter config history) to see whether affected nodes switched to DHCP-driven DNS after the overnight change.

### 3) Subnet-specific DHCP policy/helper path serving wrong options to Floor 3 only
Why this fits the scope facts:
- Incident is localized to Floor 3 population, not enterprise-wide.
- Different clients in same organization receiving different DNS values implies scope/policy/relay segmentation issue.
- One unaffected machine can be explained by local manual DNS or different reservation/policy path.

Single fastest check:
- On DHCP server, inspect effective Option 006 at scope, policy, and reservation levels for Floor 3 subnet; verify what lease records show for each affected host MAC.

### 4) Residual static DNS/NRPT config on affected machines pointing to retired resolver
Why this fits the scope facts:
- A subset effect (3 of 4) can occur if only those endpoints carried legacy static DNS artifacts.
- Would produce identical symptoms: DC lookup failure, SYSVOL path failures, GP errors, and potential logon shell delays/black screen behavior.
- Still consistent with overnight event if cleanup was incomplete before migration cutover.

Single fastest check:
- Run `Get-DnsClientServerAddress` and `netsh interface ip show dns` on each affected endpoint; confirm whether any interface has static old DNS despite expected central DNS.

### 5) Boot-time network readiness delay as a contributing amplifier (not primary)
Why this fits the scope facts:
- Early startup sequence shows GP attempts before stable connectivity and DHCP lease completion.
- Could worsen user-visible black screen duration when domain-dependent processing retries.
- However, by itself it does not explain persistent wrong DNS assignment; therefore lower probability.

Single fastest check:
- Reboot one affected machine after forcing correct DNS and run `gpupdate /force`; if GP succeeds immediately, startup timing was secondary, not root.

## Current position (no single-cause commitment)
Most evidence points to DNS assignment path failure on the Floor 3 DHCP scope after overnight decommission/migration, with image/config drift as a possible co-factor. Final root-cause declaration should wait for one-pass validation of checks #1 and #3.