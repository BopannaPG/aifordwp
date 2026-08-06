Summary: Company Portal app installs are showing failed with error 0x87D1041C due to a detection-rule mismatch after an app version bump. Impact: all devices assigned the app after the version bump, broad deployment impact, moderate to high user disruption. Known facts: failure appears in Company Portal with 0x87D1041C; cause identified as outdated detection rule; scope affects all newly assigned devices post-bump; manual IT reinstall works but is not user-fixable; permanent fix is to update detection rule and redeploy. Missing info: exact start time of failures, total affected device count, whether any app assignments are unaffected, and redeploy completion/validation status (to confirm). Likely category: Intune application packaging/detection-rule configuration issue. First step: validate current detection-rule criteria against the deployed app version and trigger controlled redeploy to confirm install success.
---
Refere @file:prompt-library.md which contains prompt templates with examples . using Triage prompt write a Triage for "Company Portal app install failures (0x87D1041C) traced to an
outdated detection rule after an app version bump."
Known-error record:
  Symptom: App shows 'failed' in Company Portal, error 0x87D1041C.
  Cause: Detection rule not updated for new app version.
  Scope: All devices assigned the app after the version bump.
  Workaround: Manually reinstall via IT; not user-fixable.
  Permanent fix: Update detection rule to match new version, redeploy.