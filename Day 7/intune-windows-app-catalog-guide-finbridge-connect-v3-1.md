# Intune Guide: Add a Windows App to the App Catalog Before Phased Rollout

## Purpose
Use this runbook to add a Windows app to Intune and validate it before any broad deployment. This guide uses **FinBridge Connect v3.1** as the worked example.

- Package type: `.intunewin` (Windows LOB/Win32-style package)
- Install command: `FinBridgeConnect_Setup.exe /silent`
- Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
- Detection method: Registry value
- Registry path/value: `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`

## Prerequisites
1. You have Intune admin rights sufficient to create and assign apps.
2. You have the packaged app file available: `FinBridgeConnect_v3.1.intunewin` (filename can vary).
3. You have a pilot Entra ID group ready (recommended: small controlled set of test devices/users).
4. You have one reachable test endpoint enrolled in Intune.

## 1. Where to Add the App in Intune
1. Open the Intune admin center.
2. Go to **Apps** -> **All apps** -> **Create** (some tenants show **Add** instead).
3. In the app type picker, choose the correct type:
   1. **Windows LOB/Win32 app using a `.intunewin` package**: select **Windows app (Win32)** (shown under **Other** in many tenants).
   2. **Microsoft Store app**: choose the Microsoft Store app option (new or legacy wording depends on tenant).
   3. **Web link**: choose **Web link** or **Windows web link** based on whether you need a generic link or Windows-scoped link.
4. After selecting the app type, click **Select** to start the app creation wizard.

> UI label warning: Exact menu labels and app-type names vary across Intune tenant versions and portal updates. Verify each label live in your tenant before proceeding, and select the option matching the artifact you are onboarding.

## 2. Create the LOB Windows App (FinBridge Connect v3.1)
1. On the app creation flow (after **Windows app (Win32)** -> **Select**), upload `FinBridgeConnect_v3.1.intunewin`.
2. Complete **App information**:
   1. Name: `FinBridge Connect`
   2. Description: `FinBridge Connect desktop client v3.1`
   3. Publisher: `FinBridge`
   4. Version: `3.1`
   5. On the same screen, leave optional fields blank unless your process requires them (Category, Information URL, Privacy URL, Developer, Owner, Notes, Logo).
   6. Keep **Show this as a featured app** set to **No** for pilot unless you intentionally want it highlighted in Company Portal.
   7. Click **Next** to move to the **Program** page.
3. Complete **Program**:
   1. Install command: `FinBridgeConnect_Setup.exe /silent`
   2. Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
   3. Install behavior: choose **System** unless the vendor explicitly requires per-user context.
   4. Click **Next**.
4. Complete **Requirements**:
   1. Operating system architecture: select target architecture (for example x64 only, or x64 + x86 if supported).
   2. Minimum OS version: set according to supported baseline (for example Windows 10/11 minimum build used in your estate).
   3. Click **Next**.
5. Configure **Detection rules** so Intune can confirm installation:
      1. On the **Detection rules** page, set **Rules format** to **Manually configure detection rules** if that selector is shown in your tenant UI.
      2. Click **Add** to open the rule details pane or dialog.
      3. In the add-rule pane, set **Rule type** to **Registry**.
      4. Key path: `HKLM\SOFTWARE\FinBridge\Connect`
      5. Value name: `Version`
      6. Detection method: String or version comparison as supported in your UI.
      7. Expected value: `3.1`
      8. Save the detection rule, then click **Next**.
6. On **Dependencies**, leave the list empty for this first pilot unless the app requires a prerequisite application, then click **Next**.
7. On **Supersedence**, leave it empty for this first pilot unless you are replacing an older managed app, then click **Next**.
8. On **Assignments**, choose the correct section in the wizard page:
   1. **Required**: use this when Intune should install the app automatically.
   2. **Available for enrolled devices**: use this when the app should appear in Company Portal for optional self-service install.
   3. **Uninstall**: use this when Intune should remove the app from the targeted scope.
   4. Use **Add group** to target a pilot Entra ID group. The UI may also offer **Add all users** and **Add all devices**, but do not use those for initial rollout.
   5. Confirm the selected assignment appears in the correct section, then click **Next**.
9. On **Review + create**, verify the configuration and create the app.

> UI label warning: In many tenants, the **Detection rules** page first shows **Rules format** and only shows **Rule type** after you click **Add** to create a detection rule. In the UI shown here, the next wizard pages are **Dependencies**, **Supersedence**, **Assignments**, and **Review + create**; a separate **Return codes** page is not shown.

> Assignment UI note: In the UI shown here, the assignment page is split into **Required**, **Available for enrolled devices**, and **Uninstall** sections, each with actions such as **Add group**, **Add all users**, and **Add all devices**. The page also warns that retiring a device does not automatically remove a Win32 app from the device.

## 3. Assignment Basics (Pilot First)
1. Use the **Assignments** step in the creation wizard, or open the newly created app and go to **Assignments** after creation.
2. Add assignment(s) using the correct intent:
   1. **Required**: Intune installs automatically for targeted users/devices.
   2. **Available for enrolled devices**: app is offered in Company Portal for optional self-service install.
   3. **Uninstall**: Intune removes the app from targeted users/devices.
3. Prefer **Add group** and select a small pilot Entra ID group for the first deployment.
4. Do not use **Add all users** or **Add all devices** on first release.
5. Validate pilot results, then expand in phases.

Why pilot first:
1. Reduces blast radius if detection, requirements, or commands are incorrect.
2. Catches environment-specific issues (permissions, dependencies, conflicts).
3. Provides real telemetry before broad rollout.
4. Allows controlled rollback/uninstall if needed.
5. Avoids broad assignment from one-click options such as **Add all users** or **Add all devices**.

> UI label warning: Assignment panes and wording can differ by tenant. In the UI shown here, use the visible sections and verify the assignment lands under the correct one before saving.

## 4. Verification Steps
1. Confirm app appears correctly in catalog:
   1. Go to **Apps** -> **All apps** and search for `FinBridge Connect`.
   2. Verify publisher/version metadata shows expected values.
2. Confirm assignment is applied to the pilot group:
   1. Open app -> **Assignments**.
   2. Verify the intended group is included under the correct assignment type.
3. Check install status from Intune:
   1. Open app -> **Device install status** (or equivalent status blade in your tenant).
   2. Review per-device state for pilot devices.
4. Validate on a pilot endpoint:
   1. Trigger Company Portal sync or device sync.
   2. Confirm app installs silently.
   3. Validate registry detection value exists: `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`.

Status interpretation:
1. **Installed**: Intune detection rules matched; app is considered present.
2. **Failed**: install command returned an error or detection did not match after install attempt.
3. **Not applicable**: device/user did not meet assignment scope or requirement filters (for example OS version/architecture mismatch).

> UI label warning: Status blade names and wording (for example "Device install status" vs similar variants) can differ by tenant/version. Use the status view that reports per-device app deployment results.

## 5. Completion Criteria Before Rollout Phase 1
1. App record exists with correct metadata.
2. Program commands are validated.
3. Detection rule confirms `Version = 3.1` in registry.
4. Dependencies and supersedence are intentionally left empty or configured as required.
5. Pilot assignment is active.
6. Pilot devices report expected state with no critical failures.

If all criteria are met, proceed to phased expansion (for example 1%, 10%, 25%, then broad deployment) under change control.
