#Functions for easy repeat
function RandomiseString{
    param (
        [int]$allowedLength = 10,
        [string]$allowedText ="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"
    )
    $returnText = -Join($allowedText.tochararray() | Get-Random -Count $allowedLength | ForEach-Object {[char]$_})
    return $returnText
}
function SecureString{
    param ([string]$unsecuredString = "a")
    return (ConvertTo-SecureString $unsecuredString -AsPlainText -Force)
    
}
#Parameters Decleration
$RGName = (Get-AzResourceGroup).ResourceGroupName
$RGLocation = (Get-AzResourceGroup).Location
$CoreTags = @{"Area"="CoreServices"}
$CoreSecretsKeyVaultName = "kv-secret-core-" + (RandomiseString 6)
$RecoveryServiceVaultName = 'rsv-core-'+$RGLocation+'-001'
$vmName = 'vm-core-'+$RGLocation+'-001'


#Key Vault Properties|	
$VMAdminUsernameP = RandomiseString 
$VMAdminPasswordP = RandomiseString 16 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz&#$%?!1234567890"
$SQLAdminUsernameP = RandomiseString 
$SQLAdminPasswordP = RandomiseString 16 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz&#$%?!1234567890"
Write-Output "Virtual Machine Admin Username : $VMAdminUsernameP"
Write-Output "Virtual Machine Admin Password : $VMAdminPasswordP"
Write-Output "SQL Admin Password : $SQLAdminUsernameP"
Write-Output "SQL Admin Password : $SQLAdminPasswordP"
Write-Output "CoreSecretsKeyVaultName : $CoreSecretsKeyVaultName"

#Connect Connect-AzAccount
#Deploy Keyvault
New-AzKeyVault -ResourceGroupName $RGName -Location $RGLocation -Name $CoreSecretsKeyVaultName -EnabledForTemplateDeployment -Tag $CoreTags
#Set Secrets
Set-AzKeyVaultSecret -VaultName $CoreSecretsKeyVaultName -Name "VMAdminUsername" -SecretValue (SecureString $VMAdminUsernameP)
Set-AzKeyVaultSecret -VaultName $CoreSecretsKeyVaultName -Name "VMAdminPassword" -SecretValue (SecureString $VMAdminPasswordP)
Set-AzKeyVaultSecret -VaultName $CoreSecretsKeyVaultName -Name "SQLAdminUsername" -SecretValue (SecureString $SQLAdminUsernameP)
Set-AzKeyVaultSecret -VaultName $CoreSecretsKeyVaultName -Name "SQLAdminPassword" -SecretValue (SecureString $SQLAdminPasswordP)


New-AzResourceGroupDeployment -ResourceGroupName $RGName -TemplateFile main.bicep `
-RGLocation $RGLocation -CoreSecretsKeyVaultName $CoreSecretsKeyVaultName -RandString (RandomiseString 6 "abcdefghijklmnopqrstuvwxyz1234567890") 
#Get Recovery Vault
Get-AzRecoveryServicesVault -ResourceGroupName $RGName -Name $RecoveryServiceVaultName | Set-AzRecoveryServicesVaultContext
$backupContainer = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -FriendlyName $vmName 
$item = Get-AzRecoveryServicesBackupItem -Container $backupcontainer -WorkloadType "AzureVM"

Backup-AzRecoveryServicesBackupItem -Item $item
#New-AzResourceGroupDeployment -ResourceGroupName '1-1950a98a-playground-sandbox' -TemplateFile modules\core.bicep -RGLocation 'eastus' -vnetAddressPrefix '10.20'