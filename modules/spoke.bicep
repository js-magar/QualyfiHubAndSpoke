@allowed([
  'dev'
  'prod'
])
param devOrProd string = 'dev'
param RGLocation string
param vnetAddressPrefix string
param randString string

var virtualNetworkName = 'vnet-${devOrProd}-${RGLocation}-001'
var appServicePlanName = 'asp-${devOrProd}-${RGLocation}-001--${randString}'
var appServicePlanSku = 'B1'
var appServiceName = 'as-${devOrProd}-${RGLocation}-001--${randString}'
var appServiceSubnetName ='AppSubnet'

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
        name: appServiceSubnetName

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
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01'={
  name: appServicePlanName
  location:RGLocation
  kind: 'linux'
  sku:{name: appServicePlanSku }
}
resource appService 'Microsoft.Web/sites@2022-09-01' ={
  name:appServiceName
  location:RGLocation
  properties:{
    serverFarmId:appServicePlan.id
    siteConfig:{
      linuxFxVersion:'DOTNETCORE:7.0'
    }
  }
}
resource codeAppService 'Microsoft.Web/sites/sourcecontrols@2022-09-01' ={
  parent: appService
  name:'web'
  properties:{
    repoUrl:'https://github.com/Azure-Samples/dotnetcore-docs-hello-world'
    branch:'master'
  }
}
resource AppServiceSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: appServiceSubnetName,parent: virtualNetwork}

resource appServicePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' ={
  name:'private-endpoint-${appService.name}'
  location:RGLocation
  properties:{
    subnet:{
      id:AppServiceSubnet.id
    }
    privateLinkServiceConnections:[
      {
        name:'private-endpoint-${appService.name}'
        properties:{
          privateLinkServiceId: appService.id
          groupIds:[
            'sites'
          ]
        }
  }]
  }
}





