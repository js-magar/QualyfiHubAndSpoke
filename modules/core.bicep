

param RGLocation string
param vnetAddressPrefix string
@secure()
param adminUsername string
@secure()
param adminPassword string
param defaultNSGName string
param routeTableName string
param logAnalyticsWorkspaceName string

var virtualNetworkName = 'vnet-core-${RGLocation}-001'

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
  name: 'vm-core-${RGLocation}-001'
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
resource vmMMAExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' ={
  parent:windowsVM
  name:'vmMMAExtension'
  location:RGLocation
  properties:{
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type:'MicrosoftMonitoringAgent'
    typeHandlerVersion:'1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(logAnalyticsWorkspace.id, '2022-10-01').customerId
      azureResourceId: windowsVM.id
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspace.id, '2022-10-01').primarySharedKey
    }
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
//Key Vault



