

param RGLocation string
param vnetAddressPrefix string
param GatewaySubnetName string
param AppgwSubnetName string
param AzureFirewallSubnetName string
param AzureBastionSubnetName string
param firewallName string
param prodAppServiceName string


var virtualNetworkName = 'vnet-hub-${RGLocation}-001'
var GatewaySubnetAddressPrefix ='1'
var AppgwSubnetAddressPrefix ='2'
var AzureFirewallSubnetAddressPrefix ='3'
var AzureBastionSubnetAddressPrefix ='4'
var appgw_id = resourceId('Microsoft.Network/applicationGateways','appGateway-hub-${RGLocation}-001')

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
        name: GatewaySubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${GatewaySubnetAddressPrefix}.0/24'
        }
      }
      {
        name: AppgwSubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${AppgwSubnetAddressPrefix}.0/24'
        }
      }
      {
        name: AzureFirewallSubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${AzureFirewallSubnetAddressPrefix}.0/24'
        }
      }
      {
        name: AzureBastionSubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${AzureBastionSubnetAddressPrefix}.0/24'
        }
      }
    ]
  }
}

//Bastion Code
resource BastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: AzureBastionSubnetName,parent: virtualNetwork}

resource bastionPIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-bastion-hub-${RGLocation}-001'
  location: RGLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
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
//Firewall Code
resource FirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: AzureFirewallSubnetName,parent: virtualNetwork}

resource firewallPIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-firewall-hub-${RGLocation}-001'
  location: RGLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' ={
  name: firewallName
  location:RGLocation
  properties:{
    hubIPAddresses:{
      privateIPAddress: '${vnetAddressPrefix}.${AzureFirewallSubnetAddressPrefix}.4'
    }
    ipConfigurations:[{
      name:'ipconfig'
      properties:{
        publicIPAddress:{ id:firewallPIP.id}
        subnet:{id:FirewallSubnet.id}
      }
    }]
    firewallPolicy:{id:firewallPolicy.id}
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-05-01' = {
  name: 'firewallPolicy-hub-${RGLocation}-001'
  location: RGLocation
}
resource firewallRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' ={
  name: 'firewallRules-hub-${RGLocation}-001'
  parent: firewallPolicy
  properties:{
    priority: 200
    ruleCollections:[{
      name:'allowAllRule'
      priority: 1100
      ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
      action:{ type:'Allow'}
      rules:[
        {
          name:'Rule1'
          ruleType:'NetworkRule'
          ipProtocols:['Any']
          sourceAddresses:['*']
          destinationAddresses:['*']
          destinationPorts:['*']
        }
      ]
    }]
  }
}

output firewallPrivateIP string = '${vnetAddressPrefix}.${AzureFirewallSubnetAddressPrefix}.4' //firewall.properties.hubIPAddresses.privateIPAddress

//AppGateway
resource AppGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: AppgwSubnetName,parent: virtualNetwork}

resource appGatewayPIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-appGateway-hub-${RGLocation}-001'
  location: RGLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: 'appGateway-hub-${RGLocation}-001'
  location: RGLocation
  properties:{
    backendAddressPools:[
      {
        name:'backendAddressPool'
        properties:{
          backendAddresses:[{
            fqdn:'${prodAppServiceName}.privatelink.azurewebsites.net'
          }]
        }
      }
    ]
    backendHttpSettingsCollection:[
      {
        name:'backendHttpPort80'
        properties:{
          port:80
          protocol:'Http'
          pickHostNameFromBackendAddress:true
        }
      }
    ]
    frontendIPConfigurations:[
      {
        name:'appGatewayFrontendConfig'
        properties:{
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress:{
            id:appGatewayPIP.id
          }
        }
      }
    ]
    frontendPorts:[
      {
        name:'frontendHttpPort80'
        properties:{
          port:80
        }
      }
    ]
    gatewayIPConfigurations:[
      {
        name:'appGatewayIPConfig'
        properties:{
          subnet:{
            id:AppGatewaySubnet.id
          }
        }
      }
    ]
    httpListeners:[
      {
          name:'appGWHttpListener'
          properties:{
            frontendIPConfiguration:{
              id:'${appgw_id}/frontendIPConfigurations/appGatewayFrontendConfig'
            }
            frontendPort:{
              id:'${appgw_id}/frontendPorts/frontendHttpPort80'
            }
            protocol:'Http'
          }
      }
    ]
    requestRoutingRules:[
      {
        name:'appGWRoutingRule'
        properties:{
          ruleType:'Basic'
          priority:110
          httpListener:{
            id:'${appgw_id}/httpListerners/appGWHttpListener'
          }
          backendAddressPool:{
            id:'${appgw_id}/backendAddressPools/backendAddressPool'
          }
          backendHttpSettings:{
            id:'${appgw_id}/backendHttpSettingsCollection/backendHttpPort80'
          }

        }
      }
    ]
    sku:{
      tier:'Standard_v2'
    }
  }
}


