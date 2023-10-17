
param RGLocation string

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
