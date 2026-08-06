# DWP Temp Cleanup Script (PowerShell 5.1)

This folder includes a safe temp cleanup script for Windows endpoints:

- Script: `temp-cleanup-safe.ps1`
- Purpose: Clean temp files with dry-run, age filtering, logging, per-file error handling, and rollback support.

## What the Script Does

1. Scans one or more temp folders.
2. Targets only files older than a configurable number of days.
3. Skips locked files and logs those skips.
4. Uses per-file try/catch so one bad file does not stop the run.
5. Logs every action to a timestamped log file.
6. Prints a run summary at the end.
7. Supports rollback by restoring files moved during cleanup.
8. Is idempotent:
   - Running cleanup repeatedly only acts on files currently present and matching criteria.
   - Running rollback repeatedly skips already-restored files.

## Syntax

```powershell
# Dry run (no changes)
.\temp-cleanup-safe.ps1 -DryRun

# Cleanup files older than 7 days
.\temp-cleanup-safe.ps1 -OlderThanDays 7

# Cleanup custom paths
.\temp-cleanup-safe.ps1 -TargetPaths "C:\Users\<user>\AppData\Local\Temp","C:\Windows\Temp" -OlderThanDays 3

# Rollback using latest available manifest
.\temp-cleanup-safe.ps1 -Rollback

# Rollback using a specific manifest
.\temp-cleanup-safe.ps1 -Rollback -RollbackManifest "C:\ProgramData\DWP\TempCleanup\Backups\run-20260805-101500\cleanup-manifest-20260805-101500.json"
```

## Parameters

- `-TargetPaths [string[]]`
  - One or more folders to scan recursively.
  - Default: current user temp and `C:\Windows\Temp`.

- `-OlderThanDays [int]`
  - Only files with `LastWriteTime <= (Now - OlderThanDays)` are eligible.
  - Default: `0`.

- `-DryRun [switch]`
  - Shows what would be cleaned without moving/deleting files.

- `-Rollback [switch]`
  - Runs restore mode from a previous manifest.

- `-RollbackManifest [string]`
  - Optional manifest path for rollback.
  - If omitted in rollback mode, the script selects the latest manifest under backup root.

- `-BackupRoot [string]`
  - Root folder for moved files and rollback manifests.
  - Default: `C:\ProgramData\DWP\TempCleanup\Backups`.

- `-LogRoot [string]`
  - Root folder for timestamped log files.
  - Default: `C:\ProgramData\DWP\TempCleanup\Logs`.

## Logging and Output

- A new log file is created per execution, for example:
  - `C:\ProgramData\DWP\TempCleanup\Logs\temp-cleanup-YYYYMMDD-HHMMSS.log`
- In cleanup mode (non-dry-run), a rollback manifest is saved, for example:
  - `C:\ProgramData\DWP\TempCleanup\Backups\run-YYYYMMDD-HHMMSS\cleanup-manifest-YYYYMMDD-HHMMSS.json`

## Safety Notes

- The script does not stop on individual file errors.
- Locked files are skipped and logged.
- Cleanup mode moves files into rollback storage rather than permanently deleting immediately.
- Review dry-run output before executing cleanup in production.
---
---
rewrite the below prompts
"write something for the user about their email"