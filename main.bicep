

param RGName string
param RGLocation string
param CoreSecretsKeyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: CoreSecretsKeyVaultName
}

module devSpoke 'modules/spoke.bicep'={
  name:'devSpokeDeployment'
  params:{
    RGLocation:RGLocation
    devOrProd:'dev'
    vnetAddressPrefix:'10.30'
  }
}
module prodSpoke 'modules/spoke.bicep'={
  name:'prodSpokeDeployment'
  params:{
    RGLocation:RGLocation
    devOrProd:'prod'
    vnetAddressPrefix:'10.31'
  }
}
module hub 'modules/hub.bicep'={
  name:'hubDeployment'
  params:{
    RGLocation:RGLocation
    vnetAddressPrefix:'10.10'
  }
}
module core 'modules/core.bicep'={
  name:'coreDeployment'
  params:{
    RGLocation:RGLocation
    vnetAddressPrefix:'10.20'
    adminUsername:keyVault.getSecret('VMAdminUsername')
    adminPassword:keyVault.getSecret('VMAdminPassword')
  }
}
module peerings 'modules/peerings.bicep'={
  name:'peeringsDeployment'
  params:{
    RGLocation:RGLocation
  }
  dependsOn:[
    devSpoke
    prodSpoke
    hub
    core
  ]
}
