targetScope = 'subscription'

@description('The location where resources should be deployed.')
param location string = deployment().location

@description('Environment of the deployment. Allowed values are dev prepro and prod.')
@allowed([
  'dev'
  'prod'
])
param environment string = 'dev'

var spokeResourceGroupName = 'aks-power-${environment}-we-rg'
var jumpResourceGroupName = 'aks-power-jump-${environment}-we-rg'
module platform 'modules/platform/deploy.bicep' = {
  name: 'platform-deployment'
  params: {
    location: location
    spokeResourceGroupName: spokeResourceGroupName
    jumpResourceGroupName: jumpResourceGroupName
  }
}

module identity 'modules/identity/deploy.bicep' = {
  name: 'identity-deployment'
  scope: resourceGroup(subscription().subscriptionId, spokeResourceGroupName)
  params: {
    environment: environment
    location: location
  }
  dependsOn: [
    platform
  ]
}

module roleAssignment 'modules/roleAssignments/deploy.bicep' = {
  scope: resourceGroup(subscription().subscriptionId, spokeResourceGroupName)
  name: 'role-assignment-deployment'
  params: {
    principalId: identity.outputs.aksPrincipalId
    roleDefinitionId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' //Owner
  }
}

module network 'modules/network/deploy.bicep' = {
  name: 'network-deployment'
  scope: resourceGroup(subscription().subscriptionId, spokeResourceGroupName)
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
  scope: resourceGroup(subscription().subscriptionId, spokeResourceGroupName)
  params: {
    environment: environment
    location: location
  }
  dependsOn: [
    network
  ]
}

module jump 'modules/jump/deploy.bicep' = {
  name: 'jump-deployment'
  scope: resourceGroup(subscription().subscriptionId, jumpResourceGroupName)
  params: {
    environment: environment
    location: location
    spokeResourceGroupName: spokeResourceGroupName
  }
  dependsOn: [
    network
  ]
}

module peering 'modules/peering/deploy.bicep' = {
  name: 'peering-deployment'
  scope: resourceGroup(subscription().subscriptionId, spokeResourceGroupName)
  params: {
    environment: environment
    jumpResourceGroupName: jumpResourceGroupName
  }
  dependsOn: [
    jump
  ]
}

module spoke 'modules/spoke-mp/deploy.bicep' = {
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
