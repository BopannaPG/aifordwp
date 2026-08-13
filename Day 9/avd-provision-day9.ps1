param(
    [string]$SubscriptionId = "ef7e4b27-d453-4d40-807d-d288b309ffe0",
    [string]$ResourceGroup = "dwpai-lab-rg",
    [string]$Location = "eastus",
    [string]$HostPoolName = "POOL-FIN-01",
    [string]$WorkspaceName = "FinBridge-Workspace",
    [string]$SessionVmName = "vm-fin-avd-01",
    [string]$SessionComputerName = "FINAVDSH01",
    [string]$VnetName = "vnet-fin-01",
    [string]$SubnetName = "snet-avd-01",
    [string]$NsgName = "nsg-fin-avd-01",
    [string]$NicName = "nic-fin-avd-01",
    [string]$PipName = "pip-fin-avd-01"
)

$ErrorActionPreference = "Stop"

Write-Host "Setting subscription..."
az account set --subscription $SubscriptionId

Write-Host "Ensuring AVD extension..."
az extension add --name desktopvirtualization --upgrade --only-show-errors

Write-Host "Creating network resources..."
az network vnet create --resource-group $ResourceGroup --location $Location --name $VnetName --address-prefixes 10.40.0.0/16 --subnet-name $SubnetName --subnet-prefixes 10.40.1.0/24 --output none
az network nsg create --resource-group $ResourceGroup --location $Location --name $NsgName --output none
az network nsg rule create --resource-group $ResourceGroup --nsg-name $NsgName --name allow-rdp-internet --priority 1000 --access Allow --direction Inbound --protocol Tcp --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 3389 --output none
az network public-ip create --resource-group $ResourceGroup --location $Location --name $PipName --sku Standard --allocation-method Static --output none
az network nic create --resource-group $ResourceGroup --location $Location --name $NicName --vnet-name $VnetName --subnet $SubnetName --network-security-group $NsgName --public-ip-address $PipName --output none

Write-Host "Creating AVD control plane resources..."
az desktopvirtualization hostpool create --resource-group $ResourceGroup --location $Location --name $HostPoolName --host-pool-type Pooled --load-balancer-type BreadthFirst --max-session-limit 5 --preferred-app-group-type Desktop --custom-rdp-property "targetisaadjoined:i:1;enablerdsaadauth:i:1" --validation-environment false --output none
az desktopvirtualization workspace create --resource-group $ResourceGroup --location $Location --name $WorkspaceName --friendly-name $WorkspaceName --description "FinBridge AVD Workspace" --output none

Write-Host "Creating session host VM..."
$adminUser = "localavdadmin"
$adminPass = (([guid]::NewGuid().ToString('N').Substring(0,20)) + 'aA1!')
az vm create --resource-group $ResourceGroup --location $Location --name $SessionVmName --computer-name $SessionComputerName --nics $NicName --image MicrosoftWindowsDesktop:office-365:win11-24h2-avd-m365:latest --size Standard_B2ms --admin-username $adminUser --admin-password $adminPass --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm true --assign-identity --output none

Write-Host "Configuring Entra login extension..."
az vm extension set --resource-group $ResourceGroup --vm-name $SessionVmName --publisher Microsoft.Azure.ActiveDirectory --name AADLoginForWindows --force-update --output none

Write-Host "Generating registration token..."
$exp = (Get-Date).ToUniversalTime().AddHours(8).ToString("yyyy-MM-ddTHH:mm:ssZ")
az desktopvirtualization hostpool update --resource-group $ResourceGroup --name $HostPoolName --registration-info expiration-time=$exp registration-token-operation=Update --output none
$token = az desktopvirtualization hostpool retrieve-registration-token --resource-group $ResourceGroup --name $HostPoolName --query token -o tsv

Write-Host "Registering VM to host pool..."
$settingsPath = Join-Path $env:TEMP 'avd-dsc-settings.json'
$protectedPath = Join-Path $env:TEMP 'avd-dsc-protected.json'
$settingsObj = @{
    modulesUrl = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02774.414.zip'
    configurationFunction = 'Configuration.ps1\\AddSessionHost'
    properties = @{ hostPoolName = $HostPoolName; aadJoin = $true }
}
$protectedObj = @{ properties = @{ registrationInfoToken = $token } }
$settingsObj | ConvertTo-Json -Depth 10 -Compress | Set-Content -Path $settingsPath -Encoding ascii
$protectedObj | ConvertTo-Json -Depth 10 -Compress | Set-Content -Path $protectedPath -Encoding ascii
az vm extension set --resource-group $ResourceGroup --vm-name $SessionVmName --publisher Microsoft.Powershell --name DSC --version 2.73 --settings @$settingsPath --protected-settings @$protectedPath --output none

Write-Host "Provisioning completed."
Write-Host "Admin password for this run: $adminPass"
