

param RGName string
param RGLocation string
param CoreSecretsKeyVaultName string
param RandString string

var GatewaySubnetName ='GatewaySubnet'
var AppgwSubnetName ='AppgwSubnet'
var AzureFirewallSubnetName ='AzureFirewallSubnet'
var AzureBastionSubnetName ='AzureBastionSubnet'
var DefaultNSGName ='defaultNSG'
var firewallName = 'firewall-hub-${RGLocation}-001'

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: CoreSecretsKeyVaultName
}
resource defaultNSG 'Microsoft.Network/networkSecurityGroups@2023-05-01' ={
  name: DefaultNSGName
  location:RGLocation
}
module devSpoke 'modules/spoke.bicep'={
  name:'devSpokeDeployment'
  params:{
    RGLocation:RGLocation
    devOrProd:'dev'
    vnetAddressPrefix:'10.30'
    randString: RandString
  }
}
module prodSpoke 'modules/spoke.bicep'={
  name:'prodSpokeDeployment'
  params:{
    RGLocation:RGLocation
    devOrProd:'prod'
    vnetAddressPrefix:'10.31'
    randString: RandString
  }
}
module hub 'modules/hub.bicep'={
  name:'hubDeployment'
  params:{
    RGLocation:RGLocation
    vnetAddressPrefix:'10.10'
    GatewaySubnetName:GatewaySubnetName
    AppgwSubnetName:AppgwSubnetName
    AzureFirewallSubnetName:AzureFirewallSubnetName
    AzureBastionSubnetName:AzureBastionSubnetName
    firewallName:firewallName
  }
}
module core 'modules/core.bicep'={
  name:'coreDeployment'
  params:{
    RGLocation:RGLocation
    vnetAddressPrefix:'10.20'
    adminUsername:keyVault.getSecret('VMAdminUsername')
    adminPassword:keyVault.getSecret('VMAdminPassword')
    defaultNSGName:defaultNSG.name
  }
}
module peerings 'modules/peerings.bicep'={
  name:'peeringsDeployment'
  params:{
    RGLocation:RGLocation
    AzureFirewallSubnetName:AzureFirewallSubnetName
    firewallName:firewallName
    firewallPrivateIP:hub.outputs.firewallPrivateIP
  }
  dependsOn:[
    devSpoke
    prodSpoke
    hub
    core
  ]
}
