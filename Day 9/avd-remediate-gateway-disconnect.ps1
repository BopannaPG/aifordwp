param(
    [string]$SubscriptionId = "ef7e4b27-d453-4d40-807d-d288b309ffe0",
    [string]$ResourceGroup = "dwpai-lab-rg",
    [string]$HostPoolName = "POOL-FIN-01",
    [string]$SessionVmName = "vm-fin-avd-01",
    [string]$NewComputerName = "FINAVDSH99"
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId

Write-Host "Checking session host state..."
$sub = $SubscriptionId
az rest --method get --url ("https://management.azure.com/subscriptions/$sub/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/hostPools/$HostPoolName/sessionHosts?api-version=2024-04-03") --output table

Write-Host "Ensuring Automatic-Device-Join task is enabled..."
az vm run-command invoke -g $ResourceGroup -n $SessionVmName --command-id RunPowerShellScript --scripts "Enable-ScheduledTask -TaskPath '\\Microsoft\\Windows\\Workplace Join\\' -TaskName 'Automatic-Device-Join'; Start-ScheduledTask -TaskPath '\\Microsoft\\Windows\\Workplace Join\\' -TaskName 'Automatic-Device-Join'" --output none

Write-Host "Attempting secure join..."
az vm run-command invoke -g $ResourceGroup -n $SessionVmName --command-id RunPowerShellScript --scripts "dsregcmd /AzureSecureVMJoin /debug; dsregcmd /status" --output jsonc

Write-Host "If hostname duplicate remains, rename and reboot..."
az vm run-command invoke -g $ResourceGroup -n $SessionVmName --command-id RunPowerShellScript --scripts "Rename-Computer -NewName $NewComputerName -Force -Restart" --output none

Write-Host "Waiting for reboot and re-joining..."
Start-Sleep -Seconds 30
az vm run-command invoke -g $ResourceGroup -n $SessionVmName --command-id RunPowerShellScript --scripts "dsregcmd /AzureSecureVMJoin /debug; dsregcmd /status" --output jsonc

Write-Host "Final host state check..."
az rest --method get --url ("https://management.azure.com/subscriptions/$sub/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/hostPools/$HostPoolName/sessionHosts?api-version=2024-04-03") --query "value[].{sessionHost:name,status:properties.status,lastHeartBeat:properties.lastHeartBeat}" --output table
