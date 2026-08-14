# RCA - FinBridge VDI Session Launch Failure (Pool-02)

Date: 2026-08-14  
Incident Type: Citrix VDI Session Launch Failure  
Environment: FinBridge Citrix Site

## Executive Summary

A session launch degradation affected FinBridge-VDI-Pool-02 users (22/30 impacted). Broker logs showed launch timeout and error 1030 with message "No machines available in the desktop group." Pool-02 machine catalog showed only 3 of 25 machines registered, while Pool-01 remained largely healthy at 19 of 20 registered. Unregistered Pool-02 machine samples reported inability to contact dc-vdi-02 on port 80 with connection refused. Delivery Controller health showed Citrix Broker Service STOPPED on dc-vdi-02, with a pending reboot following Windows update activity. dc-vdi-01 remained healthy and running.

## Scope and Impact

- Impacted desktop group/pool: FinBridge-VDI-Pool-02
- Users affected: 22 of 30
- Unaffected comparator: FinBridge-VDI-Pool-01
- User-facing symptom: VDI launch failure at brokering stage
- Business effect: Majority of users in one production pool unable to start sessions

## Supporting Evidence

### Broker log evidence
- [08:58:34] Timeout waiting for machine registration response (30000ms exceeded)
- [08:58:34] Session launch FAILED: error 1030 "No machines available in the desktop group"

### Catalog evidence
- Pool-02: 25 provisioned; 3 registered; 22 unregistered; maintenance mode 0
- Pool-01: 20 provisioned; 19 registered; 1 unregistered

### VDA sample evidence (Pool-02)
- VDI-P02-014 registration attempt failed; unable to contact Delivery Controller; dc-vdi-02.finbridge.local:80 connection refused
- VDI-P02-017 registration attempt failed; unable to contact Delivery Controller; dc-vdi-02.finbridge.local:80 connection refused

### Controller health evidence
- dc-vdi-02:
  - Citrix Broker Service: STOPPED
  - Last known running: yesterday 23:40
  - Windows update installed today 00:15; reboot required flag set; host not rebooted
- dc-vdi-01:
  - Citrix Broker Service: RUNNING
  - Uptime: 14 days

## Timeline (From Provided Data)

- Yesterday 23:40: dc-vdi-02 Broker Service last known running
- Today 00:15: Windows update installed on dc-vdi-02; reboot required set; no reboot completed
- 06:15-06:16: Pool-02 VDA registration attempts fail with dc-vdi-02:80 connection refused
- 08:58:03: User launch requested in Pool-02
- 08:58:04: Broker queries available machines in Pool-02
- 08:58:34: Broker times out at 30000ms waiting for machine registration response
- 08:58:34: Launch fails with error 1030 text: "No machines available in the desktop group"

## 5 Whys Analysis

1. Why did users fail to launch sessions in Pool-02?
- Because broker could not allocate an available registered machine and timed out.

2. Why could broker not allocate machines?
- Because most Pool-02 machines were unregistered (22 unregistered, only 3 registered).

3. Why were Pool-02 machines unregistered?
- Because VDAs failed to register against their Delivery Controller endpoint and received connection refused on dc-vdi-02:80.

4. Why was connection refused occurring on dc-vdi-02?
- Because the Citrix Broker Service on dc-vdi-02 was stopped.

5. Why was Broker Service stopped and not recovered?
- Because update-related state required host reboot and post-update service validation did not complete before production hours.

## Final Root Cause Statement

Primary cause: Service availability failure on Delivery Controller dc-vdi-02 (Citrix Broker Service stopped in a pending-reboot post-update state), which caused widespread VDA unregistration in FinBridge-VDI-Pool-02 and led to broker launch failures.

Note on error code interpretation:
- This RCA confirms only what is present in provided logs: error 1030 text is "No machines available in the desktop group." No additional vendor-version-specific code semantics are asserted.

## Resolution Plan (Exact Steps)

1. Initiate controlled change window and stakeholder notification.
2. Capture pre-remediation evidence on dc-vdi-02:
- Broker Service status
- Reboot-required status and recent update details
- Relevant event logs snapshot
3. Reboot dc-vdi-02 to complete pending update cycle.
4. Post-reboot validate:
- Citrix Broker Service startup type = Automatic
- Citrix Broker Service status = Running
5. If service is not running, start service manually and review immediate startup errors.
6. Validate controller endpoint accessibility from sample Pool-02 VDAs.
7. Trigger/allow VDA registration refresh; restart VDA desktop service on failed samples if required.
8. Monitor catalog metrics until registered count normalizes for Pool-02.
9. Execute controlled user launch tests in Pool-02.
10. Close incident only after sustained stable launch success and no recurring broker timeout/1030.

## Correct Order of Operations

1. Preserve stable path (do not disrupt dc-vdi-01).
2. Collect evidence before change.
3. Reboot dc-vdi-02.
4. Validate Broker Service and endpoint readiness.
5. Restore VDA registrations.
6. Validate user launch outcome.
7. Observe for stability window.

## Verification of Resolution

Technical verification:
- dc-vdi-02 Broker Service remains Running.
- Pool-02 registered count rises significantly from 3 and unregistered count drops from 22.
- No new connection-refused registration failures to dc-vdi-02:80 on sampled VDAs.

Functional verification:
- Multiple user launch attempts in Pool-02 complete successfully.
- No repeated broker timeout (30000ms) or error 1030 entries during validation window.

Control verification:
- Pool-01 health remains stable throughout.

## Preventive Actions

1. Post-patch controller reboot policy
- Enforce mandatory reboot completion after Delivery Controller updates within approved maintenance window.

2. Automated controller health gate
- Implement automated check that blocks maintenance closure unless Broker Service is Running and endpoint health probe passes.

3. Registration drift alerting
- Add threshold alerts for abrupt registered/unregistered ratio shifts by pool (for example, alert if unregistered exceeds defined baseline variance).

4. Operational runbook hardening
- Add explicit post-update validation checklist and rollback/escalation path for controller service failures.

## Ownership and Follow-up

- Platform team: implement reboot/health gate automation
- EUC operations: define alert thresholds and on-call response playbook
- Change management: enforce post-update validation evidence in change closure criteria

