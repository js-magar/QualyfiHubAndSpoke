

param RGName string
param RGLocation string
param CoreSecretsKeyVaultName string

module devSpoke 'modules/spoke.bicep'={
  name:'devSpokeDeployment'
  params:{
    RGLocation:RGLocation
    devOrProd:'dev'
    vnetAddressPrefix:'10.30'
  }
}
