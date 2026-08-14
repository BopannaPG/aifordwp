# README: Floor 6 Shortcuts Evidence Script

## Purpose

`collect-floor6-shortcuts-evidence.ps1` gathers endpoint evidence for the Floor 6 desktop shortcuts RCA cause (desktop items hidden by policy), then safely processes old evidence files.

The script is PowerShell 5.1 compatible and designed for safe endpoint use.

## Script Location

- `PROJECT/collect-floor6-shortcuts-evidence.ps1`

## What it Collects

- Desktop shortcut inventory (`*.lnk`) for the target user
- Registry snapshot for desktop visibility policy keys
- `gpresult` HTML report
- GroupPolicy-related event exports (System + Operational)

## Safety Features

- Dry run mode prints files it would remove from active folders.
- Age filter targets only files older than `-OlderThanDays` (default `0`).
- Locked files are skipped and logged.
- Per-file try/catch handling prevents full script failure.
- Every action is logged to a timestamped log file.
- End-of-run summary is printed.
- Rollback restores moved files from manifest.
- Idempotent behavior:
  - Re-running evidence collection creates a new run folder.
  - Rollback skips files already restored.

## Important Behavior Note

"Delete" in this script means **move from active folder to quarantine** (not permanent deletion). This enables rollback.

## Parameters

- `-OutputRoot <path>`: Root output folder (default `C:\DWP\Floor6-Evidence`)
- `-TargetUser <username>`: User profile name to inspect desktop (default current user)
- `-OlderThanDays <int>`: File age threshold in days for cleanup (default `0`)
- `-DryRun`: Show files that would be removed
- `-Rollback`: Enable rollback mode
- `-RollbackManifestPath <path>`: Manifest JSON to restore files from
- `-CleanupPaths <string[]>`: Folders to scan for old files
- `-CollectEvents`: Include event exports (default enabled)

## Run Examples

### 1) Safe preview (dry run)
```powershell
powershell -ExecutionPolicy Bypass -File .\collect-floor6-shortcuts-evidence.ps1 -DryRun
```

### 2) Collect evidence and process old files (default age = 0 days)
```powershell
powershell -ExecutionPolicy Bypass -File .\collect-floor6-shortcuts-evidence.ps1
```

### 3) Only process files older than 14 days
```powershell
powershell -ExecutionPolicy Bypass -File .\collect-floor6-shortcuts-evidence.ps1 -OlderThanDays 14
```

### 4) Custom output folder and target user
```powershell
powershell -ExecutionPolicy Bypass -File .\collect-floor6-shortcuts-evidence.ps1 -OutputRoot "D:\Evidence\Floor6" -TargetUser "jane.doe"
```

### 5) Rollback from manifest
```powershell
powershell -ExecutionPolicy Bypass -File .\collect-floor6-shortcuts-evidence.ps1 -Rollback -RollbackManifestPath "C:\DWP\Floor6-Evidence\manifests\cleanup-manifest-20260814-103000.json"
```

## Output Structure

- `...\run-YYYYMMDD-HHMMSS\` evidence for that run
- `...\logs\collect-floor6-evidence-YYYYMMDD-HHMMSS.log` action log
- `...\quarantine\quarantine-YYYYMMDD-HHMMSS\` moved files
- `...\manifests\cleanup-manifest-YYYYMMDD-HHMMSS.json` rollback manifest

## Operational Notes

- Run elevated for best results (`gpresult` and some log exports may require admin).
- Check summary and log after each run.
- Keep manifest files if rollback might be needed later.
