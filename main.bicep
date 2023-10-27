param RGLocation string
param CoreSecVaultName string
param CoreEncryptKeyVaultName string
param RandString string

var GatewaySubnetName ='GatewaySubnet'
var AppgwSubnetName ='AppgwSubnet'
var AzureFirewallSubnetName ='AzureFirewallSubnet'
var AzureBastionSubnetName ='AzureBastionSubnet'
var DefaultNSGName ='defaultNSG'
var firewallName = 'firewall-hub-${RGLocation}-001'

var coreVnetName = 'vnet-core-${RGLocation}-001'
var devVnetName = 'vnet-dev-${RGLocation}-001'
var hubVnetName = 'vnet-hub-${RGLocation}-001'
var prodVnetName = 'vnet-prod-${RGLocation}-001'

var devAppServicePlanName = 'asp-dev-${RGLocation}-001-${RandString}'
var devAppServiceName = 'as-dev-${RGLocation}-001-${RandString}'
var prodAppServicePlanName = 'asp-prod-${RGLocation}-001-${RandString}'
var prodAppServiceName = 'as-prod-${RGLocation}-001-${RandString}'
var logAnalyticsWorkspaceName = 'log-core-${RGLocation}-001-${RandString}'
var recoveryServiceVaultName = 'rsv-core-${RGLocation}-001'

//Prefixes
var prodVnetAddressPrefix = '10.31'
var devVnetAddressPrefix = '10.30'
var coreVnetAddressPrefix = '10.20'
var hubVnetAddressPrefix = '10.10'

//tags
var hubTag ={ Dept:'Hub', Owner:'HubOwner'}
var coreTag ={ Dept:'Core', Owner:'CoreOwner'}
var prodTag ={ Dept:'Prod', Owner:'ProdOwner'}
var devTag ={ Dept:'Dev', Owner:'DevOwner'}
var coreServicesTag ={ Dept:'CoreServices', Owner:'CoreServicesOwner'}


resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: CoreSecVaultName
}
resource defaultNSG 'Microsoft.Network/networkSecurityGroups@2023-05-01' ={
  name: DefaultNSGName
  location:RGLocation
  tags:coreServicesTag
}
resource routeTable 'Microsoft.Network/routeTables@2019-11-01' = {
  name: 'routetable-${RGLocation}-001'
  location: RGLocation
  tags:hubTag
}
module coreServices 'modules/coreServices.bicep'={
  name:'coreServicesDeployment'
  params:{
    coreVnetName :coreVnetName
    devVnetName :devVnetName
    hubVnetName :hubVnetName
    prodVnetName :prodVnetName
    RGLocation:RGLocation
    logAnalyticsWorkspaceName:logAnalyticsWorkspaceName
    recoveryServiceVaultName:recoveryServiceVaultName
    coreVnetAddress:'${coreVnetAddressPrefix}.0.0/16'
    devVnetAddress: '${devVnetAddressPrefix}.0.0/16'
    prodVnetAddress:'${prodVnetAddressPrefix}.0.0/16'
    hubVnetAddress:'${hubVnetAddressPrefix}.0.0/16'
    devTag:devTag
    hubTag:hubTag
    coreTag:coreTag
    prodTag:prodTag
    coreServicesTag:coreServicesTag
  }
}
module devSpoke 'modules/spoke.bicep'={
  name:'devSpokeDeployment'
  params:{
    RGLocation:RGLocation
    devOrProd:'dev'
    vnetAddressPrefix:devVnetAddressPrefix
    randString: RandString
    adminUsername:keyVault.getSecret('SQLAdminUsername')
    adminPassword:keyVault.getSecret('SQLAdminPassword')
    defaultNSGName:defaultNSG.name
    routeTableName:routeTable.name
    appServicePrivateDnsZoneName:coreServices.outputs.appServicePrivateDnsZoneName
    sqlPrivateDnsZoneName:coreServices.outputs.sqlPrivateDnsZoneName
    storageAccountPrivateDnsZoneName:coreServices.outputs.storageAccountPrivateDnsZoneName
    appServiceName:devAppServiceName
    appServicePlanName:devAppServicePlanName
    logAnalyticsWorkspaceName:logAnalyticsWorkspaceName
    tagSpoke:devTag
  }
  dependsOn:[coreServices]
}
module prodSpoke 'modules/spoke.bicep'={
  name:'prodSpokeDeployment'
  params:{
    RGLocation:RGLocation
    devOrProd:'prod'
    vnetAddressPrefix:prodVnetAddressPrefix
    randString: RandString
    adminUsername:keyVault.getSecret('SQLAdminUsername')
    adminPassword:keyVault.getSecret('SQLAdminPassword')
    defaultNSGName:defaultNSG.name
    routeTableName:routeTable.name
    appServicePrivateDnsZoneName:coreServices.outputs.appServicePrivateDnsZoneName
    sqlPrivateDnsZoneName:coreServices.outputs.sqlPrivateDnsZoneName
    storageAccountPrivateDnsZoneName:coreServices.outputs.storageAccountPrivateDnsZoneName
    appServiceName:prodAppServiceName
    appServicePlanName:prodAppServicePlanName
    logAnalyticsWorkspaceName:logAnalyticsWorkspaceName
    tagSpoke:prodTag
  }
  dependsOn:[coreServices]
}
module hub 'modules/hub.bicep'={
  name:'hubDeployment'
  params:{
    RGLocation:RGLocation
    vnetAddressPrefix:hubVnetAddressPrefix
    GatewaySubnetName:GatewaySubnetName
    AppgwSubnetName:AppgwSubnetName
    AzureFirewallSubnetName:AzureFirewallSubnetName
    AzureBastionSubnetName:AzureBastionSubnetName
    firewallName:firewallName
    prodAppServiceName:prodAppServiceName
    logAnalyticsWorkspaceName:logAnalyticsWorkspaceName
    hubTag:hubTag
  }
  dependsOn:[coreServices
    prodSpoke]
}
/*
module hubGateway 'modules/hubGateway.bicep'= {
  name:'hubGatewayDeployment'
  params:{
    GatewaySubnetName: hub.outputs.HubGatewayName
    RGLocation: RGLocation
    virtualNetworkName: hub.outputs.HubVNName
  }
  dependsOn:[hub
    peerings] // so deploys at end
}
*/
module core 'modules/core.bicep'={
  name:'coreDeployment'
  params:{
    RGLocation:RGLocation
    vnetAddressPrefix:coreVnetAddressPrefix
    adminUsername:keyVault.getSecret('VMAdminUsername')
    adminPassword:keyVault.getSecret('VMAdminPassword')
    defaultNSGName:defaultNSG.name
    routeTableName:routeTable.name
    logAnalyticsWorkspaceName:logAnalyticsWorkspaceName
    recoveryServiceVaultName:recoveryServiceVaultName
    keyVaultPrivateDnsZoneName:coreServices.outputs.encryptKVPrivateDnsZoneName
    CoreEncryptKeyVaultName:CoreEncryptKeyVaultName
    RecoverySAName:'sacore${RGLocation}${RandString}'
    coreTag:coreTag
  }
  dependsOn:[coreServices]
}
module peerings 'modules/peerings.bicep'={
  name:'peeringsDeployment'
  params:{
    RGLocation:RGLocation
    firewallPrivateIP:hub.outputs.firewallPrivateIP
    hubTag:hubTag
  }
  dependsOn:[
    devSpoke
    prodSpoke
    hub
    core
  ]
}
