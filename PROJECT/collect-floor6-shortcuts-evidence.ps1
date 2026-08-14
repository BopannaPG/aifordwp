<#
.SYNOPSIS
Collects evidence for the Floor 6 desktop shortcuts incident and safely processes old evidence files.

.DESCRIPTION
This script is designed for PowerShell 5.1 and endpoint-safe execution.
It gathers evidence for the top-ranked RCA cause (desktop items hidden by policy),
then optionally removes old evidence files from active folders by moving them to a quarantine area.

Key safety features:
- Dry run mode shows files that would be removed.
- Age-based targeting with configurable days (default: 0).
- Locked files are skipped and logged.
- Per-file try/catch handling (script does not stop on one file error).
- Timestamped action log.
- End-of-run summary.
- Manifest-based rollback.
- Idempotent behavior.

.NOTES
Author: DWP Engineering
Version: 1.0
Compatible: Windows PowerShell 5.1
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # Root folder for evidence output and logs.
    [Parameter(Mandatory = $false)]
    [string]$OutputRoot = "C:\DWP\Floor6-Evidence",

    # User profile name used for desktop shortcut inventory.
    [Parameter(Mandatory = $false)]
    [string]$TargetUser = $env:USERNAME,

    # Files older than this number of days are eligible for cleanup from active evidence folders.
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    # Preview mode: show files that would be removed from active folders.
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    # Rollback mode: restores files moved to quarantine using a manifest.
    [Parameter(Mandatory = $false)]
    [switch]$Rollback,

    # Path to manifest file used for rollback.
    [Parameter(Mandatory = $false)]
    [string]$RollbackManifestPath,

    # Active folders to process for old files. Defaults to evidence/log folders.
    [Parameter(Mandatory = $false)]
    [string[]]$CleanupPaths,

    # Include event export from System and GroupPolicy operational logs.
    [Parameter(Mandatory = $false)]
    [switch]$CollectEvents = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------
# Section: Runtime paths and IDs
# ------------------------------
$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$runFolder = Join-Path $OutputRoot ("run-" + $runId)
$logFolder = Join-Path $OutputRoot "logs"
$quarantineRoot = Join-Path $OutputRoot "quarantine"
$manifestFolder = Join-Path $OutputRoot "manifests"

if (-not $CleanupPaths -or $CleanupPaths.Count -eq 0) {
    $CleanupPaths = @($OutputRoot, $logFolder)
}

# Ensure key directories exist.
foreach ($path in @($OutputRoot, $logFolder, $quarantineRoot, $manifestFolder)) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

$logFile = Join-Path $logFolder ("collect-floor6-evidence-" + $runId + ".log")

# ------------------------------
# Section: Logging helpers
# ------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][ValidateSet('INFO','WARN','ERROR','SUMMARY')][string]$Level = 'INFO'
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

# ----------------------------------
# Section: File lock detection helper
# ----------------------------------
function Test-FileLocked {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $stream = [System.IO.File]::Open($Path, 'Open', 'ReadWrite', 'None')
        $stream.Close()
        return $false
    }
    catch {
        return $true
    }
}

# ---------------------------------
# Section: Evidence collection logic
# ---------------------------------
function Collect-Evidence {
    # Create run folder for this execution.
    if (-not (Test-Path -LiteralPath $runFolder)) {
        New-Item -Path $runFolder -ItemType Directory -Force | Out-Null
    }

    Write-Log "Starting evidence collection. Run folder: $runFolder"

    # 1) Desktop shortcut inventory (verifies files exist even when hidden).
    try {
        $desktopPath = Join-Path "C:\Users" $TargetUser
        $desktopPath = Join-Path $desktopPath "Desktop"
        $shortcutInventoryPath = Join-Path $runFolder "desktop-shortcuts.csv"

        if (Test-Path -LiteralPath $desktopPath) {
            Get-ChildItem -LiteralPath $desktopPath -Filter "*.lnk" -File -ErrorAction Stop |
                Select-Object FullName, Name, Length, CreationTime, LastWriteTime |
                Export-Csv -Path $shortcutInventoryPath -NoTypeInformation
            Write-Log "Desktop shortcut inventory exported: $shortcutInventoryPath"
        }
        else {
            Write-Log "Desktop path not found: $desktopPath" "WARN"
        }
    }
    catch {
        Write-Log "Failed desktop shortcut inventory: $($_.Exception.Message)" "ERROR"
    }

    # 2) Policy-related registry checks for hidden desktop behavior.
    try {
        $regOut = Join-Path $runFolder "desktop-policy-registry.txt"
        $regPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        )

        "Registry snapshot for desktop visibility policy keys" | Out-File -FilePath $regOut -Encoding ascii
        foreach ($regPath in $regPaths) {
            Add-Content -Path $regOut -Value ("`n=== {0} ===" -f $regPath)
            if (Test-Path -LiteralPath $regPath) {
                Get-ItemProperty -LiteralPath $regPath |
                    Select-Object NoDesktop, HideIcons, HideDesktopIcons |
                    Out-String |
                    Add-Content -Path $regOut
            }
            else {
                Add-Content -Path $regOut -Value "Path not present"
            }
        }
        Write-Log "Registry evidence exported: $regOut"
    }
    catch {
        Write-Log "Failed registry evidence capture: $($_.Exception.Message)" "ERROR"
    }

    # 3) gpresult report to capture applied policy state.
    try {
        $gpResultPath = Join-Path $runFolder "gpresult.html"
        $tempParent = Split-Path -Path $gpResultPath -Parent
        if (-not (Test-Path -LiteralPath $tempParent)) {
            New-Item -Path $tempParent -ItemType Directory -Force | Out-Null
        }

        $proc = Start-Process -FilePath "gpresult.exe" -ArgumentList "/h `"$gpResultPath`"" -PassThru -Wait -WindowStyle Hidden
        if ($proc.ExitCode -eq 0 -and (Test-Path -LiteralPath $gpResultPath)) {
            Write-Log "gpresult report exported: $gpResultPath"
        }
        else {
            Write-Log "gpresult completed with exit code $($proc.ExitCode)." "WARN"
        }
    }
    catch {
        Write-Log "Failed gpresult capture (try running elevated): $($_.Exception.Message)" "ERROR"
    }

    # 4) Event exports for GroupPolicy processing confirmation.
    if ($CollectEvents) {
        try {
            $sysCsv = Join-Path $runFolder "event-system-grouppolicy.csv"
            Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 4098, 1502, 1503; StartTime = (Get-Date).AddDays(-7) } -ErrorAction Stop |
                Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
                Export-Csv -Path $sysCsv -NoTypeInformation
            Write-Log "System event evidence exported: $sysCsv"
        }
        catch {
            Write-Log "Failed System event export: $($_.Exception.Message)" "ERROR"
        }

        try {
            $opCsv = Join-Path $runFolder "event-operational-grouppolicy.csv"
            Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-GroupPolicy/Operational'; Id = 5312, 5317, 8004; StartTime = (Get-Date).AddDays(-7) } -ErrorAction Stop |
                Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
                Export-Csv -Path $opCsv -NoTypeInformation
            Write-Log "Operational event evidence exported: $opCsv"
        }
        catch {
            Write-Log "Failed Operational event export: $($_.Exception.Message)" "ERROR"
        }
    }

    Write-Log "Evidence collection completed for run: $runId"
}

# ---------------------------------
# Section: Old file cleanup workflow
# ---------------------------------
function Invoke-SafeCleanup {
    param(
        [Parameter(Mandatory = $true)][string[]]$Paths,
        [Parameter(Mandatory = $true)][int]$AgeDays,
        [Parameter(Mandatory = $true)][switch]$IsDryRun
    )

    $summary = [ordered]@{
        Scanned              = 0
        Candidates           = 0
        LockedSkipped        = 0
        RemovedToQuarantine  = 0
        DryRunListed         = 0
        Errors               = 0
    }

    $cutoff = (Get-Date).AddDays(-$AgeDays)
    $quarantineRun = Join-Path $quarantineRoot ("quarantine-" + $runId)
    if (-not (Test-Path -LiteralPath $quarantineRun)) {
        New-Item -Path $quarantineRun -ItemType Directory -Force | Out-Null
    }

    $manifest = @()

    Write-Log "Starting cleanup phase. Age cutoff: files older than $AgeDays day(s), cutoff: $cutoff"

    foreach ($root in $Paths) {
        if (-not (Test-Path -LiteralPath $root)) {
            Write-Log "Cleanup path not found, skipping: $root" "WARN"
            continue
        }

        $items = Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $_.LastWriteTime -lt $cutoff -and
                $_.FullName -notlike "$quarantineRoot*" -and
                $_.FullName -notlike "$manifestFolder*"
            }

        foreach ($file in $items) {
            $summary.Scanned++

            # Do not touch current run files to keep idempotence and avoid self-interference.
            if ($file.FullName -like "$runFolder*") {
                continue
            }

            $summary.Candidates++

            # Locked-file handling: skip and continue.
            if (Test-FileLocked -Path $file.FullName) {
                $summary.LockedSkipped++
                Write-Log "LOCKED-SKIP: $($file.FullName)" "WARN"
                continue
            }

            # Per-file try/catch to prevent full stop on one file failure.
            try {
                if ($IsDryRun) {
                    $summary.DryRunListed++
                    Write-Host ("DRY-RUN DELETE: {0}" -f $file.FullName)
                    Write-Log "DRY-RUN LISTED: $($file.FullName)"
                }
                else {
                    $relativeSafe = $file.FullName.Replace(':', '').Replace('\\', '__').Replace('/', '__')
                    $dest = Join-Path $quarantineRun $relativeSafe
                    Move-Item -LiteralPath $file.FullName -Destination $dest -Force -ErrorAction Stop

                    $manifest += [pscustomobject]@{
                        OriginalPath  = $file.FullName
                        QuarantinePath = $dest
                        LastWriteTime = $file.LastWriteTime
                        RunId         = $runId
                    }

                    $summary.RemovedToQuarantine++
                    Write-Log "REMOVED-TO-QUARANTINE: $($file.FullName) -> $dest"
                }
            }
            catch {
                $summary.Errors++
                Write-Log "ERROR processing file '$($file.FullName)': $($_.Exception.Message)" "ERROR"
            }
        }
    }

    if (-not $IsDryRun -and $manifest.Count -gt 0) {
        $manifestPath = Join-Path $manifestFolder ("cleanup-manifest-" + $runId + ".json")
        $manifest | ConvertTo-Json -Depth 4 | Out-File -FilePath $manifestPath -Encoding ascii
        Write-Log "Manifest written: $manifestPath"
    }

    return $summary
}

# ------------------------------
# Section: Rollback functionality
# ------------------------------
function Invoke-Rollback {
    param([Parameter(Mandatory = $true)][string]$ManifestPath)

    $summary = [ordered]@{
        ManifestEntries = 0
        Restored        = 0
        AlreadyRestored = 0
        MissingSource   = 0
        Errors          = 0
    }

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "Rollback manifest not found: $ManifestPath"
    }

    Write-Log "Starting rollback using manifest: $ManifestPath"

    $entries = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    if ($entries -isnot [System.Array]) {
        $entries = @($entries)
    }

    foreach ($entry in $entries) {
        $summary.ManifestEntries++

        try {
            $targetDir = Split-Path -Path $entry.OriginalPath -Parent
            if (-not (Test-Path -LiteralPath $targetDir)) {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            }

            if (Test-Path -LiteralPath $entry.OriginalPath) {
                $summary.AlreadyRestored++
                Write-Log "ROLLBACK-SKIP (already exists): $($entry.OriginalPath)" "WARN"
                continue
            }

            if (-not (Test-Path -LiteralPath $entry.QuarantinePath)) {
                $summary.MissingSource++
                Write-Log "ROLLBACK-SKIP (missing quarantine file): $($entry.QuarantinePath)" "WARN"
                continue
            }

            Move-Item -LiteralPath $entry.QuarantinePath -Destination $entry.OriginalPath -Force -ErrorAction Stop
            $summary.Restored++
            Write-Log "ROLLBACK-RESTORED: $($entry.OriginalPath)"
        }
        catch {
            $summary.Errors++
            Write-Log "ROLLBACK-ERROR for '$($entry.OriginalPath)': $($_.Exception.Message)" "ERROR"
        }
    }

    return $summary
}

# ------------------------------
# Section: Main execution flow
# ------------------------------
Write-Log "Script started. DryRun=$DryRun Rollback=$Rollback OlderThanDays=$OlderThanDays OutputRoot=$OutputRoot"

if ($Rollback) {
    # Rollback mode is isolated and idempotent.
    if ([string]::IsNullOrWhiteSpace($RollbackManifestPath)) {
        throw "Rollback mode requires -RollbackManifestPath"
    }

    $rbSummary = Invoke-Rollback -ManifestPath $RollbackManifestPath

    Write-Log "Rollback summary: Entries=$($rbSummary.ManifestEntries), Restored=$($rbSummary.Restored), AlreadyRestored=$($rbSummary.AlreadyRestored), MissingSource=$($rbSummary.MissingSource), Errors=$($rbSummary.Errors)" "SUMMARY"
    Write-Host "`n=== ROLLBACK SUMMARY ==="
    $rbSummary.GetEnumerator() | ForEach-Object { Write-Host ("{0}: {1}" -f $_.Key, $_.Value) }
    return
}

# Standard mode: collect evidence first, then run cleanup logic.
Collect-Evidence
$cleanupSummary = Invoke-SafeCleanup -Paths $CleanupPaths -AgeDays $OlderThanDays -IsDryRun:$DryRun

Write-Log "Cleanup summary: Scanned=$($cleanupSummary.Scanned), Candidates=$($cleanupSummary.Candidates), LockedSkipped=$($cleanupSummary.LockedSkipped), RemovedToQuarantine=$($cleanupSummary.RemovedToQuarantine), DryRunListed=$($cleanupSummary.DryRunListed), Errors=$($cleanupSummary.Errors)" "SUMMARY"

# Console summary for operators.
Write-Host "`n=== EXECUTION SUMMARY ==="
Write-Host ("RunId: {0}" -f $runId)
Write-Host ("Log File: {0}" -f $logFile)
Write-Host ("Evidence Folder: {0}" -f $runFolder)
$cleanupSummary.GetEnumerator() | ForEach-Object { Write-Host ("{0}: {1}" -f $_.Key, $_.Value) }

Write-Log "Script completed."
