Symptom: Users on affected Floor 3 Windows 11 machines see a black screen after sign-in and Group Policy does not process. During startup, systems show domain controller connectivity and policy processing failures.

Cause: The verified root cause is stale DNS assignment from the Floor 3 DHCP scope after overnight DNS migration. Clients received a decommissioned DNS server address and could not resolve/reach domain controller services.

Scope: Impact was 3 of 4 Windows 11 machines on Floor 3 in OU=Finance. A same-OU control machine with correct DNS assignment was unaffected.

Workaround: Restore service by correcting DNS assignment on affected clients to the new DNS server (10.10.0.10). Then verify policy processing health on remediated systems.

Permanent fix: Update the Floor 3 DHCP scope DNS option so only the new resolver is distributed and remove stale DNS references from the change path. Keep DNS cutover controls that require scope update and post-change validation before/after decommission.

How to spot it: Look for Netlogon Event 5719, GroupPolicy Events 1058/1030/1129, DNS Client Event 1014, and DHCP Client Event 50036 showing old DNS assignment (for example 10.10.3.250). In the healthy control path, DHCP Client Event 50036 shows 10.10.0.10 and GroupPolicy Event 1500 confirms successful processing.