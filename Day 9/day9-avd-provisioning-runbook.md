# Day 9 - Azure Virtual Desktop Provisioning Runbook

## Scope
This document captures the exact provisioning and remediation flow executed for the Windows 11 workplace migration AVD setup.

## Environment
- Subscription: `ef7e4b27-d453-4d40-807d-d288b309ffe0`
- Resource Group: `dwpai-lab-rg`
- Region: `eastus`
- Host Pool: `POOL-FIN-01`
- Workspace: `FinBridge-Workspace`
- Session Host VM: `vm-fin-avd-01`
- User assigned for access: `p36@zippyops.in`

## Pre-Check Performed
1. Verified signed-in identity and RBAC scope.
2. Confirmed identity had Owner role at subscription scope so role assignment operations were allowed.

## Provisioning Steps Followed
1. Installed/updated Azure CLI extension: `desktopvirtualization`.
2. Created network resources:
   - VNet: `vnet-fin-01`
   - Subnet: `snet-avd-01`
   - NSG: `nsg-fin-avd-01`
   - Public IP: `pip-fin-avd-01`
   - NIC: `nic-fin-avd-01`
3. Added RDP ingress rule on port 3389 (lab scope).
4. Created AVD host pool with required settings:
   - Pooled
   - BreadthFirst
   - Max session limit: 5
5. Confirmed Desktop app group: `POOL-FIN-01-Desktop`.
6. Created workspace `FinBridge-Workspace` and linked app group.
7. Created Windows 11 multi-session VM with:
   - Image: `MicrosoftWindowsDesktop:office-365:win11-24h2-avd-m365:latest`
   - Size: `Standard_B2ms`
   - Security: Trusted Launch + Secure Boot + vTPM
8. Enabled system-assigned identity on session host.
9. Installed `AADLoginForWindows` extension.
10. Generated host pool registration token.
11. Applied DSC extension (`Microsoft.Powershell/DSC`) to register session host with `aadJoin=true`.
12. Assigned roles to `p36@zippyops.in`:
   - `Virtual Machine User Login` on VM scope
   - `Desktop Virtualization User` on app group scope

## Incident Encountered and Root Cause
- Symptom: Web client showed gateway disconnect.
- Actual host status: `Unavailable`.
- Root causes discovered:
  1. Device join task was disabled (`Automatic-Device-Join`), causing `0x80041326`.
  2. Entra join failed with `error_hostname_duplicate` / `0x801c0083` due to an existing device object for hostname `finavdsh01`.

## Remediation Steps Followed
1. Enabled and executed `Automatic-Device-Join` task.
2. Verified join error from event logs and dsreg output.
3. Since directory object deletion permission was blocked, used workaround:
   - Renamed computer to `FINAVDSH99`.
   - Re-ran secure Entra join.
4. Re-validated AVD registration.
5. Final host status became `Available` with live heartbeat as `POOL-FIN-01/FINAVDSH99`.

## Output Artifacts (Day 9)
- `Day 9/avd-provision-day9.ps1`
- `Day 9/avd-remediate-gateway-disconnect.ps1`
- `Day 9/day9-avd-provisioning-runbook.md`

## Notes on Script Movement
No persistent scripts were created earlier in the workspace during execution; commands were run inline in terminal. Reusable scripts were created and stored directly under Day 9.
