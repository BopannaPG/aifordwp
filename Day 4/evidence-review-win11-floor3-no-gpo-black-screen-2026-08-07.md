# Evidence Review Against Ranked Hypotheses

Date: 2026-08-07  
Incident scope: 3 Win11 machines affected on Floor 3, no Group Policy/DC connectivity during startup window.

## Source Evidence
System Event Log - DESKTOP-FB031, startup window 07:40-07:55 on 2024-03-15.

## Hypothesis-by-Hypothesis Judgement

### 1) DHCP scope still handing out decommissioned DNS server
Judgement: Support

Why:
- The event log explicitly shows DHCP assigning an old DNS server that had already been decommissioned.
- Domain join channel and GPO/SYSVOL failures are consistent with broken DC name resolution.

Determining events:
- 07:42:18 - DHCP Client Event 50036: DNS assigned by DHCP is 10.10.3.250 (old/decommissioned).
- 07:41:05 - DNS Client Event 1014: DC name resolution timed out; configured DNS servers did not respond.
- 07:40:08 - Netlogon Event 5719: secure channel failed; no DC available; DNS query no response.
- 07:40:09 and 07:40:11 - GroupPolicy Event 1058: cannot access SYSVOL path.
- 07:40:12 and 07:44:01 - GroupPolicy Event 1129: no DC connectivity.

### 2) Overnight pool/image update reverted clients to DHCP DNS (removed manual override)
Judgement: Neutral

Why:
- Evidence confirms DHCP-delivered DNS was used on the affected endpoint.
- Provided events do not directly prove a transition from static DNS to DHCP occurred overnight.

Determining events:
- 07:42:18 - DHCP Client Event 50036: confirms DHCP-provided DNS in use.
- No direct event in provided set proving pre-incident static DNS changed to DHCP.

### 3) Subnet-specific DHCP policy/helper path serving wrong options to Floor 3 only
Judgement: Support

Why:
- Floor-specific impact plus wrong DNS assignment via DHCP strongly matches scope/policy/helper misconfiguration localized to this subnet.

Determining events:
- 07:42:18 - DHCP Client Event 50036: DHCP assigns old DNS value.
- 07:41:05 - DNS Client Event 1014: resolver timeout/no response.
- 07:40:08 - Netlogon Event 5719: DC reachability failure.

### 4) Residual static DNS or local resolver config on affected endpoints
Judgement: Contradicts

Why:
- The strongest evidence points to DHCP-assigned wrong DNS as the active failure source, not a local static DNS artifact.

Determining events:
- 07:42:18 - DHCP Client Event 50036: DNS explicitly assigned by DHCP as 10.10.3.250.
- 07:41:05 - DNS Client Event 1014: behavior consistent with bad assigned resolver.

### 5) Boot-time network readiness delay as main cause
Judgement: Contradicts (as primary cause)

Why:
- Failures persist after startup and after DHCP lease assignment, indicating persistent DNS/DC path failure rather than only transient startup timing.

Determining events:
- 07:40:12 - GroupPolicy Event 1129: initial no-DC connectivity.
- 07:42:18 - DHCP Client Event 50036: lease obtained with wrong DNS.
- 07:44:01 - GroupPolicy Event 1129: repeated no-DC failure persists.

## Note
This evidence review intentionally does not select a final winner; it only classifies each ranked hypothesis as support/neutral/contradict based on supplied log evidence.