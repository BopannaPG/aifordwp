# Detailed RCA: Floor 6 Legal Login Degradation Incident (Final)

## 1. Finalized single hypothesis
The Friday afternoon rollout of the new document management app to FinBridge Floor 6 introduced a login-path degradation/failure condition on a subset of Win11 Intune-managed devices.

Status: Finalized as the primary operational hypothesis based on available evidence.
Technical sub-cause: To confirm with endpoint/app telemetry.

## 2. Why this hypothesis is selected
- A known change occurred before impact (Friday rollout).
- Impact was reported Monday morning in the same floor cohort that received the change.
- Symptom profile (login failure for some users, severe delay for others) is consistent with startup/login component side effects.

## 3. Supporting evidence
### Confirmed facts from incident scope
- Location/group: FinBridge Floor 6 (Legal), 45 users.
- Environment: Recently migrated to Windows 11 and enrolled in Intune.
- Change event: New document management app rolled out Friday afternoon to that floor.
- Incident report: Monday morning, at least a dozen users cannot log in or login takes a very long time.

### Evidence quality notes
- Error codes were not provided.
- Exact failure point (Windows sign-in vs app sign-in vs both) is to confirm.
- Exact affected count beyond "at least a dozen" is to confirm.

## 4. Timeline
- Friday afternoon: Document management app rollout to Floor 6 Legal.
- Monday morning: Service desk receives reports of login failures and severe delays from at least a dozen users.
- Current analysis point: Change-correlated app impact selected as primary hypothesis and rollback-first mitigation approach finalized.

## 5. Exact remediation steps to resolve
1. Pause/stop further deployment of this app to Floor 6 immediately.
2. Create and validate affected-user/device targeting group in Intune.
3. Execute rollback on affected endpoints:
   - Uninstall the app, or
   - Disable its startup component/service if uninstall cannot be immediate.
4. Force Intune sync on targeted devices.
5. Perform restart or sign-out/sign-in cycle for targeted users.
6. Re-test login success and login time on a pilot subset.
7. If pilot passes, expand rollback/remediation to all affected users.
8. Hold re-deployment until fixed app build/config is validated.

## 6. Correct order of operations
1. Incident communication and containment announcement.
2. Deployment freeze for the app on Floor 6.
3. Affected cohort confirmation and Intune targeting.
4. Rollback/disable startup component on targeted devices.
5. Intune sync and endpoint restart/sign-in refresh.
6. Pilot verification (functional + performance).
7. Full remediation rollout to remaining affected users.
8. Controlled reintroduction in staged rings only after fix validation.

## 7. Verification checks after remediation
### Resolution checks
- Functional: Previously affected users can complete login successfully.
- Performance: Login duration returns to expected baseline (baseline value to confirm).
- Scope stability: No new Floor 6 cases during agreed observation window (duration to confirm).
- Configuration state: Intune confirms rollback/disable state on targeted endpoints.

### Exit criteria
- All currently affected users restored.
- No new incident reports in the observation window.

## 8. 5 Whys analysis
1. Why were users unable to log in or experiencing severe delays?
   - Login flow degraded or stalled on affected devices.
2. Why did login flow degrade/stall?
   - A recently introduced component likely interfered with startup/login path execution.
3. Why was that component introduced?
   - A new document management app was deployed to this cohort on Friday.
4. Why was the issue not caught before broad impact?
   - Pre-rollout validation and phased post-deployment monitoring were insufficient (to confirm exact control gap).
5. Why did one rollout create significant business impact?
   - Blast-radius controls and rollback gating were not strict enough for this cohort (to confirm process specifics).

## 9. Preventive action to stop recurrence
1. Enforce deployment rings: IT pilot, small business pilot, then controlled floor rollout.
2. Add mandatory login performance smoke test before broad deployment approval.
3. Require tested rollback/uninstall path as a release gate.
4. Add first-business-morning monitoring checkpoint after major endpoint app changes.
5. Avoid broad Friday afternoon rollouts for high-impact business cohorts.

## 10. Error code statement
No error codes were provided in the shared incident data. Therefore, no error-code meaning is confirmed in this RCA.
Any later error-code interpretation must be validated against authoritative Microsoft or vendor documentation.
