# Structured Triage Summary

## Summary (one line)
Ticket T-1004 reports a company app fails to install from Company Portal with error 0x87D1041C.

## Impact (who/how many/business urgency)
- Who is affected: Reported user/device attempting install (to-verify).
- How many affected: One reported case (to-verify if broader).
- Business urgency: Potential block if the app is required for daily role tasks (urgency to-verify).

## known facts
- Ticket reference: T-1004.
- Install source: Company Portal.
- Reported outcome: App install fails.
- Reported code: 0x87D1041C.

## Missing information to gather
- Exact app name/version and assignment scope.
- Whether failure occurs on one device only or multiple devices.
- Whether other Company Portal apps install on the affected device.
- Device enrollment/compliance state at failure time (to-verify).
- Network context during install attempt (to-verify).
- Exact timestamp and repeatability of the failure.
- Any additional message text shown with the error code.

## likely catagory
- Endpoint Management / Company Portal App Deployment Failure (to-verify).

## First diagnostic step
- Verify whether the same app installs successfully for another assigned device/user, then check the affected device’s assignment and compliance state to separate app-scope from device-specific deployment issues (to-verify result).
