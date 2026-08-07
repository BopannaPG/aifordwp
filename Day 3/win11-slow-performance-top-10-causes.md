1. High CPU usage from one or more processes
Why it causes slowness: When CPU stays near 90 to 100 percent, apps, browser tabs, and normal desktop actions queue up and respond slowly.
Fastest diagnostic check: Open Task Manager and sort by CPU to see if any process is consistently consuming high usage for several minutes.
Recommended resolution: End non-critical runaway processes, restart the device, and if recurring, patch or reinstall the offending app and escalate to endpoint engineering for known process issues.

2. Memory pressure and paging
Why it causes slowness: If RAM is heavily used, Windows relies on pagefile disk I O, which makes app launches and multitasking feel very slow.
Fastest diagnostic check: In Task Manager Performance tab, confirm memory utilization is persistently high and check for frequent hard faults or heavy Commit usage.
Recommended resolution: Close high-memory apps or browser sessions, disable unnecessary background tools, update memory-leaking applications, and plan RAM upgrade if baseline demand exceeds installed memory.

3. Too many startup and background applications
Why it causes slowness: Startup agents and resident tools consume CPU, RAM, and disk continuously, degrading overall responsiveness.
Fastest diagnostic check: Task Manager Startup tab and Processes tab to identify high-impact startup items and background apps with sustained resource use.
Recommended resolution: Disable non-essential startup items via policy-approved methods, remove unused software, and keep only required enterprise agents.

4. Low free disk space on system drive
Why it causes slowness: Windows performance drops when free space is low because temp files, updates, and pagefile operations cannot run efficiently.
Fastest diagnostic check: Check free space in Settings Storage or File Explorer; performance risk increases significantly when free space is below about 10 to 15 percent.
Recommended resolution: Run Storage Sense, clear temp files, remove large unnecessary local data, move user files to OneDrive or network storage, and enforce disk cleanup policy.

5. Disk bottleneck or early storage failure
Why it causes slowness: High disk active time or failing SSD HDD causes long waits for app opens, logon, and basic file operations.
Fastest diagnostic check: Task Manager Performance Disk for sustained high active time with low throughput, plus SMART or vendor health check if available.
Recommended resolution: Run disk health diagnostics, correct filesystem errors, replace failing drive under warranty, and restore image or data as needed.

6. Windows Update or feature servicing activity
Why it causes slowness: Update download, install, post-install maintenance, and indexing can temporarily consume CPU, disk, and network resources.
Fastest diagnostic check: Check Windows Update status for active install, pending restart, or recent feature update timing aligned with slowdown onset.
Recommended resolution: Allow update cycle to complete, reboot promptly, confirm update success, and schedule heavy update windows outside peak hours where possible.

7. Antivirus or endpoint security scan load
Why it causes slowness: Full scans and real-time inspection of large file activity can increase CPU and disk latency.
Fastest diagnostic check: Review endpoint protection console or local status for active full scans and correlate scan time with user complaint.
Recommended resolution: Let scheduled scan finish, tune scan exclusions per security policy for trusted high-I O paths, and stagger scan schedules across device groups.

8. Browser or network path delays
Why it causes slowness: Slow DNS, proxy issues, VPN congestion, or packet loss makes web and cloud-backed apps appear generally slow.
Fastest diagnostic check: Compare performance on and off VPN if policy allows, test name resolution and latency to key business endpoints, and check proxy auto-config behavior.
Recommended resolution: Fix DNS or proxy configuration, reconnect VPN, switch to healthy network path, and escalate persistent WAN issues to network operations.

9. Software conflict after recent change
Why it causes slowness: Newly installed apps, drivers, plugins, or updates can conflict with existing components and degrade system performance.
Fastest diagnostic check: Review recent installs and update history from last known good date, then perform a clean boot style isolation test under support procedure.
Recommended resolution: Roll back or uninstall the conflicting component, update to compatible version, and block problematic release in software deployment rings.

10. Thermal throttling or power profile constraints
Why it causes slowness: Overheating or restrictive power settings can reduce CPU frequency, making all tasks feel sluggish.
Fastest diagnostic check: Check CPU speed versus expected base clock during workload and verify power mode plus thermal indicators or fan behavior.
Recommended resolution: Set corporate approved balanced or performance power profile, clear vents and docks, update BIOS firmware, and replace failing fan or thermal components if needed.
