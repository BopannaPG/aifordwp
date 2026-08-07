<#
DWP Endpoint Health Report (Read-Only)
PowerShell Version: 5.1

This script is strictly read-only.
It only queries local system state, event logs, services, and optional network tests.
It does not change files, registry, services, policies, or configuration.
#>

# -------------------------------
# Verify Before Running
# -------------------------------
# 1) Run in a normal PowerShell 5.1 session on the endpoint to be assessed.
# 2) Some sections may require elevated rights for complete data visibility (to confirm).
# 3) Internet speed section uses external connectivity and optionally the Speedtest CLI if present (to confirm).
# 4) If the endpoint is heavily locked down, event log and user-session visibility may be limited (to confirm).

$ErrorActionPreference = 'Stop'

# -------------------------------
# Helper: Pending Reboot Check
# -------------------------------
# Checks common registry indicators used by Windows servicing and update components
# to determine whether a reboot is pending.
function Get-PendingRebootStatus {
    $reasons = New-Object System.Collections.Generic.List[string]

    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
        $reasons.Add('Component Based Servicing: RebootPending')
    }

    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
        $reasons.Add('Windows Update: RebootRequired')
    }

    $sessionManagerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    try {
        $pendingRename = Get-ItemProperty -Path $sessionManagerPath -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue
        if ($null -ne $pendingRename) {
            $reasons.Add('Session Manager: PendingFileRenameOperations')
        }
    }
    catch {
        # Read-only script: ignore inaccessible value and continue reporting.
    }

    [pscustomobject]@{
        IsPending = ($reasons.Count -gt 0)
        Reasons   = if ($reasons.Count -gt 0) { $reasons -join '; ' } else { 'None detected' }
    }
}

# -------------------------------
# 1) System Uptime
# -------------------------------
# Reads last boot time from Win32_OperatingSystem and calculates uptime duration.
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBoot = $os.LastBootUpTime
$uptime = (Get-Date) - $lastBoot

# -------------------------------
# 2) Free Disk Space
# -------------------------------
# Reads all fixed disks (DriveType=3) and reports total/free capacity and free percent.
$diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
        @{Name='SizeGB';Expression={ [math]::Round($_.Size / 1GB, 2) }},
        @{Name='FreeGB';Expression={ [math]::Round($_.FreeSpace / 1GB, 2) }},
        @{Name='FreePercent';Expression={ if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { 0 } }}

# -------------------------------
# 3) Pending Reboot (Registry)
# -------------------------------
# Uses helper function to read common reboot-pending registry indicators.
$pendingReboot = Get-PendingRebootStatus

# -------------------------------
# 4) Top 5 Processes by Memory
# -------------------------------
# Reads process working set and lists highest memory consumers.
$topMemory = Get-Process |
    Sort-Object -Property WorkingSet64 -Descending |
    Select-Object -First 5 Name, Id,
        @{Name='WorkingSetMB';Expression={ [math]::Round($_.WorkingSet64 / 1MB, 2) }}

# -------------------------------
# 5) Top 5 Processes by CPU
# -------------------------------
# Reads cumulative CPU seconds since process start and lists highest consumers.
$topCpu = Get-Process |
    Where-Object { $null -ne $_.CPU } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5 Name, Id,
        @{Name='CPUSeconds';Expression={ [math]::Round($_.CPU, 2) }}

# -------------------------------
# 6) Last 5 System Log Errors
# -------------------------------
# Reads the latest 5 Error-level entries from the System event log.
$lastSystemErrors = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 |
    Select-Object TimeCreated, Id, ProviderName,
        @{Name='Message';Expression={
            if ($_.Message.Length -gt 200) { $_.Message.Substring(0, 200) + '...' } else { $_.Message }
        }}

# -------------------------------
# 7) Internet Speed
# -------------------------------
# First tries Ookla Speedtest CLI if installed locally.
# If unavailable, falls back to simple connectivity/latency checks.
$speedResult = [pscustomobject]@{
    Method          = 'Not available'
    DownloadMbps    = 'to confirm'
    UploadMbps      = 'to confirm'
    LatencyMs       = 'to confirm'
    Notes           = 'Install Speedtest CLI for throughput metrics, or use fallback latency check.'
}

$speedtestCmd = Get-Command -Name 'speedtest' -ErrorAction SilentlyContinue
if ($null -ne $speedtestCmd) {
    try {
        $speedtestJson = speedtest --accept-license --accept-gdpr --format=json 2>$null | ConvertFrom-Json
        if ($null -ne $speedtestJson) {
            $speedResult = [pscustomobject]@{
                Method       = 'Speedtest CLI'
                DownloadMbps = [math]::Round(($speedtestJson.download.bandwidth * 8) / 1MB, 2)
                UploadMbps   = [math]::Round(($speedtestJson.upload.bandwidth * 8) / 1MB, 2)
                LatencyMs    = [math]::Round($speedtestJson.ping.latency, 2)
                Notes        = 'External network test completed.'
            }
        }
    }
    catch {
        $speedResult = [pscustomobject]@{
            Method       = 'Speedtest CLI'
            DownloadMbps = 'to confirm'
            UploadMbps   = 'to confirm'
            LatencyMs    = 'to confirm'
            Notes        = 'Speedtest CLI present but test failed (to confirm network/proxy restrictions).'
        }
    }
}
else {
    try {
        $pings = Test-Connection -ComputerName '8.8.8.8' -Count 4 -ErrorAction Stop
        $avgLatency = ($pings | Measure-Object -Property ResponseTime -Average).Average
        $speedResult = [pscustomobject]@{
            Method       = 'Ping fallback'
            DownloadMbps = 'to confirm'
            UploadMbps   = 'to confirm'
            LatencyMs    = [math]::Round($avgLatency, 2)
            Notes        = 'Throughput not measured. Speedtest CLI not installed (to confirm if required).'
        }
    }
    catch {
        $speedResult = [pscustomobject]@{
            Method       = 'Ping fallback'
            DownloadMbps = 'to confirm'
            UploadMbps   = 'to confirm'
            LatencyMs    = 'to confirm'
            Notes        = 'No external connectivity or ICMP blocked (to confirm).'
        }
    }
}

# -------------------------------
# 8) Microsoft Defender Service Status
# -------------------------------
# Checks whether the WinDefend service is present and running.
$defenderSvc = Get-Service -Name 'WinDefend' -ErrorAction SilentlyContinue
$defenderStatus = if ($null -eq $defenderSvc) { 'Service not found (to confirm)' } else { $defenderSvc.Status }

# -------------------------------
# 9) Number of Logged-In Users
# -------------------------------
# Uses quser output to count active/disconnected user sessions.
# This reflects terminal sessions recognized by the OS session manager.
$loggedInUsers = New-Object System.Collections.Generic.List[string]
try {
    $quserOutput = quser 2>$null
    if ($LASTEXITCODE -eq 0 -and $quserOutput.Count -gt 1) {
        foreach ($line in ($quserOutput | Select-Object -Skip 1)) {
            $cleanLine = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($cleanLine)) { continue }
            if ($cleanLine.StartsWith('>')) {
                $cleanLine = $cleanLine.TrimStart('>').Trim()
            }
            $userName = ($cleanLine -split '\s+')[0]
            if (-not [string]::IsNullOrWhiteSpace($userName)) {
                $loggedInUsers.Add($userName)
            }
        }
    }
}
catch {
    # Read-only script: fall through and return to confirm if quser fails.
}

$uniqueUsers = $loggedInUsers | Select-Object -Unique
$userCount = if ($uniqueUsers.Count -gt 0) { $uniqueUsers.Count } else { 'to confirm' }

# -------------------------------
# 10) Last Windows Update Time
# -------------------------------
# Reads the most recently installed hotfix/update record from Get-HotFix.
$lastUpdate = $null
try {
    $lastUpdate = Get-HotFix |
        Where-Object { $null -ne $_.InstalledOn } |
        Sort-Object -Property InstalledOn -Descending |
        Select-Object -First 1 HotFixID, Description, InstalledOn
}
catch {
    # Read-only script: if restricted, keep value as to confirm.
}

# -------------------------------
# Report Output
# -------------------------------
# Prints all collected health sections in a structured, readable format.
Write-Output '=== DWP Endpoint Health Report (Read-Only) ==='
Write-Output ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Output ''

Write-Output '1) System Uptime'
Write-Output ("Last Boot: {0}" -f $lastBoot)
Write-Output ("Uptime: {0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
Write-Output ''

Write-Output '2) Free Disk Space'
$diskInfo | Format-Table -AutoSize | Out-String | Write-Output

Write-Output '3) Pending Reboot (Registry)'
Write-Output ("Pending Reboot: {0}" -f $pendingReboot.IsPending)
Write-Output ("Reason(s): {0}" -f $pendingReboot.Reasons)
Write-Output ''

Write-Output '4) Top 5 Processes by Memory (Working Set)'
$topMemory | Format-Table -AutoSize | Out-String | Write-Output

Write-Output '5) Top 5 Processes by CPU'
$topCpu | Format-Table -AutoSize | Out-String | Write-Output

Write-Output '6) Last 5 System Log Errors'
$lastSystemErrors | Format-Table -Wrap -AutoSize | Out-String | Write-Output

Write-Output '7) Internet Speed'
$speedResult | Format-List | Out-String | Write-Output

Write-Output '8) Microsoft Defender Service Status'
Write-Output ("WinDefend Status: {0}" -f $defenderStatus)
Write-Output ''

Write-Output '9) Logged-In User Count'
Write-Output ("User Count: {0}" -f $userCount)
if ($uniqueUsers.Count -gt 0) {
    Write-Output ("Users: {0}" -f ($uniqueUsers -join ', '))
}
else {
    Write-Output 'Users: to confirm'
}
Write-Output ''

Write-Output '10) Last Windows Update'
if ($null -ne $lastUpdate) {
    $lastUpdate | Format-List | Out-String | Write-Output
}
else {
    Write-Output 'Last update: to confirm (insufficient data/permissions).'
}
