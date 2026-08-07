<#
.SYNOPSIS
     Displays a simple local system health summary.

.DESCRIPTION
     This script reads basic computer, disk, process, event log, and user profile information
     and writes a short summary to the console.

.AUTHOR
     GitHub Copilot

.HOW TO RUN
     Open PowerShell in this folder and run: .\inherit.ps1

.EXAMPLE
     .\inherit.ps1
#>

# Get the local computer system details for the summary output.
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Get the free space in bytes on drive C:.
$driveCFreeBytes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Get the five processes using the most working set memory.
$topFiveProcessesByWorkingSet = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Get the ten most recent entries from the System event log and keep only error-level events.
$recentSystemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object {$_.Level -eq 2}

# Get user profiles that are not special profiles and have not been used in the last 90 days.
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
      -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)}

# Print the computer name and total physical memory.
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Print the free space on drive C: in gigabytes.
Write-Host ([math]::Round($driveCFreeBytes/1GB,2)) 'GB free'

# Print the name and working set memory for each of the top five processes.
$topFiveProcessesByWorkingSet | ForEach-Object { Write-Host $_.Name $_.WS }

# Print the time and message for each recent system error.
$recentSystemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# Print the number of stale profiles when at least one is found.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }