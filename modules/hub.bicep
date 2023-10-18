

param RGLocation string
param vnetAddressPrefix string

var virtualNetworkName = 'vnet-hub-${RGLocation}-001'

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
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '${vnetAddressPrefix}.1.0/24'
        }
      }
      {
        name: 'AppgwSubnet'
        properties: {
          addressPrefix: '${vnetAddressPrefix}.2.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '${vnetAddressPrefix}.3.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '${vnetAddressPrefix}.4.0/24'
        }
      }
    ]
  }
}

resource BastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: 'AzureBastionSubnet',parent: virtualNetwork}

resource bastionPIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'pip-bastion-hub-${RGLocation}-001'
  location: RGLocation
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: 'dnsname'
    }
  }
}
resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' ={
  name: 'bastion-hub-${RGLocation}-001'
  location:RGLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: BastionSubnet.id
          }
          publicIPAddress: {
            id: bastionPIP.id
          }
        }
      }
    ]
  }
}


