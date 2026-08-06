Root cause: Win11 upgrade removed legacy VPN client; Intune did not re-deploy new client due to detection-rule gap.
Action taken: manually removed stale VPN registry entries under HKLM\SOFTWARE\<vendor>; force-triggered Intune sync; new VPN client deployed; split-tunnel config applied.
Verification: confirmed connectivity to all internal subnets.
Data impact: no data loss.
Preventive action needed: fix/close Intune detection-rule gap so Win11-upgraded devices auto-trigger new VPN client re-deployment.
