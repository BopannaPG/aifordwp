Resolved. Cause: detection rule was not updated after the app version bump, causing Company Portal install failures with error 0x87D1041C. Action: updated the detection rule to match the new app version and redeployed the app; affected users were supported with manual IT reinstall where required. Preventive: add a detection-rule verification step to the app version release process.
---
Refere @file:prompt-library.md which contains prompt templates with examples . using closure notes prompt write a closure notes communication for "Company Portal app install failures (0x87D1041C) traced to an
outdated detection rule after an app version bump."
Known-error record:
  Symptom: App shows 'failed' in Company Portal, error 0x87D1041C.
  Cause: Detection rule not updated for new app version.
  Scope: All devices assigned the app after the version bump.
  Workaround: Manually reinstall via IT; not user-fixable.
  Permanent fix: Update detection rule to match new version, redeploy.