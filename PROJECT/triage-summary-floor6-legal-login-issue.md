# summary (one line)
Monday morning: Floor 6 users report login failures or extremely slow login performance following Friday’s document management app rollout (to confirm linkage).

# Impact (who/how many/ business urgency)
- Who: FinBridge Floor 6 (Legal), recently migrated to Win11 and enrolled in Intune.
- How many: "At least a dozen" affected users; floor population is 45 (exact impacted count to confirm).
- Business urgency: High, because Legal users are unable to log in or face severe delays, disrupting core business access.

# Know facts
- Issue reported on Monday morning.
- Affected area: FinBridge Floor 6 (Legal).
- Floor size: 45 users.
- Environment: Recently migrated to Win11 and enrolled in Intune.
- Change event: New document management app rolled out Friday afternoon to that floor.
- Symptom: At least a dozen users cannot log in, or login takes "forever."
- Scope and root cause are not yet confirmed.

# Missing Information to gather
- Exact number of affected users and whether impact is growing (to confirm).
- Login failure details: error messages/codes vs pure slowness (to confirm).
- Whether issue occurs at Windows sign-in, app sign-in, or both (to confirm).
- Whether affected users are all on Floor 6 only, or broader (to confirm).
- Whether unaffected Floor 6 users share different device model/build/policy status (to confirm).
- Exact timeline per user: first occurrence and whether it started before/after app deployment (to confirm).
- Intune/device compliance status and recent policy/app install status on affected devices (to confirm).
- Network/VPN dependency at login time (to confirm).
- Any common pattern: specific teams, device types, or account types (to confirm).

# Likely catagory
- Major incident candidate: Authentication / endpoint performance degradation after recent change (to confirm).
- Possible categories for routing: Endpoint Management (Intune), Identity/Access, Application Deployment.

# suggest first diagnostic step
- First step: Correlate affected users with Friday app deployment status by checking a small sample of affected vs unaffected Floor 6 devices in Intune (install success, timing, and policy state), then confirm whether failures are Windows login, app login, or both.
