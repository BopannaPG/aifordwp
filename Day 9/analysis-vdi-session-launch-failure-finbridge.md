# FinBridge VDI Session Launch Failure - Detailed Analysis

Date: 2026-08-14  
Analyst: DWP Incident Analysis

## Incident Scope (Facts Only)

- Affected pool: FinBridge-VDI-Pool-02
- Impacted users: 22 of 30
- Unaffected pool: FinBridge-VDI-Pool-01 (same site)
- Broker failure lines:
  - "Timeout waiting for machine registration response (30000ms exceeded)"
  - "Session launch FAILED: error 1030 'No machines available in the desktop group'"
- Catalog status:
  - Pool-02: 25 provisioned, 3 registered, 22 unregistered, maintenance mode 0
  - Pool-01: 20 provisioned, 19 registered, 1 unregistered
- Unregistered sample details in Pool-02:
  - Unable to contact Delivery Controller
  - dc-vdi-02.finbridge.local:80 - connection refused
- Controller health:
  - dc-vdi-02: Citrix Broker Service STOPPED; last running yesterday 23:40; Windows update at 00:15 with reboot required and not completed
  - dc-vdi-01 (serves Pool-01): Citrix Broker Service RUNNING; uptime 14 days

## Ranked Likely Causes (Most Probable First)

### 1) Citrix Broker Service stopped on dc-vdi-02 after update/reboot-pending state

Why it fits the evidence:
- Pool-02 has a high unregistered ratio (22/25), while Pool-01 remains mostly healthy (19/20 registered).
- Unregistered machines explicitly show connection refused to dc-vdi-02 on port 80.
- A hard connection refusal aligns with a required service endpoint not listening.
- Controller health confirms Citrix Broker Service is STOPPED on dc-vdi-02.
- Timing is consistent: last known service run ended before observed launch failures, with update + pending reboot afterward.

Fastest check to confirm or eliminate:
- On dc-vdi-02, verify Broker Service state and listener availability:
  - Service status is Stopped.
  - Port 80 listener for the broker endpoint is absent.
- Then start service (or reboot if required), and immediately observe whether registration count in Pool-02 rises.

Specific remediation if confirmed:
- Perform controlled recovery on dc-vdi-02:
  1) Put controller in maintenance window / notify operations.
  2) Reboot dc-vdi-02 to complete pending update state.
  3) Confirm Citrix Broker Service is set to Automatic and Running.
  4) Validate endpoint responsiveness from Pool-02 VDAs.
  5) Force or wait for VDA re-registration and confirm registered count returns to expected baseline.

### 2) Controller-to-VDA communication path failure isolated to dc-vdi-02 (service dependency, local firewall, or listener binding)

Why it fits the evidence:
- "Connection refused" can occur if local firewall/service binding/dependent components prevent endpoint exposure, even if controller host is reachable.
- Impact is pool-specific and aligns to one controller target.
- The symptom pattern (unregistered VDAs and broker timeout) is compatible with controller endpoint unavailability at transport level.

Fastest check to confirm or eliminate:
- From a Pool-02 VDA, run connectivity test to dc-vdi-02:80 and compare with dc-vdi-01 endpoint behavior.
- On dc-vdi-02, inspect Windows Firewall rules, HTTP bindings, and dependent service chain for Broker Service.

Specific remediation if confirmed:
- Correct endpoint exposure:
  - Restore required firewall rules/listeners.
  - Repair broken dependencies/bindings for broker endpoint.
  - Restart affected services and verify successful VDA registration recovery.

### 3) Pool-02 controller assignment/configuration drift causing VDAs to prefer an unavailable controller

Why it fits the evidence:
- Pool-01 is healthy and served by dc-vdi-01, but Pool-02 shows large-scale unregistration.
- If Pool-02 VDAs are pinned/prefer dc-vdi-02 or have stale registration lists, failures can persist even with another healthy controller in site.
- This would amplify outage impact when one controller endpoint is down.

Fastest check to confirm or eliminate:
- Compare VDA controller registration list/policy for Pool-02 vs Pool-01.
- Verify whether Pool-02 VDAs can and do register against dc-vdi-01 when dc-vdi-02 is unavailable.

Specific remediation if confirmed:
- Standardize VDA registration configuration:
  - Ensure both controllers are in registration lists/policies.
  - Remove stale controller references.
  - Apply policy/registry correction and recycle VDA registration service.

## Error Code Meaning Confidence Statement

- Confirmed from provided data only: the broker error is recorded as error 1030 with text "No machines available in the desktop group".
- Additional product-version-specific interpretation of numeric code 1030 is not asserted here.

## Finalized Working Hypothesis

Primary hypothesis selected: Cause 1.

Statement:
- Session launch failures are primarily driven by Broker Service unavailability on dc-vdi-02 (stopped service in an update/reboot-pending state), resulting in mass VDA unregistration in Pool-02 and broker inability to allocate machines.

## Exact Remediation Steps

1. Open incident bridge and declare controlled remediation window.
2. Confirm no concurrent maintenance on dc-vdi-01.
3. On dc-vdi-02, capture pre-change evidence:
   - Service state for Citrix Broker Service.
   - Last update/reboot-required flags.
4. Reboot dc-vdi-02 to complete pending update cycle.
5. After boot, verify:
   - Citrix Broker Service startup type = Automatic.
   - Citrix Broker Service status = Running.
6. If service does not auto-start, start it and review immediate application/system logs for startup errors.
7. Validate controller endpoint reachability from sample Pool-02 VDAs.
8. Trigger VDA registration refresh (or restart Desktop Service on sample VDAs if required by runbook).
9. Monitor Pool-02 catalog registration until recovered to operational baseline.
10. Re-test user launch in Pool-02 and confirm broker no longer returns timeout/1030 for affected cohort.

## Correct Order of Operations

1. Stabilize unaffected service path (keep dc-vdi-01 untouched and healthy).
2. Evidence capture on dc-vdi-02 before changes.
3. Complete pending reboot on dc-vdi-02.
4. Service post-boot validation and repair if needed.
5. Connectivity validation from VDAs.
6. Registration recovery actions.
7. Functional launch validation.
8. Sustained monitoring period.

## Verification Checks After Remediation

Required checks:
- Controller checks:
  - dc-vdi-02 Broker Service Running continuously.
  - No immediate recurring service stop events.
- Registration checks:
  - Pool-02 registered machines rise materially from 3 toward expected baseline.
  - Unregistered count falls from 22.
- User experience checks:
  - Test launches in Pool-02 succeed without timeout.
  - No new "error 1030 'No machines available in the desktop group'" entries for test users.
- Comparative control check:
  - Pool-01 remains stable during and after remediation.

Success criteria:
- Pool-02 registration restored to normal operating level and launch success rate returned for impacted users.

## Preventive Action (Single Highest-Value)

Implement controller post-patch reboot-and-service validation automation:
- After any Windows update on Delivery Controllers, enforce a timed reboot window.
- Run automated health probe that verifies Broker Service is Running and endpoint is reachable before ending change.
- Alert operations if service is stopped or endpoint check fails.

