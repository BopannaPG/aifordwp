# Root Cause Analysis (RCA)

## Incident Title
Win11 Floor 3 black screen and Group Policy failure after DNS migration

## Date/Time Window Reviewed
2024-03-15 07:40 to 07:55 (startup incident window)  
Resolution verified at 07:40:05 AM (post-fix validation checkpoint)

## Analyst
DWP Engineer

## Executive Summary
Three Win11 machines on Floor 3 failed domain-dependent startup processing and presented black screen symptoms. Event evidence shows DNS/DC lookup failure, GPO SYSVOL access failure, and repeated no-DC connectivity errors. The incident was caused by an outdated DNS server still being distributed by the Floor 3 DHCP scope after overnight DNS migration/decommission. The suggested resolution was applied, Group Policy processing was verified healthy, and no further issues were reported.

## Business and Technical Impact
- Affected population: 3 of 4 machines in OU=Finance on Floor 3.
- User impact: delayed or failed post-login desktop readiness (black screen symptom) and policy application failure.
- Technical impact: loss of domain controller name resolution, Netlogon secure channel failure, and failed GPO processing from SYSVOL.

## Scope and Control Comparison
- Affected example host: DESKTOP-FB031.
- Unaffected control host in same OU: DESKTOP-FB029.
- Pattern: hosts receiving old DNS failed; host receiving correct new DNS succeeded.

## Timeline (UTC offset not provided in source)
1. 02:00 (overnight migration wave): legacy Floor 3 DNS resolver decommissioned.
2. 07:40:02: SCM Event 7036 on FB031, Network Location Awareness enters running state.
3. 07:40:08: Netlogon Event 5719 on FB031, secure channel to FINBRIDGE fails, DC DNS query no response.
4. 07:40:09: GroupPolicy Event 1058 on FB031, cannot access SYSVOL gpt.ini path.
5. 07:40:10: GroupPolicy Event 1030 on FB031, cannot query GPO list.
6. 07:40:11: GroupPolicy Event 1058 repeats on FB031.
7. 07:40:12: GroupPolicy Event 1129 on FB031, no network connectivity to DC.
8. 07:40:05 (control): DHCP Client Event 50036 on FB029, DNS assigned 10.10.0.10 (correct).
9. 07:40:11 (control): GroupPolicy Event 1500 on FB029, policy processed successfully.
10. 07:41:05: DNS Client Event 1014 on FB031, FINBRIDGE-DC01 resolution timed out, configured DNS non-responsive.
11. 07:42:18: DHCP Client Event 50036 on FB031, DNS assigned 10.10.3.250 (old/decommissioned).
12. 07:44:01: GroupPolicy Event 1129 repeats on FB031 (persistent no-DC state).
13. 07:40:05 AM (post-remediation checkpoint): resolution verified, system Group Policy healthy, no issues reported.

## Supporting Evidence

### Affected Host Evidence (DESKTOP-FB031)
- 07:40:08, Netlogon Event 5719:
  - Cannot establish secure channel to domain FINBRIDGE.
  - DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09 and 07:40:11, GroupPolicy Event 1058:
  - Cannot read SYSVOL gpt.ini path.
  - Error code 0x3 (path not found) consistent with unresolved/unreachable DC namespace.
- 07:40:10, GroupPolicy Event 1030:
  - Cannot query list of GPO objects.
- 07:40:12 and 07:44:01, GroupPolicy Event 1129:
  - No network connectivity to domain controller; failure persists.
- 07:41:05, DNS Client Event 1014:
  - FINBRIDGE-DC01 resolution timed out.
  - None of configured DNS servers responded.
- 07:42:18, DHCP Client Event 50036:
  - DNS assigned by DHCP: 10.10.3.250 (old DNS, decommissioned).

### Unaffected Host Evidence (DESKTOP-FB029)
- 07:40:05, DHCP Client Event 50036:
  - DNS assigned: 10.10.0.10 (correct new DNS).
- 07:40:11, GroupPolicy Event 1500:
  - Group Policy settings processed successfully.
- Context note: FB029 was manually reconfigured before migration wave.

### DHCP Server Comparison Evidence
- FB055-057 were assigned DNS 172.16.5.5 (Floor 3 local DNS, decommissioned).
- FB058 was assigned DNS 10.10.0.10 (correct central DNS), manually set prior to migration.
- Confirms configuration split by DNS assignment path, not by OU membership itself.

## Root Cause Statement
Primary root cause: Floor 3 DHCP scope continued to distribute a decommissioned DNS resolver address after the overnight migration wave. Endpoints receiving that stale DNS could not resolve/reach domain controllers, causing Netlogon secure channel failure and Group Policy processing failure, which manifested to users as black screen/delayed desktop readiness.

## Contributing Factors
1. DHCP scope Option 006 for Floor 3 subnet was not updated during migration cutover.
2. Limited pre-cutover validation of effective DNS options at scope/policy/reservation level.
3. Inconsistent endpoint DNS posture (some manually corrected, others dependent on DHCP).

## 5 Whys Analysis
1. Why did users see black screen and no Group Policy?
- Domain-dependent login/policy processing could not complete because DC connectivity failed.
2. Why did DC connectivity fail?
- Clients could not resolve/reach FINBRIDGE-DC01 via configured DNS.
3. Why could clients not resolve the DC?
- DHCP assigned an old DNS server that had been decommissioned.
4. Why was DHCP assigning an old DNS server after migration?
- Floor 3 DHCP scope configuration (Option 006) was not updated during the migration wave.
5. Why was the scope misconfiguration not caught before user impact?
- Change validation did not include a mandatory post-change lease-and-GPO functional check on DHCP-dependent endpoints in that subnet.

## Corrective Actions Implemented
1. Applied the suggested resolution to correct DNS assignment path for affected Floor 3 clients.
2. Ensured endpoints used the correct DNS server (10.10.0.10) instead of decommissioned resolver.
3. Re-verified system Group Policy processing post-fix.
4. Confirmed incident closure condition: no ongoing issues reported.

## Preventive Actions
1. Enforce migration runbook control:
- Add a required checklist item to update DHCP Option 006 for all impacted scopes before DNS decommission.
2. Add technical gate before decommission:
- Block resolver retirement until sampled clients from each subnet obtain new leases and pass DC resolution test.
3. Add post-change synthetic validation:
- Automated checks for nslookup of domain controllers and gpupdate /force on representative endpoints per subnet.
4. Add drift monitoring:
- Alert when DHCP scopes advertise DNS servers not in approved resolver inventory.
5. Standardize endpoint DNS governance:
- Reduce manual exceptions; document and track approved static overrides where required.

## Validation and Exit Criteria
Incident considered resolved when all conditions were true:
1. Affected endpoints receive correct DNS in DHCP lease data.
2. No recurring DNS Client 1014 for FINBRIDGE-DC01 on remediated endpoints.
3. No recurring Netlogon 5719 on remediated endpoints during startup.
4. GroupPolicy success observed (Event 1500 or equivalent successful processing signal).
5. Service desk reports no new black-screen/no-GPO complaints from Floor 3 after fix window.

## Lessons Learned
- DNS cutovers must treat DHCP scope correctness as a first-class dependency.
- A single subnet-scoped DHCP misconfiguration can mimic broader authentication/policy outages.
- Control-host comparison (same OU, different DNS assignment) is a high-value triage accelerator.

## Incident Conclusion
The incident was caused by stale DNS values distributed by the Floor 3 DHCP scope after overnight DNS migration. Correcting DNS assignment restored domain resolution and Group Policy processing. Resolution was verified at 07:40:05 AM, and no further issues were reported.