<#
.SYNOPSIS
Safely cleans up temporary files on a Windows endpoint with logging, dry-run, and rollback support.

.DESCRIPTION
This script targets files in temporary locations, filters by age, and moves eligible files
into a rollback folder before deletion-equivalent cleanup. Because files are moved first,
rollback is possible using a generated manifest.

PowerShell version target: 5.1
#>

[CmdletBinding(DefaultParameterSetName = 'Cleanup')]
param(
    # One or more folders to scan for temp files.
    [Parameter(ParameterSetName = 'Cleanup')]
    [string[]]$TargetPaths = @($env:TEMP, 'C:\Windows\Temp'),

    # Minimum age (in days) of files to clean. Default 0 means any file older than now.
    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    # Lists files that would be cleaned without changing anything.
    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun,

    # Runs rollback mode to restore files from a previous cleanup manifest.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    # Manifest file to use for rollback. If omitted in rollback mode, latest manifest is selected.
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackManifest,

    # Root folder for backup payloads and manifests used by rollback.
    [string]$BackupRoot = "$env:ProgramData\DWP\TempCleanup\Backups",

    # Root folder for timestamped log files.
    [string]$LogRoot = "$env:ProgramData\DWP\TempCleanup\Logs"
)

# -------------------------------
# Script Setup
# -------------------------------
# Creates run identifiers and key folders used for logs and rollback data.
$ErrorActionPreference = 'Stop'
$runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runId = "run-$runTimestamp"

if (-not (Test-Path -LiteralPath $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path -Path $LogRoot -ChildPath ("temp-cleanup-$runTimestamp.log")

# -------------------------------
# Logging Helper
# -------------------------------
# Writes every action to console and log file with a timestamp and severity.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[$timestamp] [$Level] $Message"
    Write-Output $entry
    Add-Content -LiteralPath $logFile -Value $entry
}

# -------------------------------
# Lock Check Helper
# -------------------------------
# Detects whether a file is currently in use by trying to open it with exclusive access.
function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $stream = [System.IO.File]::Open($Path, 'Open', 'ReadWrite', 'None')
        if ($null -ne $stream) {
            $stream.Close()
        }
        return $false
    }
    catch [System.IO.IOException] {
        return $true
    }
    catch {
        # If access cannot be determined reliably, treat as locked for safety.
        return $true
    }
}

# -------------------------------
# Rollback Helpers
# -------------------------------
# Finds the newest manifest when rollback mode is used without an explicit manifest path.
function Get-LatestManifestPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    if (-not (Test-Path -LiteralPath $RootPath)) {
        return $null
    }

    $latest = Get-ChildItem -LiteralPath $RootPath -Recurse -File -Filter 'cleanup-manifest-*.json' -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $latest) {
        return $null
    }

    return $latest.FullName
}

# Restores files from a manifest. Existing destination files are skipped for idempotency.
function Invoke-Rollback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    Write-Log -Message "Starting rollback using manifest: $ManifestPath"

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "Rollback manifest not found: $ManifestPath"
    }

    $manifestEntries = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

    $summary = [ordered]@{
        ManifestPath      = $ManifestPath
        Restored          = 0
        SkippedExisting   = 0
        SkippedMissingBak = 0
        Errors            = 0
    }

    foreach ($entry in $manifestEntries) {
        $originalPath = [string]$entry.OriginalPath
        $backupPath = [string]$entry.BackupPath

        try {
            if (-not (Test-Path -LiteralPath $backupPath)) {
                $summary.SkippedMissingBak++
                Write-Log -Level 'WARN' -Message "Backup file missing, cannot restore: $backupPath"
                continue
            }

            if (Test-Path -LiteralPath $originalPath) {
                $summary.SkippedExisting++
                Write-Log -Level 'WARN' -Message "Target already exists, skipped restore: $originalPath"
                continue
            }

            $parent = Split-Path -Path $originalPath -Parent
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }

            Move-Item -LiteralPath $backupPath -Destination $originalPath -Force -ErrorAction Stop
            $summary.Restored++
            Write-Log -Message "Restored: $originalPath"
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message "Rollback failed for '$originalPath'. Error: $($_.Exception.Message)"
        }
    }

    Write-Log -Message "Rollback complete. Restored=$($summary.Restored), SkippedExisting=$($summary.SkippedExisting), SkippedMissingBackup=$($summary.SkippedMissingBak), Errors=$($summary.Errors)"

    return [pscustomobject]$summary
}

# -------------------------------
# Main: Rollback Mode
# -------------------------------
# Executes rollback flow and exits after printing a concise summary.
if ($Rollback) {
    try {
        $manifestToUse = $RollbackManifest
        if ([string]::IsNullOrWhiteSpace($manifestToUse)) {
            $manifestToUse = Get-LatestManifestPath -RootPath $BackupRoot
            if ([string]::IsNullOrWhiteSpace($manifestToUse)) {
                throw "No rollback manifest found under $BackupRoot"
            }
            Write-Log -Message "No rollback manifest provided. Using latest: $manifestToUse"
        }

        $rollbackSummary = Invoke-Rollback -ManifestPath $manifestToUse

        Write-Output ''
        Write-Output '=== Rollback Summary ==='
        Write-Output ("Manifest: {0}" -f $rollbackSummary.ManifestPath)
        Write-Output ("Restored: {0}" -f $rollbackSummary.Restored)
        Write-Output ("Skipped (existing target): {0}" -f $rollbackSummary.SkippedExisting)
        Write-Output ("Skipped (missing backup): {0}" -f $rollbackSummary.SkippedMissingBak)
        Write-Output ("Errors: {0}" -f $rollbackSummary.Errors)
        Write-Output ("Log file: {0}" -f $logFile)
        return
    }
    catch {
        Write-Log -Level 'ERROR' -Message "Rollback aborted. Error: $($_.Exception.Message)"
        throw
    }
}

# -------------------------------
# Main: Cleanup Mode Initialization
# -------------------------------
# Prepares backup destination and counters used for detailed end-of-run reporting.
$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$backupRunFolder = Join-Path -Path $BackupRoot -ChildPath $runId
$manifestPath = Join-Path -Path $backupRunFolder -ChildPath ("cleanup-manifest-$runTimestamp.json")

if (-not $DryRun) {
    if (-not (Test-Path -LiteralPath $backupRunFolder)) {
        New-Item -Path $backupRunFolder -ItemType Directory -Force | Out-Null
    }
}

$summary = [ordered]@{
    DryRun              = [bool]$DryRun
    TargetPaths         = ($TargetPaths -join '; ')
    OlderThanDays       = $OlderThanDays
    CutoffDate          = $cutoff.ToString('yyyy-MM-dd HH:mm:ss')
    Scanned             = 0
    Eligible            = 0
    Cleaned             = 0
    SkippedLocked       = 0
    SkippedNotFound     = 0
    Errors              = 0
    ManifestPath        = if ($DryRun) { 'Not created (dry run)' } else { $manifestPath }
    LogFile             = $logFile
}

$manifestEntries = New-Object System.Collections.Generic.List[object]

Write-Log -Message "Starting cleanup. DryRun=$DryRun, OlderThanDays=$OlderThanDays, Cutoff=$($summary.CutoffDate)"
Write-Log -Message "Target paths: $($summary.TargetPaths)"

# -------------------------------
# File Discovery
# -------------------------------
# Enumerates candidate files from all target paths while continuing on access issues.
$candidateFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]

foreach ($path in $TargetPaths) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        continue
    }

    if (-not (Test-Path -LiteralPath $path)) {
        Write-Log -Level 'WARN' -Message "Target path not found, skipped: $path"
        continue
    }

    Write-Log -Message "Scanning path: $path"
    Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            $candidateFiles.Add($_)
        }
}

# -------------------------------
# Cleanup Loop
# -------------------------------
# Processes each file with per-file try/catch, lock detection, and action logging.
foreach ($file in $candidateFiles) {
    $summary.Scanned++

    if ($file.LastWriteTime -gt $cutoff) {
        continue
    }

    $summary.Eligible++

    try {
        if (-not (Test-Path -LiteralPath $file.FullName)) {
            $summary.SkippedNotFound++
            Write-Log -Level 'WARN' -Message "File disappeared before processing, skipped: $($file.FullName)"
            continue
        }

        if (Test-FileLocked -Path $file.FullName) {
            $summary.SkippedLocked++
            Write-Log -Level 'WARN' -Message "File is locked, skipped: $($file.FullName)"
            continue
        }

        if ($DryRun) {
            Write-Log -Message "DRY RUN - would clean: $($file.FullName)"
            continue
        }

        # Generate a collision-resistant backup file name to preserve rollback mapping.
        $safeOriginal = $file.FullName -replace '[:\\/]', '_'
        $destination = Join-Path -Path $backupRunFolder -ChildPath ("$safeOriginal.$($file.CreationTimeUtc.Ticks).bak")

        Move-Item -LiteralPath $file.FullName -Destination $destination -Force -ErrorAction Stop

        $manifestEntries.Add([pscustomobject]@{
            OriginalPath     = $file.FullName
            BackupPath       = $destination
            LastWriteTimeUtc = $file.LastWriteTimeUtc.ToString('o')
            MovedAtUtc       = (Get-Date).ToUniversalTime().ToString('o')
        })

        $summary.Cleaned++
        Write-Log -Message "Cleaned (moved to rollback store): $($file.FullName)"
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message "Failed to process '$($file.FullName)'. Error: $($_.Exception.Message)"
    }
}

# -------------------------------
# Manifest Persistence
# -------------------------------
# Saves rollback metadata only for non-dry-run operations.
if (-not $DryRun) {
    try {
        $manifestEntries | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
        Write-Log -Message "Rollback manifest saved: $manifestPath"
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message "Failed to write rollback manifest. Error: $($_.Exception.Message)"
    }
}

# -------------------------------
# End-of-Run Summary
# -------------------------------
# Reports final counters to both console and log.
$modeLabel = 'Cleanup'
if ($DryRun) {
    $modeLabel = 'Dry Run'
}

Write-Output ''
Write-Output '=== Cleanup Summary ==='
Write-Output ("Mode: {0}" -f $modeLabel)
Write-Output ("Target Paths: {0}" -f $summary.TargetPaths)
Write-Output ("Older Than Days: {0}" -f $summary.OlderThanDays)
Write-Output ("Cutoff Date: {0}" -f $summary.CutoffDate)
Write-Output ("Scanned: {0}" -f $summary.Scanned)
Write-Output ("Eligible: {0}" -f $summary.Eligible)
Write-Output ("Cleaned: {0}" -f $summary.Cleaned)
Write-Output ("Skipped Locked: {0}" -f $summary.SkippedLocked)
Write-Output ("Skipped Not Found: {0}" -f $summary.SkippedNotFound)
Write-Output ("Errors: {0}" -f $summary.Errors)
Write-Output ("Rollback Manifest: {0}" -f $summary.ManifestPath)
Write-Output ("Log file: {0}" -f $summary.LogFile)

Write-Log -Message "Run complete. Scanned=$($summary.Scanned), Eligible=$($summary.Eligible), Cleaned=$($summary.Cleaned), Locked=$($summary.SkippedLocked), Errors=$($summary.Errors)"
