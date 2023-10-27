param coreVnetName string
param devVnetName string
param hubVnetName string
param prodVnetName string
param logAnalyticsWorkspaceName string
param recoveryServiceVaultName string
param RGLocation string
param coreVnetAddress string
param devVnetAddress string
param prodVnetAddress string
param hubVnetAddress string

param hubTag object
param coreTag object
param prodTag object
param devTag object
param coreServicesTag object

//RSV
resource recoveryServiceVaults 'Microsoft.RecoveryServices/vaults@2023-06-01'={
  name:recoveryServiceVaultName
  location:RGLocation
  tags:coreServicesTag
  properties:{
    publicNetworkAccess:'Disabled'
  }
  sku:{
    tier:'Standard'
    name:'Standard'
  }
}
//LAW
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name:logAnalyticsWorkspaceName
  location:RGLocation
  tags:coreServicesTag
  properties:{
    features:{
      enableLogAccessUsingOnlyResourcePermissions:true
    }
  }
}
//Get VNets
resource coreVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: coreVnetName
  location: RGLocation
  tags:coreTag
  properties: {
    addressSpace: {
      addressPrefixes: [
        coreVnetAddress//'10.20.0.0/16'
      ]
    }
  }
}
resource devVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: devVnetName
  location: RGLocation
  tags:devTag
  properties: {
    addressSpace: {
      addressPrefixes: [
        devVnetAddress//'10.30.0.0/16'
      ]
    }
  }
}
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: hubVnetName
  location: RGLocation
  tags:hubTag
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddress//'10.10.0.0/16'
      ]
    }
  }
}
resource prodVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: prodVnetName
  location: RGLocation
  tags:prodTag
  properties: {
    addressSpace: {
      addressPrefixes: [
        prodVnetAddress//'10.31.0.0/16'
      ]
    }
  }
}
//DNS Zones
resource appServicePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
  tags:coreServicesTag
}
resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink${environment().suffixes.sqlServerHostname}'
  location: 'global'
  tags:coreServicesTag
}
resource storageAccountPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  tags:coreServicesTag
}
resource encryptKVPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink${environment().suffixes.keyvaultDns}'
  location: 'global'
  tags:coreServicesTag
}
//
//output DNS Zone names
output appServicePrivateDnsZoneName string = appServicePrivateDnsZone.name
output sqlPrivateDnsZoneName string = sqlPrivateDnsZone.name
output storageAccountPrivateDnsZoneName string = storageAccountPrivateDnsZone.name
output encryptKVPrivateDnsZoneName string = encryptKVPrivateDnsZone.name
//DNS Links
//core
resource CoreAppServiceLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: appServicePrivateDnsZone
  name: 'link-core'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: coreVnet.id
    }
  }
}
resource CoreSQLLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlPrivateDnsZone
  name: 'link-core'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: coreVnet.id
    }
  }
}
resource CoreStorageAccountLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: storageAccountPrivateDnsZone
  name: 'link-core'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: coreVnet.id
    }
  }
}
//dev
resource DevAppServiceLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: appServicePrivateDnsZone
  name: 'link-dev'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: devVnet.id
    }
  }
}
resource DevSQLLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlPrivateDnsZone
  name: 'link-dev'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: devVnet.id
    }
  }
}
//hub
resource HubAppServiceLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: appServicePrivateDnsZone
  name: 'link-hub'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnet.id
    }
  }
}
resource HubSQLLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlPrivateDnsZone
  name: 'link-hub'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnet.id
    }
  }
}
resource HubStorageAccountLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: storageAccountPrivateDnsZone
  name: 'link-hub'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnet.id
    }
  }
}
//prod
resource ProdAppServiceLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: appServicePrivateDnsZone
  name: 'link-prod'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: prodVnet.id
    }
  }
}
resource ProdSQLLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlPrivateDnsZone
  name: 'link-prod'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: prodVnet.id
    }
  }
}
resource ProdStorageAccountLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: storageAccountPrivateDnsZone
  name: 'link-prod'
  location: 'global'
  tags:coreServicesTag
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: prodVnet.id
    }
  }
}

//Zone Groups created in Spoke.bicep
