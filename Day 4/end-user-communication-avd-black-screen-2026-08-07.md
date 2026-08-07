## Audience 1 - Non-technical executive
Your access and data are safe. Around 07:00, after a 02:00 overnight update, about 40% of users in one virtual desktop group saw a black screen after sign-in, while the comparison group was unaffected. We found the updated image included a display component that caused desktop startup failures, corrected the image, and confirmed stable sign-ins. If you see a black screen, reconnect once, then contact the Service Desk.

## Audience 2 - Affected end-user team
Your access and data are safe. Around 07:00, after a 02:00 overnight update, about 40% of users in one virtual desktop group saw a black screen after sign-in because the updated image included a display component that caused desktop startup failures, while the comparison group was unaffected. We corrected the image and confirmed stable sign-ins. If this happens to you, reconnect once. Contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note
Access and user data were safe; impact was session presentation only.

Root cause:
- Updated POOL-FIN-01 image introduced a graphics/display component regression causing post-login desktop startup failures and black screen behavior.

Config detail:
- Affected pool: POOL-FIN-01.
- Unaffected control pool: POOL-FIN-02.
- Timing: image update at 02:00; user impact started around 07:00.
- Scope: about 40% of users in POOL-FIN-01.

Exact action taken:
- Redirected/drained new sessions away from affected POOL-FIN-01 capacity toward unaffected capacity.
- Corrected the updated image component responsible for display-path failure.
- Reintroduced corrected image for sign-in flow.

Verification step:
- Re-tested user sign-ins after image correction.
- Confirmed stable sign-ins and no repeat black-screen behavior.

Preventive action needed:
- Keep a release gate for future image updates with canary sign-in validation before broad rollout.
- Block promotion if black-screen/session-start display failures appear.

User instruction on recurrence:
- Reconnect once, then contact the Service Desk.
