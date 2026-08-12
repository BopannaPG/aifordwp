# Microsoft 365 Copilot Readiness Checklist — Finance (High Sensitivity)
Date: 2026-08-12
Owner: DWP Engineering
Department scope: Finance (~200 users)
Data profile: Payroll, board packs, M&A documents, client financial data
Current state: M365 E5 assigned to all users; Copilot add-on not yet assigned; SharePoint permissions inherited from 2019 migration and never fully audited

## How to Use This Checklist
- Tick each item only when evidence exists (report, screenshot, sign-off, or exported control result).
- Do not assign Copilot add-ons until all "Priority 0" items are complete and signed off.
- For this department, permissions and oversharing controls are the primary risk gate.

## Priority 0 (Must Complete First): Permissions and Oversharing Risk Gate

### 0.1 SharePoint and OneDrive Access Baseline (Highest Priority)
- [ ] Export current membership for all Finance SharePoint sites, M365 groups, and Teams-connected sites.
- [ ] Identify data-critical locations and map owners for each:
  - [ ] Payroll repositories
  - [ ] Board pack repositories
  - [ ] M&A workspaces
  - [ ] Client financial document libraries
- [ ] Confirm each site/library has at least 2 accountable business owners (primary + backup).
- [ ] Confirm inheritance status for each critical library/folder and document where inheritance is broken.
- [ ] Identify orphaned groups, stale owners, and legacy migration-era groups from 2019 cutover.

### 0.2 Oversharing Discovery and Remediation (Highest Priority)
- [ ] Run tenant-level and Finance-scoped checks for:
  - [ ] "Everyone except external users" access
  - [ ] Anonymous or anyone links
  - [ ] Organization-wide links on high-sensitivity libraries
  - [ ] Broadly shared links with no expiry
  - [ ] Files/folders shared directly to users outside Finance without business justification
- [ ] Produce a remediation list ranked by risk (Critical, High, Medium).
- [ ] Remove or narrow high-risk access grants before Copilot enablement.
- [ ] Replace broad links with least-privilege sharing (named users/groups, expiry, and review date).
- [ ] Validate no unresolved Critical oversharing findings remain.

### 0.3 Access Governance Controls (Highest Priority)
- [ ] Apply least-privilege model for all high-sensitivity libraries.
- [ ] Enforce owner review cadence (at minimum quarterly) for Finance critical repositories.
- [ ] Define and publish an exception process for temporary elevated access.
- [ ] Obtain Security + Compliance + Finance leadership sign-off that permissions posture is acceptable for Copilot pilot.

## Priority 1: Licensing Prerequisites
- [ ] Confirm 200/200 Finance users have eligible base licenses (M365 E5 confirmed).
- [ ] Confirm no blocked accounts, suspended users, or guest-only identities in pilot candidate list.
- [ ] Procure/assign Microsoft 365 Copilot add-on only after Priority 0 sign-off.
- [ ] Stage assignment by pilot ring (for example: 20 to 30 users first, then phased expansion).
- [ ] Document rollback method for add-on assignment if risk posture changes.

## Priority 2: Microsoft 365 Apps Client Readiness
- [ ] Confirm Microsoft 365 Apps for enterprise is deployed to all pilot users.
- [ ] Confirm update channel is supported and consistent for pilot users.
- [ ] Confirm Office desktop clients are on a supported, current build (Word, Excel, PowerPoint, Outlook, Teams).
- [ ] Verify modern auth is enabled and legacy auth dependencies are removed where possible.
- [ ] Validate pilot devices meet performance baseline for Office apps (startup, sign-in, save/sync behavior).

## Priority 3: Identity and MFA Readiness
- [ ] Confirm MFA is enforced for all Finance users (no standing exclusions without documented exception).
- [ ] Confirm Conditional Access policies are active for Finance access to M365 resources.
- [ ] Review and remove risky sign-in exclusions and legacy authentication paths.
- [ ] Confirm privileged/admin accounts are separate from day-to-day user identities.
- [ ] Validate account lifecycle hygiene (joiners, movers, leavers) for Finance groups and site access.

## Priority 4: Sensitivity Labels and Data Protection
- [ ] Define or validate sensitivity labels for Finance data classes:
  - [ ] Payroll
  - [ ] Board/Executive
  - [ ] M&A/Deal
  - [ ] Client Confidential Financial
- [ ] Confirm labels are published to Finance users and available in Office apps.
- [ ] Apply default labels or recommended labeling policies for high-risk locations.
- [ ] Validate encryption and access restrictions for highest sensitivity labels.
- [ ] Run sample tests: create, share, and open labeled files across approved and non-approved users.

## Priority 5: End-User Communications and Enablement
- [ ] Send pre-launch communication to Finance explaining:
  - [ ] What Copilot can and cannot access (it respects existing permissions)
  - [ ] Why permissions remediation was required before rollout
  - [ ] Data handling expectations for sensitive content
- [ ] Deliver a 30-minute role-specific training for pilot users (Finance examples only).
- [ ] Publish "do/don't" usage guide with approved prompts and prohibited scenarios.
- [ ] Provide a clear support path (Service Desk queue + escalation route).
- [ ] Collect week-1 pilot feedback and incidents; feed results into phase-2 go/no-go decision.

## Go/No-Go Gate (Before Copilot Add-On Assignment)
- [ ] Priority 0 completed with documented evidence.
- [ ] No open Critical oversharing findings.
- [ ] Security, Compliance, and Finance owner sign-off captured.
- [ ] Pilot user list approved and communicated.

If any item above is not complete, status remains NO-GO for Copilot add-on assignment in Finance.
