# Microsoft 365 Copilot Readiness Tiering — Finance (200 Users)
Date: 2026-08-12
Source checklist: Copilot readiness checklist for Finance
Audience: DWP engineering, Security, Compliance, Finance leadership

## Tier 1 — MUST Complete Before Rollout (Blocking)

### 1) Permissions and Oversharing Risk Gate (SharePoint/OneDrive)
- Complete a full Finance access baseline across sites, libraries, groups, and shared links.
- Identify and remediate overexposed access patterns (for example: Everyone except external users, org-wide links, stale direct shares, legacy migration groups).
- Validate data-critical repositories (payroll, board packs, M&A, client financial data) have named accountable owners and least-privilege membership.
- Close all Critical oversharing findings and secure leadership sign-off (Security + Compliance + Finance).

Why this is blocking:
- Copilot enforces existing permissions. If permissions are wrong, Copilot will still surface content to whoever currently has access.
- Inherited permissions from a 2019 migration that were never audited create a high probability of hidden over-permissioning.
- For Finance data classes, the impact of a permission mistake is severe (regulatory, legal, confidentiality, and reputational risk).
- This is a risk-multiplying control: one unresolved access issue can expose many sensitive files at once.

### 2) Identity and MFA Baseline
- Enforce MFA for all Finance users with no unapproved standing exclusions.
- Validate Conditional Access policy coverage for Finance access paths.
- Remove risky legacy authentication routes and high-risk sign-in exceptions.

Why this is blocking:
- Copilot access inherits the user identity context.
- Weak identity controls allow account compromise to become immediate data exposure.

### 3) Minimum Licensing Gate (Readiness to Enable)
- Confirm all target users have eligible base licensing (M365 E5 already confirmed).
- Keep Copilot add-on assignment blocked until permissions gate is signed off.

Why this is blocking:
- Users cannot be enabled without the required license state.
- However, licensing alone is not a safety control and does not reduce oversharing risk.

## Tier 2 — SHOULD Complete Before Rollout (High Risk if Skipped)

### 1) Microsoft 365 Apps Client Version and Channel Consistency
- Verify Microsoft 365 Apps for enterprise is deployed for pilot users.
- Confirm Office apps are on supported current builds and update channels are consistent.
- Validate modern auth and baseline client health (startup, sign-in, save/sync).

Risk if skipped:
- Increased support incidents, inconsistent Copilot behavior, degraded pilot confidence.
- Not usually a direct data exposure issue, but can materially affect adoption and service quality.

### 2) Sensitivity Label Operational Readiness
- Confirm required Finance labels are published and usable in Office apps.
- Validate encryption/restriction behavior for highest sensitivity labels.
- Perform sample share/open tests for approved vs non-approved users.

Risk if skipped:
- Reduced policy enforcement quality and weaker user guidance for sensitive handling.
- Existing access controls still do most of the heavy lifting, but labeling maturity improves defense in depth.

## Tier 3 — CAN Complete During/After Rollout (Lower Risk)

### 1) End-User Comms and Enablement Expansion
- Deliver broader communications after initial pilot launch.
- Extend role-specific training and scenario playbooks iteratively.
- Refine do/don't guidance based on real pilot incidents and FAQ trends.

Risk if delayed:
- Slower adoption and more avoidable support queries.
- Lower immediate security risk than unresolved permissions oversharing.

### 2) Pilot Optimization and Wave Tuning
- Tune ring sizes and rollout pacing using week-1 and week-2 telemetry.
- Improve support routing and escalation runbooks.

Risk if delayed:
- Operational inefficiency, not usually a direct confidentiality exposure.

## Why Permissions/Oversharing Is MUST in Finance (Even if Licensing and Client Checks Are Simpler)
Licensing and client version checks are technically straightforward because they are mostly deterministic inventory tasks: either a user has the correct SKU, and either a device is on a supported build or not. Those checks are necessary, but they do not validate who can see sensitive data.

Permissions and oversharing validation is harder but mission-critical because it addresses the core confidentiality risk. In this Finance context, data includes payroll, board packs, M&A content, and client financial information, and permissions have been inherited from a legacy 2019 migration with no full audit. That combination creates elevated likelihood and high impact of overexposure. Copilot does not fix that; it follows it. Therefore, permissions and oversharing remediation is the true go/no-go control, while licensing and client readiness are enablement prerequisites.

## Recommended Rollout Gate Statement
Copilot add-on assignment for Finance remains blocked until Tier 1 completion evidence is recorded and approved by Security, Compliance, and Finance data owners.
