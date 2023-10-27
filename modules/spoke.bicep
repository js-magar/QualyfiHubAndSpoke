@allowed([
  'dev'
  'prod'
])
param devOrProd string = 'dev'
param RGLocation string
param vnetAddressPrefix string
param randString string
@secure()
param adminUsername string
@secure()
param adminPassword string
param defaultNSGName string
param routeTableName string
param appServicePrivateDnsZoneName string 
param sqlPrivateDnsZoneName string 
param storageAccountPrivateDnsZoneName string
param appServicePlanName string
param appServiceName string
param logAnalyticsWorkspaceName string
param tagSpoke object

var virtualNetworkName = 'vnet-${devOrProd}-${RGLocation}-001'
var appServicePlanSku = 'B1'
var appServiceSubnetName ='AppSubnet'
var SQLServerName = 'sql-${devOrProd}-${RGLocation}-001-${randString}'
var SQLServerSku = 'Basic'
var SQLDatabaseName = 'sqldb-${devOrProd}-${RGLocation}-001-${randString}'
var SQLServerSubnetName ='SqlSubnet'
var storageAccountName = 'st${devOrProd}001${randString}'
var SASubnetName ='StSubnet'
var appServiceRepoURL = 'https://github.com/Azure-Samples/dotnetcore-docs-hello-world'
var appServicePrivateEndpointName = 'private-endpoint-${appService.name}'
var sqlServerPrivateEndpointName = 'private-endpoint-${sqlServer.name}'
var storageAccountPrivateEndpointName ='private-endpoint-${storageAccount.name}'

resource routeTable 'Microsoft.Network/routeTables@2019-11-01' existing = {name: routeTableName}

resource defaultNSG 'Microsoft.Network/networkSecurityGroups@2023-05-01' existing ={
  name: defaultNSGName
}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: virtualNetworkName
  location: RGLocation
  tags:tagSpoke
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
          networkSecurityGroup:{  id: defaultNSG.id }
          routeTable:{id:routeTable.id}
        }
      }
      {
        name: SQLServerSubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.2.0/24'
          networkSecurityGroup:{  id: defaultNSG.id }
          routeTable:{id:routeTable.id}
        }
      }
    ]
  }
}
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name:logAnalyticsWorkspaceName
}
resource storageAccountSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' = if (devOrProd == 'prod') {
  parent: virtualNetwork
  name: SASubnetName
  properties: {
    addressPrefix: '${vnetAddressPrefix}.3.0/24'
    networkSecurityGroup:{  id: defaultNSG.id }
    routeTable:{id:routeTable.id}
  }
}
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01'={
  name: appServicePlanName
  location:RGLocation
  tags:tagSpoke
  kind: 'linux'
  sku:{
    name: appServicePlanSku
    tier : 'Basic'
   }
  properties:{
    reserved:true
  }
}
resource appService 'Microsoft.Web/sites@2022-09-01' ={
  name:appServiceName
  location:RGLocation
  tags:tagSpoke
  properties:{
    serverFarmId:appServicePlan.id
    siteConfig:{
      linuxFxVersion:'DOTNETCORE|7.0'
      appSettings:[
        {
          name:'APPINSIGHTS_INSTRUMENTATIONKEY'
          value:applicationInsights.properties.InstrumentationKey
        }
        {
          name:'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value:applicationInsights.properties.ConnectionString
        }
        {
          name:'ApplicationInsightsAgent_EXTENSION_VERSION'
          value:'~3'
        }
        {
          name:'XDT_MicrosoftApplicationInsights_Mode'
          value:'default'
        }
      ]
      alwaysOn:true
    }
  }
}
resource codeAppService 'Microsoft.Web/sites/sourcecontrols@2022-09-01' ={
  parent: appService
  name:'web'
  properties:{
    repoUrl:appServiceRepoURL
    isManualIntegration:true
    branch:'master'
  }
}
resource AppServiceSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: appServiceSubnetName,parent: virtualNetwork
}
resource appServicePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' ={
  name:appServicePrivateEndpointName
  location:RGLocation
  tags:tagSpoke
  properties:{
    subnet:{
      id:AppServiceSubnet.id
    }
    privateLinkServiceConnections:[
      {
        name:appServicePrivateEndpointName
        properties:{
          privateLinkServiceId: appService.id
          groupIds:[
            'sites'
          ]
        }
  }]
  }
}
resource appServiceDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (devOrProd == 'prod') {
  name: '${devOrProd}-${RGLocation}-aSDiagnosticSettings'
  scope: appService
  properties: {
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspace.id
  }
  dependsOn:[
    applicationInsights
  ]
}
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name:'${devOrProd}-${RGLocation}-aSInsights'
  location:RGLocation
  tags:tagSpoke
  kind:'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}
//SQL
resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name:SQLServerName
  location:RGLocation
  tags:tagSpoke
  properties:{
    administratorLogin:adminUsername
    administratorLoginPassword:adminPassword
  }
}
resource sqlDB 'Microsoft.Sql/servers/databases@2021-11-01' = {
  name:SQLDatabaseName
  location:RGLocation
  tags:tagSpoke
  parent: sqlServer
  sku:{
    name:SQLServerSku
    tier:SQLServerSku
  }
}
resource SQLSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: SQLServerSubnetName,parent: virtualNetwork
}
resource sqlServerPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' ={
  name:sqlServerPrivateEndpointName
  location:RGLocation
  tags:tagSpoke
  properties:{
    subnet:{
      id:SQLSubnet.id
    }
    privateLinkServiceConnections:[
      {
        name:sqlServerPrivateEndpointName
        properties:{
          privateLinkServiceId: sqlServer.id
          groupIds:[
            'sqlServer'
          ]
        }
  }]
  }
}
//StorageAccount
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = if (devOrProd == 'prod') {
  name: storageAccountName
  kind: 'StorageV2'
  tags:tagSpoke
  location: RGLocation
  sku:{
    name:'Standard_LRS'
  }
}
resource storageAccountPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (devOrProd == 'prod') {
  name:storageAccountPrivateEndpointName
  location:RGLocation
  tags:tagSpoke
  properties:{
    subnet:{
      id:storageAccountSubnet.id
    }
    privateLinkServiceConnections:[
      {
        name:storageAccountPrivateEndpointName
        properties:{
          privateLinkServiceId: storageAccount.id
          groupIds:[
            'blob'
          ]
        }
  }]
  }
}
//DNS Settings
resource appServicePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: appServicePrivateDnsZoneName
}
resource privateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: appServicePrivateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: appServicePrivateDnsZone.id
        }
      }
    ]
  }
}
resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: sqlPrivateDnsZoneName
}
resource sqlPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: sqlServerPrivateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: sqlPrivateDnsZone.id
        }
      }
    ]
  }
}
resource storageAccountPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: storageAccountPrivateDnsZoneName
}
resource storageAccountPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (devOrProd == 'prod') {
  parent: storageAccountPrivateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: storageAccountPrivateDnsZone.id
        }
      }
    ]
  }
}

//SQLAudit https://learn.microsoft.com/en-us/azure/templates/microsoft.sql/servers/auditingsettings?pivots=deployment-language-bicep
//https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-database-engine?view=sql-server-ver16
//https://learn.microsoft.com/en-us/azure/azure-sql/database/auditing-overview?view=azuresql






