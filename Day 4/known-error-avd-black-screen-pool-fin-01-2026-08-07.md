Symptom     : Users in POOL-FIN-01 see a blank or black screen immediately after login. For some users it clears after about 30 seconds; for others the session remains unusable or disconnects.

Cause       : The verified root cause is an image-linked graphics/render-path regression introduced by the 02:00 POOL-FIN-01 image update. On affected hosts, dwm.exe crashed in igdumd64.dll version 31.0.101.4146 with exception code 0xc0000005.

Scope       : About 40% of users on POOL-FIN-01 were affected starting around 07:00. POOL-FIN-02 was unaffected.

Workaround  : Stop directing new sessions to POOL-FIN-01, drain affected hosts, and prefer POOL-FIN-02 for new user sessions. This was the immediate containment used during the incident.

Permanent fix: Apply graphics/image remediation on POOL-FIN-01 by correcting the image-linked graphics component or rolling back to the known-good image state, then redeploy remediated hosts. Service was confirmed restored at 10:00 with successful user logins and no further issues reported.

How to spot it: Look for successful logon events followed by graphics-path failures: TerminalServices-LocalSessionManager Event 21, then Application Error Event 1000 for dwm.exe faulting in igdumd64.dll (31.0.101.4146, 0xc0000005), plus Desktop Window Manager Event 9009 and session disconnect Event 40. On unaffected comparison hosts, DWM start appears as Desktop Window Manager Event 9011 with no Application Error Event 1000 in the same window.
