
param RGLocation string
param hubTag object
param firewallPrivateIP string
var devVirtualNetworkName = 'vnet-dev-${RGLocation}-001'
var prodVirtualNetworkName = 'vnet-prod-${RGLocation}-001'
var hubVirtualNetworkName = 'vnet-hub-${RGLocation}-001'
var coreVirtualNetworkName = 'vnet-core-${RGLocation}-001'

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: hubVirtualNetworkName
}

resource prodVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: prodVirtualNetworkName
}

resource devVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: devVirtualNetworkName
}

resource coreVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: coreVirtualNetworkName
}

resource hubToCorePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01'={
  name: 'hub-to-core-peering'
  parent: hubVirtualNetwork
  properties:{
    allowForwardedTraffic:true
    allowGatewayTransit:true
    allowVirtualNetworkAccess:true
    peeringState:'Connected'
    remoteVirtualNetwork:{
      id: coreVirtualNetwork.id
    }
  }
}
resource hubToProdPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01'={
  name: 'hub-to-prod-peering'
  parent: hubVirtualNetwork
  properties:{
    allowForwardedTraffic:true
    allowGatewayTransit:true
    allowVirtualNetworkAccess:true
    peeringState:'Connected'
    remoteVirtualNetwork:{
      id: prodVirtualNetwork.id
    }
  }
}
resource hubToDevPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01'={
  name: 'hub-to-dev-peering'
  parent: hubVirtualNetwork
  properties:{
    allowForwardedTraffic:true
    allowGatewayTransit:true
    allowVirtualNetworkAccess:true
    peeringState:'Connected'
    remoteVirtualNetwork:{
      id: devVirtualNetwork.id
    }
  }
}
resource coreToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01'={
  name: 'core-to-hub-peering'
  parent: coreVirtualNetwork
  properties:{
    allowForwardedTraffic:true
    allowGatewayTransit:true
    allowVirtualNetworkAccess:true
    peeringState:'Connected'
    remoteVirtualNetwork:{
      id: hubVirtualNetwork.id
    }
  }
}
resource prodToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01'={
  name: 'prod-to-hub-peering'
  parent: prodVirtualNetwork
  properties:{
    allowForwardedTraffic:true
    allowGatewayTransit:true
    allowVirtualNetworkAccess:true
    peeringState:'Connected'
    remoteVirtualNetwork:{
      id: hubVirtualNetwork.id
    }
  }
}
resource devToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01'={
  name: 'dev-to-hub-peering'
  parent: devVirtualNetwork
  properties:{
    allowForwardedTraffic:true
    allowGatewayTransit:true
    allowVirtualNetworkAccess:true
    peeringState:'Connected'
    remoteVirtualNetwork:{
      id: hubVirtualNetwork.id
    }
  }
}
//resource FirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: AzureFirewallSubnetName,parent: hubVirtualNetwork}
//resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' existing = {name:firewallName}
//user defined routes

resource routeTable 'Microsoft.Network/routeTables@2019-11-01' = {
  name: 'routetable-${RGLocation}-001'
  location: RGLocation
  tags:hubTag
  properties: {
    routes: [
      {
        name: 'defaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType:'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIP
        }
      }
      {
        name: 'core1Route'
        properties: {
          addressPrefix: coreVirtualNetwork.properties.addressSpace.addressPrefixes[0]
          nextHopType:'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIP
        }
      }
      {
        name: 'dev1Route'
        properties: {
          addressPrefix: devVirtualNetwork.properties.addressSpace.addressPrefixes[0]
          nextHopType:'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIP
        }
      }
      {
        name: 'prod1Route'
        properties: {
          addressPrefix: prodVirtualNetwork.properties.addressSpace.addressPrefixes[0]
          nextHopType:'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIP
        }
      }
    ]
  }
}

