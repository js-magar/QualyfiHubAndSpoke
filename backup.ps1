#Parameters Decleration
$RGName = (Get-AzResourceGroup).ResourceGroupName
$RGLocation = (Get-AzResourceGroup).Location
$RecoveryServiceVaultName = 'rsv-core-'+$RGLocation+'-001'
$vmName = 'vm-core-'+$RGLocation+'-001'

Get-AzRecoveryServicesVault -ResourceGroupName $RGName -Name $RecoveryServiceVaultName | Set-AzRecoveryServicesVaultContext
$backupContainer = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -FriendlyName $vmName 
$item = Get-AzRecoveryServicesBackupItem -Container $backupcontainer -WorkloadType "AzureVM"

Backup-AzRecoveryServicesBackupItem -Item $item