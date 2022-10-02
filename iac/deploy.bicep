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

module roleAssignment 'modules/roleAssignments/deploy.bicep' = {
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  name: 'role-assignment-deployment'
  params: {
    principalId: identity.outputs.aksPrincipalId
    roleDefinitionId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' //Owner
  }
}

module network 'modules/network/deploy.bicep' = {
  name: 'network-deployment'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    environment: environment
    location: location
  }
  dependsOn: [
    platform
    roleAssignment
  ]
}

module spoke 'modules/spoke/deploy.bicep' = {
  name: 'infraSpoke-deployment'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    environment: environment
    location: location
  }
  dependsOn: [
    network
  ]
}
