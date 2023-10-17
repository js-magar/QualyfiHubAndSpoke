

param RGLocation string
param vnetAddressPrefix string

var virtualNetworkName = 'vnet-hub-${RGLocation}-001'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
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
