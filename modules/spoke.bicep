@allowed([
  'dev'
  'prod'
])
param devOrProd string = 'dev'
param RGLocation string
param vnetAddressPrefix string

var virtualNetworkName = 'vnet-${devOrProd}-${RGLocation}-001'

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
        name: 'AppSubnet'
        properties: {
          addressPrefix: '${vnetAddressPrefix}.1.0/24'
        }
      }
      {
        name: 'SqlSubnet'
        properties: {
          addressPrefix: '${vnetAddressPrefix}.2.0/24'
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' = if (devOrProd == 'prod') {
  parent: virtualNetwork
  name: 'StSubnet'
  properties: {
    addressPrefix: '${vnetAddressPrefix}.3.0/24'
  }
}



