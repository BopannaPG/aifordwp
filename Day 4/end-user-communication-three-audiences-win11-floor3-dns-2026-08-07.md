# End-User Communication Pack (Three Audiences)

## Common Facts Used in All Three Versions
- Three Windows 11 machines on Floor 3 were affected.
- After an overnight DNS migration, the Floor 3 network setting still handed out an old DNS server address.
- Those machines could not reach required company sign-in and policy services, causing black screen and policy failure symptoms.
- The fix was applied by correcting DNS assignment to the new server (10.10.0.10).
- Resolution was verified at 07:40:05 AM; policy processing is healthy and no further issues were reported.

## Audience 1 - Non-Technical Executive (Under 80 words)
Your access and data are safe. Three Windows 11 machines on Floor 3 were affected after an overnight network-name-service migration, because one Floor 3 network setting still provided an old server address. That prevented those machines from reaching required sign-in and policy services, causing black screen and policy issues. We corrected DNS assignment to the new server (10.10.0.10). Resolution was verified at 07:40:05 AM; policy processing is healthy and no further issues were reported. No action is needed.

## Audience 2 - Affected End-User Team (Under 100 words)
Hi team, three Windows 11 machines on Floor 3 had black screen and policy issues because, after an overnight network-name-service migration, one Floor 3 network setting was still giving an old server address, so those PCs could not reach required sign-in and policy services. We fixed this by correcting DNS assignment to the new server (10.10.0.10). Resolution was verified at 07:40:05 AM, policy processing is healthy, and no further issues were reported. If you see the same symptom again, restart once and contact the Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note
Incident scope and impact:
- 3 Win11 endpoints on Floor 3 impacted by black screen plus GP processing failure.

Root cause:
- Post-overnight DNS migration, Floor 3 DHCP scope continued distributing stale DNS (old resolver), so affected clients could not resolve/reach domain services (DC path), leading to Netlogon/GPO failure chain and user-visible black screen/policy symptoms.

Exact action taken:
- Corrected DNS assignment path for affected Floor 3 clients.
- Enforced new resolver assignment: 10.10.0.10.

Config detail:
- Fault condition: Floor 3 DHCP scope still referenced old DNS server (stale Option 006 path).
- Healthy path/control: endpoints with correct new DNS (10.10.0.10) processed policy successfully.

Verification:
- Resolution checkpoint confirmed at 07:40:05 AM.
- System Group Policy verified healthy.
- No additional issues reported after remediation.

Preventive action required:
1. Add mandatory runbook step: update DHCP DNS options for all impacted scopes before DNS decommission.
2. Add pre-decommission gate: sampled endpoints per subnet must renew lease and pass DC resolution/policy checks.
3. Add post-change validation automation (DNS resolution + GP health checks).
4. Add DHCP drift alerting for non-approved DNS server advertisement.
5. Minimize undocumented manual DNS exceptions; track approved overrides.