# File not used
#Parameters Decleration
$RGName = (Get-AzResourceGroup).ResourceGroupName
$RGLocation = (Get-AzResourceGroup).Location
$RecoveryServiceVaultName = 'rsv-core-'+$RGLocation+'-001'
$vmName = 'vm-core-'+$RGLocation+'-001'
$saName ='sacoreeastus001jash'
#Remove-AzVM -ResourceGroupName ((Get-AzResourceGroup).ResourceGroupName) -Name ('vm-core-'+((Get-AzResourceGroup).Location)+'-001')
Get-AzRecoveryServicesVault -ResourceGroupName $RGName -Name $RecoveryServiceVaultName | Set-AzRecoveryServicesVaultContext
$rsv = Get-AzRecoveryServicesVault -ResourceGroupName $RGName -Name $RecoveryServiceVaultName 
$backupContainer = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -FriendlyName $vmName -VaultId $rsv.id
$backupContainer
$BackupItem = Get-AzRecoveryServicesBackupItem -Container $backupcontainer[1] -WorkloadType "AzureVM" -VaultId $rsv.id
$StartDate = (Get-Date).AddDays(-7)
$EndDate = Get-Date
$RestorePoint = Get-AzRecoveryServicesBackupRecoveryPoint -Item $BackupItem -StartDate $StartDate.ToUniversalTime() -EndDate $EndDate.ToUniversalTime() -VaultId $rsv.ID
$RestorePoint[0]

$RestoreJob = Restore-AzRecoveryServicesBackupItem -RecoveryPoint $RestorePoint[0] -StorageAccountName 'sacoreeastus001jash' -StorageAccountResourceGroupName $RGLocation -VaultId $rsv.ID -TargetResourceGroupName $RGLocation -VaultLocation $rsv.Location
$RestoreJob
Pause

$Details = Get-AzRecoveryServicesBackupJobDetails -Job $RestoreJob -VaultId $targetVault.ID
$Details
Pause

#The client 'cloud_user_p_fa328ba6@realhandsonlabs.com' with object id '0aab4988-5b89-40de-b0cb-066ee4b25a92' has permission to perform action
#| 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems/recoveryPoints/restore/action' on scope
#| '/subscriptions/28e1e42a-4438-4c30-9a5f-7d7b488fd883/resourceGroups/1-d0010a47-playground-sandbox/providers/Microsoft.RecoveryServices/vaults/rsv-core-eastus-001/backupFabrics/Azure/protectionContainers/IaasVMContainer;iaasvmcontainerv2;1-d0010a47-playground-sandbox;vm-core-eastus-001/protectedItems/VM;iaasvmcontainerv2;1-d0010a47-playground-sandbox;vm-core-eastus-001/recoveryPoints/928610758463922453'; however, it does not have permission to perform action 'write' on the linked scope(s) '/subscriptions/28e1e42a-4438-4c30-9a5f-7d7b488fd883/resourceGroups/eastus' or the linked scope(s) are invalid.
