targetScope = 'subscription'

@description('The location where resources should be deployed.')
param location string = deployment().location

@description('Environment of the deployment. Allowed values are dev prepro and prod.')
@allowed([
  'dev'
  'prod'
])
param environment string

var resourceGroupName = 'aks-power-${environment}-we-rg'

module platform 'modules/platform/deploy.bicep' = {
  name: 'platform-deployment'
  params: {
    location: location
    resourceGroupName: resourceGroupName
  }
}

module identity 'modules/identity/deploy.bicep' = {
  name: 'identity-deployment'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    environment: environment
    location: location
  }
  dependsOn: [
    platform
  ]
}
