# Leadership Update: Floor 6 Migration Experience

Date: 14/08/2026  
Status: Draft  
Audience: Leadership

## Executive Summary

The migration has largely worked for end users. Most people were able to continue their day-to-day work with no major disruption. A smaller group experienced problems soon after rollout, mainly related to access settings, sign-in delays, and missing desktop icons. These issues were disruptive but temporary. They were addressed quickly, and core business work has been restored.

## What Happened

After rollout, we saw a pattern of issues in one business area:

- Some users briefly saw information outside the work they should access.
- Some users had delays getting into their computers after a new app rollout.
- Some users could not see desktop icons even though their files were still present.

These were not random failures. They came from release controls that did not fully protect against settings reaching the wrong audience or being introduced too broadly too quickly.

## What Is Being Done

Immediate corrective actions are complete:

- Access settings were corrected so people can only see the work they are meant to handle.
- The app rollout that affected sign-in was stopped and user access returned to normal.
- The desktop visibility setting was corrected and icons were restored.
- Support teams were given clear user messaging so people could recover quickly with simple steps.

Stability actions now in motion:

- Changes are now staged through a smaller pilot first before wider rollout.
- Release checks are being tightened so group targeting is validated before changes go live.
- During rollout windows, we are increasing active oversight so warning signs are caught earlier.
- A formal go/no-go check is being added before a change is marked complete.

## What Remains Open

While service is stable, follow-through work is still open and important:

- Full automation of early warning checks is still being completed.
- Vendor-side follow-up is still open for the app behavior that slowed sign-in.
- Standardized release evidence and closure checks are being embedded across teams.
- Final governance updates are still being rolled into runbooks and operational checklists.

## Risk and Confidence

Current user-facing risk is lower than at incident start because fixes are in place and short-term controls are active. Longer-term risk reduction depends on completing the remaining automation and governance work. We are confident in current stability, and we are being deliberate about not expanding changes faster than controls can support.

## Leadership Ask

Support continued focus on controlled rollout speed over rapid rollout scale. This is the right tradeoff to protect business continuity, legal obligations, and user trust while we complete the remaining prevention work.

## Prevention Note (Specific Control)

**Control Name: Monday Morning Gate (MMG)**

No Friday business-hours rollout can move beyond a pilot group unless a mandatory Monday 08:00 access check is signed off by both the release engineer and service desk lead. The check requires proof that users only see their own work and that normal sign-in and desktop visibility are intact. If either reviewer cannot sign off, the rollout is automatically paused and the change is rolled back before business opening hours.
