param coreVnetName string
param devVnetName string
param hubVnetName string
param prodVnetName string
param RGLocation string
//Get VNets
resource coreVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: coreVnetName
  location: RGLocation
}
resource devVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: devVnetName
  location: RGLocation
}
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: hubVnetName
  location: RGLocation
}
resource prodVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: prodVnetName
  location: RGLocation
}
//DNS Zones
resource appServicePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
}
resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.database.${environment().suffixes.sqlServerHostname}'
  location: 'global'
}
resource storageAccountPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
}
//
//output DNS Zone names
output appServicePrivateDnsZoneName string = appServicePrivateDnsZone.name
output sqlPrivateDnsZoneName string = sqlPrivateDnsZone.name
output storageAccountPrivateDnsZoneName string = storageAccountPrivateDnsZone.name
//DNS Links
//core
resource CoreAppServiceLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-core'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: coreVnet.id
    }
  }
}
resource CoreSQLLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-core'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: coreVnet.id
    }
  }
}
resource CoreStorageAccountLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-core'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: coreVnet.id
    }
  }
}
//dev
resource DevAppServiceLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-dev'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: devVnet.id
    }
  }
}
resource DevSQLLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-dev'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: devVnet.id
    }
  }
}
//hub
resource HubAppServiceLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-hub'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnet.id
    }
  }
}
resource HubSQLLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-hub'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnet.id
    }
  }
}
resource HubStorageAccountLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-hub'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnet.id
    }
  }
}
//prod
resource ProdAppServiceLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-prod'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: prodVnet.id
    }
  }
}
resource ProdSQLLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-prod'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: prodVnet.id
    }
  }
}
resource ProdStorageAccountLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appServicePrivateDnsZone.name}/link-prod'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: prodVnet.id
    }
  }
}

//Zone Groups created in Spoke.bicep
