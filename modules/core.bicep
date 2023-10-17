

param RGLocation string
param vnetAddressPrefix string

var virtualNetworkName = 'vnet-core-${RGLocation}-001'

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
        }
      }
      {
        name: 'KVSubnet'
        properties: {
          addressPrefix: '${vnetAddressPrefix}.2.0/24'
        }
      }
    ]
  }
}
