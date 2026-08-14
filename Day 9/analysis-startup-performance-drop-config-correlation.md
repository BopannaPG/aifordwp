# Detailed Analysis - Startup Performance Drop (Config-Correlation Focus)

## Scope Facts Used
- Affected group shows a startup-performance drop.
- A configuration change was applied to the affected group before the drop.
- A comparison (unaffected) group had no configuration change.
- The unaffected group did not show the same startup-performance degradation.

## Correlation Logic (Timing + Comparison Group)
- Temporal correlation is strong: the degradation appears after the config change window.
- Counterfactual comparison is strong: a similar group without the config change did not degrade.
- This makes config-linked causes substantially more likely than broad platform, network, or random environmental causes.

## Ranked Most Likely Causes (Most Probable First)

### 1) Misconfigured or overly heavy startup policy introduced by the new config (Most likely)
Why it fits timing and unaffected-group evidence:
- The startup slowdown starts after the config rollout window.
- The unchanged comparison group remains stable, which strongly isolates the changed variable to configuration.
- Startup performance is directly sensitive to startup scripts, synchronous policy tasks, login processing order, and blocking checks that can be unintentionally introduced by config changes.

Fastest check to confirm or eliminate:
- Immediately rollback or disable only the newly changed startup-related config for a small pilot subset of affected devices (for example 5-10).
- Compare next login/startup duration versus unaffected group and versus affected devices still on changed config.
- If startup times recover quickly in pilot, this cause is confirmed with high confidence.

### 2) Config change triggered new startup-time dependency waits (service/network/resource checks)
Why it fits timing and unaffected-group evidence:
- A config may enable startup tasks that wait on external dependencies (service readiness, network location, certificate lookup, profile mount, endpoint checks).
- Timing fits because dependency waits begin only after the config is active.
- Unaffected group behavior supports this: without config activation, no added dependency waits and no comparable slowdown.

Fastest check to confirm or eliminate:
- Capture startup trace/log samples from affected vs unaffected devices and isolate added wait states introduced post-change.
- Look for repeated timeout or long-duration stages tied to newly enabled startup tasks.
- Temporarily bypass the suspected dependency check in a pilot to see if startup normalizes.

### 3) Config-scoping or assignment logic error causing an over-broad startup workload in affected group
Why it fits timing and unaffected-group evidence:
- If the change targeted affected devices with incorrect scoping or precedence, they may process extra startup items not intended for their profile.
- Timing still aligns to rollout.
- Comparison group not changed is consistent with a scope/assignment issue isolated to changed collections.

Fastest check to confirm or eliminate:
- Audit effective policy/resultant set for both groups and diff startup-related settings, script order, and enforcement mode.
- Validate assignment filters, include/exclude logic, and precedence order introduced in the same change set.
- If affected devices show unintended extra startup payload vs unaffected, this cause is confirmed.

## Why This Ranking Weights Config Change Heavily
- The strongest evidence pattern is: change happened, then symptom appeared, while no-change cohort remained stable.
- In incident analysis terms, this is a high-quality natural control.
- Therefore, direct config-content issues rank above generic infrastructure causes.

## Immediate Validation Sequence (Fastest Path)
1. Pilot rollback of new startup-related config on a small affected subset.
2. Measure next-login startup duration before/after rollback.
3. If improved, expand rollback and proceed with config fix.
4. If not improved, run startup trace diff focused on dependency waits and assignment scope.

## Analyst Note
This document is intentionally scoped to likelihood ranking and fast confirmation checks, using the config timing and unaffected comparison group as primary weighting evidence.