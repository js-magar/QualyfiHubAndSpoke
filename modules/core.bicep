

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
param keyVaultPrivateDnsZoneName string
param CoreEncryptKeyVaultName string
param RecoverySAName string
param coreTag object

var virtualNetworkName = 'vnet-core-${RGLocation}-001'
var vmName ='vm-core-${RGLocation}-001'
var backupFabric = 'Azure'
var v2VmType = 'Microsoft.Compute/virtualMachines'
var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'
var vmSubetName = 'VMSubnet'
var kvSubetName = 'KVSubnet'
var vmSize = 'Standard_D2S_v3'
var vmNICName = 'nic-core-${RGLocation}-001'
var vmNICIP = '10.20.1.20'
var vmComputerName = 'coreComputer'
var dataCollectionRuleName = 'MSVMI-vmDataCollectionRule'

resource defaultNSG 'Microsoft.Network/networkSecurityGroups@2023-05-01' existing ={
  name: defaultNSGName
}
resource routeTable 'Microsoft.Network/routeTables@2019-11-01' existing = {name: routeTableName}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: virtualNetworkName
  location: RGLocation
  tags:coreTag
  properties: {
    addressSpace: {
      addressPrefixes: [
        '${vnetAddressPrefix}.0.0/16'
      ]
    }
    subnets: [
      {
        name: vmSubetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.1.0/24'
          networkSecurityGroup:{  id: defaultNSG.id }
          routeTable:{id:routeTable.id}
        }
      }
      {
        name: kvSubetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.2.0/24'
          networkSecurityGroup:{  id: defaultNSG.id }
          routeTable:{id:routeTable.id}
        }
      }
    ]
  }
}
resource VMSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: vmSubetName,parent: virtualNetwork}
resource VMNetworkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: vmNICName
  location: RGLocation
  tags:coreTag
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static' 
          privateIPAddress: vmNICIP
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
  tags:coreTag
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmComputerName
      adminUsername: adminUsername
      adminPassword: adminPassword
      allowExtensionOperations:true
      windowsConfiguration:{
        provisionVMAgent:true
      }
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
  tags:coreTag
  location:RGLocation
  properties:{
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type:'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
    settings:{
      enableAMA: true
    }
  }
}
resource vmAMAExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' ={
  parent:windowsVM
  name:'AzureMonitorWindowsAgent'
  tags:coreTag
  location:RGLocation
  properties:{
    publisher: 'Microsoft.Azure.Monitor'
    type:'AzureMonitorWindowsAgent'
    typeHandlerVersion:'1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
  dependsOn: [
    dataCollectionRuleAssociation
  ]
}
resource windowsVMGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: windowsVM
  name: 'AzurePolicyforWindows'
  tags:coreTag
  location: RGLocation
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
    protectedSettings: {}
  }
}
resource vmAntiMalwareExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' ={
  parent:windowsVM
  name:'AntiMalwareAgent'
  tags:coreTag
  location:RGLocation
  properties:{
    publisher: 'Microsoft.Azure.Security'
    type:'IaaSAntimalware'
    typeHandlerVersion:'1.3'
    autoUpgradeMinorVersion: true
    settings:{
      AntimalwareEnabled:true
      RealtimeProtectionEnabled:true
    }
  }
}
resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: dataCollectionRuleName
  location: RGLocation
  tags:coreTag
  identity:{
    type:'None'
  }
  properties:{
    dataSources:{
      windowsEventLogs:[
        {
          name:'WindowsEventLogs'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            'Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]'
            'Security!*[System[(band(Keywords,13510798882111488))]]'
            'System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]'
          ]
        }
      ]
      performanceCounters: [
        {
            name: 'VMInsightsPerfCounters'
            streams: [
                'Microsoft-InsightsMetrics'
            ]
            scheduledTransferPeriod: 'PT1M'
            samplingFrequencyInSeconds: 60
            counterSpecifiers: [
                '\\VmInsights\\DetailedMetrics'
            ]
        }
      ]
    }
    destinations:{
      logAnalytics:[{
        name:'VMInsightsPerf-Logs-Dest'
        workspaceResourceId:logAnalyticsWorkspace.id
      }]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Perf'
          'Microsoft-Event'
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
    ]
  }

}
resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' ={
  scope: windowsVM
  name: 'vmDataCollectionRuleAssociation'
  properties: {
    description: 'Association of data collection rule for VM Insights.'
    dataCollectionRuleId: dataCollectionRule.id
  }
}
resource solution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  location: RGLocation
  tags:coreTag
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
  tags:coreTag
  properties: {
    protectedItemType: v2VmType
    policyId: '${recoveryServiceVaults.id}/backupPolicies/DefaultPolicy'
    sourceResourceId: windowsVM.id
  }
}
//Key Vault
resource encryptionKeyVault 'Microsoft.KeyVault/vaults@2023-02-01'={
  name:CoreEncryptKeyVaultName
  tags:coreTag
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
  tags:coreTag
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
resource KVubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: 'KVSubnet',parent: virtualNetwork}
//DNS Settings
resource keyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: keyVaultPrivateDnsZoneName
}
resource privateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: keyVaultPrivateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZone.id
        }
      }
    ]
  }
}
resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name:'private-endpoint-${encryptionKeyVault.name}'
  location:RGLocation
  tags:coreTag
  properties:{
    subnet:{
      id:KVubnet.id
    }
    privateLinkServiceConnections:[
      {
        name:'private-endpoint-${encryptionKeyVault.name}'
        properties:{
          privateLinkServiceId: encryptionKeyVault.id
          groupIds:[
            'vault'
          ]
        }
  }]
  } 
}
//StorageAccount
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: RecoverySAName
  tags:coreTag
  kind: 'StorageV2'
  location: RGLocation
  sku:{
    name:'Standard_LRS'
  }
}


