# Leadership Update — Finance Data Access, Permissions, and Copilot Readiness
Date: 2026-08-12
Audience: Non-technical management

## Executive Summary
Finance supports approximately 200 users and handles highly sensitive information, including payroll records, board packs, M&A material, and client financial data stored on shared drives. Current SharePoint permissions were inherited during the 2019 migration and have not had a full audit since. This creates a material risk of over-permissioned access and inconsistent data boundaries. Microsoft 365 E5 licensing is already in place for all 200 users, which means the core security and compliance tooling required for remediation is available now. Copilot add-on licensing has not yet been assigned.

## Current Risk Position
The highest immediate risk is not platform availability; it is access governance drift over time. In practical terms, that means users may still have access they no longer need due to inherited groups, legacy site structures, and undocumented exceptions from the migration period. For high-impact data classes, this is a governance and audit concern and should be treated as a priority control gap.

## What This Means for Copilot
Copilot will honor existing Microsoft 365 permissions. If legacy access is broader than intended, Copilot can surface content according to those same permissions. For this reason, assigning Copilot add-ons before a permissions clean-up would increase data exposure risk. The safe sequence is:

1. Confirm and remediate access controls.
2. Validate with business data owners.
3. Assign Copilot add-ons in a phased model.

## Recommended 30-Day Plan
1. Week 1: Launch a focused Finance permissions audit across SharePoint sites and connected groups, with priority on payroll, board, M&A, and client folders.
2. Week 2: Remove stale and excessive access, standardize owner accountability per site/library, and document approved exceptions.
3. Week 3: Run a control validation checkpoint with Finance leadership, Legal/Compliance, and Security.
4. Week 4: Begin limited Copilot pilot for a small, manager-approved user cohort after sign-off.

## Decisions Needed from Leadership
1. Approve the Finance permissions audit as a priority security and governance activity this month.
2. Confirm that Copilot add-on assignment remains paused until post-remediation sign-off.
3. Nominate Finance data owners for payroll, board content, M&A workspaces, and client financial repositories.

## Success Criteria
1. All Finance high-sensitivity repositories have validated owners and reviewed membership.
2. Legacy inherited permission exceptions are either removed or formally approved.
3. Copilot rollout starts only after documented control validation.

This approach reduces data exposure risk while preserving momentum for Finance productivity improvements.
