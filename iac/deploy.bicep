targetScope = 'subscription'

@description('The location where resources should be deployed.')
param location string = deployment().location

@description('Environment of the deployment. Allowed values are dev prepro and prod.')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('The AKS windows pool username.')
param windowsProfileUsername string

@description('The AKS windows pool password.')
param windowsProfilePassword string

@description('The address space for the subnet Cosmos.')
param snetCosmosAddressSpace string

@description('The id of the subscription where the log analytics is.')
param monSubscriptionId string

@description('Aks admin group Object Id.')
param aksAdminGroup string

@description('If we should deploy the AKS Application Gateway')
param deployAgwAKS string

@description('If we should deploy role assignemnts')
param deployRoleAssignments string

var resourceGroupName = 'aks-power-${environment}-we-rg'
var spokeVnetName = 'aks-power-${environment}-we-vnet'

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

module spokeMP 'modules/spoke-mp/deploy.bicep' = {
  name: 'infraSpoke-deployment'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    environment: environment
    location: location
    spokeVnetName: spokeVnetName
    windowsProfileUsername: windowsProfileUsername
    windowsProfilePassword: windowsProfilePassword
    aksAdminGroup: aksAdminGroup
    deployAgwAKS: deployAgwAKS
    deployRoleAssignments: deployRoleAssignments
  }
  dependsOn: [
    platform
  ]
}

module roleAssignments 'modules/roleAssignments/deploy.bicep' = if (deployRoleAssignments == 'True') {
  name: 'roleAssignments-aks-deployment'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c' //Contributor
    principalId: spokeMP.outputs.aksPrincipalId
  }
  dependsOn: [
    platform
    spokeMP
  ]
}
