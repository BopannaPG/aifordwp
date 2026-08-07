# Ranked Hypothesis - Finance Shared Drives Access Failure (2026-08-07)

## Scope Facts Used
- Source evidence: Intune Management Extension log and System log.
- Affected population: All Finance users (about 45), devices named DESKTOP-FB*, OU=Finance.
- Timing clue: Overnight change (2024-03-14 23:30) migrated drive mapping from GPO logon script (USER context) to Intune PowerShell script (SYSTEM context) for one pool.

### Key Evidence Extract
- 08:00:01 ScriptRunner starts `Map-FinBridgeDrives.ps1`.
- 08:00:02 Script context is SYSTEM.
- 08:00:03 Warning: `\\finbridge-fs01\Finance` not accessible in SYSTEM context.
- 08:00:03 Error: Exit code 1, network name cannot be found.
- 08:00:04 No retry configured.
- 08:00:05 Workstation service enters running state.
- 08:00:06 GroupPolicy processed successfully (not a GP processing issue).
- 08:00:07 NTFS warning: drive letter S: could not be assigned.

## Weighted Ranked Hypotheses (Most Probable First)

### 1) USER to SYSTEM context regression in mapping method (highest probability)
Why this fits:
- Change log explicitly describes this migration and states script was not updated for SYSTEM behavior.
- Failure occurs exactly in SYSTEM context with UNC access error.
- Uniform impact across all Finance users matches a centrally deployed script regression.
- Strong timing alignment with overnight pool update.

Single fastest check:
- On one affected endpoint, run equivalent mapping/UNC test as SYSTEM and as signed-in user. If SYSTEM fails and user succeeds, this hypothesis is strongly confirmed.

### 2) Startup timing race: script runs before network/share readiness
Why this fits:
- Script fails at 08:00:03, while Workstation service reports running at 08:00:05.
- No retry means early transient unavailability becomes a persistent failure.
- Image/pool update can alter startup order and readiness timing.

Single fastest check:
- Rerun mapping once with a short delay (30-60 seconds) on one impacted device; success on delayed run validates timing race.

### 3) No retry/backoff logic amplifying transient boot-time failures
Why this fits:
- Log explicitly says no retry configured.
- In boot/logon windows, DNS/SMB readiness can be momentarily unavailable.
- One-shot script behavior can produce broad morning failures.

Single fastest check:
- Add temporary retry logic to a pilot run (for example 3 attempts, short wait). If mapping succeeds without other changes, this is strongly supported.

### 4) Script still depends on user-session assumptions (credentials/session drive mapping semantics)
Why this fits:
- Migration note says script not adapted for SYSTEM context and unavailable mapped credentials at login time.
- GP processing success narrows away from policy processing as root mechanism.
- NTFS S: assignment warning is consistent with failed user-visible mapping outcome.

Single fastest check:
- Review script for user-context assumptions (user token, HKCU, per-session mapping) and run a minimal UNC access probe in SYSTEM context.

### 5) Pool/image-specific DNS or SMB name resolution variance for `finbridge-fs01`
Why this fits:
- Error string "network name cannot be found" can be produced by name-resolution/path discovery failure.
- Timing to one updated pool keeps this plausible.
- Lower likelihood than context/timing causes because direct migration evidence already points to context regression.

Single fastest check:
- During startup window on one affected DESKTOP-FB device, test immediate DNS resolution and SMB reachability to `finbridge-fs01`, then compare with later-in-session behavior.

## Weighting Rationale (Timing Clue Applied)
- Highest weights assigned to mechanisms introduced directly by overnight change: SYSTEM context execution and non-adapted script behavior.
- Medium weights assigned to startup-sequencing and one-shot execution design (no retry).
- Lower, still plausible weight assigned to pool-specific DNS/SMB variance as a contributing condition.

## Analyst Position
- Do not commit to one cause yet.
- Current evidence supports a ranked hypothesis set with strongest likelihood on context regression plus startup timing effects.
