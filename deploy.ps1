#Functions for easy repeat
function RandomiseString{
    param (
        [int]$allowedLength = 10,
        [string]$allowedText ="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"
    )
    $returnText = -Join($allowedText.tochararray() | Get-Random -Count $allowedLength | % {[char]$_})
    return $returnText
}
#Parameters Decleration
$RGName = (Get-AzResourceGroup).ResourceGroupName
$RGLocation = (Get-AzResourceGroup).Location
$CoreTags = @{"Area"="CoreServices"}
$CoreSecretsKeyVaultName = "kv-secret-core-" + (RandomiseString 6)

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

#Deploy Keyvault
New-AzKeyVault -ResourceGroupName $RGName -Location $RGLocation -Name $CoreSecretsKeyVaultName -EnabledForTemplateDeployment -Tag $CoreTags


#New-AzResourceGroupDeployment -TemplateFile main.bicep