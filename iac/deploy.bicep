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
