

param RGLocation string
param vnetAddressPrefix string
@secure()
param adminUsername string
@secure()
param adminPassword string
param defaultNSGName string
param routeTableName string
param logAnalyticsWorkspaceName string
param recoveryServiceVaultName string
param randString string

var virtualNetworkName = 'vnet-core-${RGLocation}-001'
var vmName ='vm-core-${RGLocation}-001'
var backupFabric = 'Azure'
var v2VmType = 'Microsoft.Compute/virtualMachines'
var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'

resource defaultNSG 'Microsoft.Network/networkSecurityGroups@2023-05-01' existing ={
  name: defaultNSGName
}
resource routeTable 'Microsoft.Network/routeTables@2019-11-01' existing = {name: routeTableName}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: virtualNetworkName
  location: RGLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '${vnetAddressPrefix}.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'VMSubnet'
        properties: {
          addressPrefix: '${vnetAddressPrefix}.1.0/24'
          networkSecurityGroup:{  id: defaultNSG.id }
          routeTable:{id:routeTable.id}
        }
      }
      {
        name: 'KVSubnet'
        properties: {
          addressPrefix: '${vnetAddressPrefix}.2.0/24'
          networkSecurityGroup:{  id: defaultNSG.id }
          routeTable:{id:routeTable.id}
        }
      }
    ]
  }
}
resource VMSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: 'VMSubnet',parent: virtualNetwork}
resource VMNetworkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-core-${RGLocation}-001'
  location: RGLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static' 
          //CHANGE
          privateIPAddress: '10.20.1.20' 
          subnet: {
            id: VMSubnet.id
          }
        }
      }
    ]
  }
}
resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: RGLocation
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2S_v3'
    }
    osProfile: {
      computerName: 'computerName'
      adminUsername: adminUsername
      adminPassword: adminPassword
      allowExtensionOperations:true
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: 'name'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk:{
          storageAccountType:'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: VMNetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name:logAnalyticsWorkspaceName
}
resource vmDAExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent:windowsVM
  name:'vmDependancyAgent'
  location:RGLocation
  properties:{
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type:'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
}
resource vmAMAExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' ={
  parent:windowsVM
  name:'AzureMonitorWindowsAgent'
  location:RGLocation
  properties:{
    publisher: 'Microsoft.Azure.Monitor'
    type:'AzureMonitorWindowsAgent'
    typeHandlerVersion:'1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}
resource solution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  location: RGLocation
  name: 'VMInsights(${split(logAnalyticsWorkspace.id, '/')[8]})'
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'VMInsights(${split(logAnalyticsWorkspace.id, '/')[8]})'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
    publisher: 'Microsoft'
  }
}
resource recoveryServiceVaults 'Microsoft.RecoveryServices/vaults@2023-06-01'existing = {
  name:recoveryServiceVaultName
}
//https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.recoveryservices/recovery-services-backup-vms/main.bicep#L20
resource windowsVMBackup 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2023-04-01' ={
  name:'${recoveryServiceVaultName}/${backupFabric}/${v2VmContainer}${resourceGroup().name};${vmName}/${v2Vm}${resourceGroup().name};${vmName}'
  properties: {
    protectedItemType: v2VmType
    policyId: '${recoveryServiceVaults.id}/backupPolicies/DefaultPolicy'
    sourceResourceId: windowsVM.id
  }
}
//Key Vault
resource encryptionKeyVault 'Microsoft.KeyVault/vaults@2023-02-01'={
  name:'kv-encrypt-core-${randString}'
  location:RGLocation
  properties:{
    accessPolicies:[]
    enableRbacAuthorization: false
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    networkAcls:{
      defaultAction:'Allow'
      bypass:'AzureServices'
    }
    sku:{
      family:'A'
      name:'standard'
    }
    tenantId:subscription().tenantId
  }
}

resource DiskEncryption 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: windowsVM
  name: 'AzureDiskEncryption'
  location: RGLocation
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    forceUpdateTag: '1.0'
    settings: {
      EncryptionOperation: 'EnableEncryption'
      KeyVaultURL: encryptionKeyVault.properties.vaultUri
      KeyVaultResourceId: encryptionKeyVault.id
      VolumeType: 'All'
      ResizeOSDisk: false
    }
  }
}



