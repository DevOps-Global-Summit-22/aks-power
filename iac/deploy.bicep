targetScope = 'subscription'

@description('The location where resources should be deployed.')
param location string = deployment().location

@description('Environment of the deployment. Allowed values are dev prepro and prod.')
@allowed([
  'dev'
  'prod'
])
param environment string = 'dev'

@description('The AKS windows pool username.')
param windowsProfileUsername string = 'username01'

@description('The AKS windows pool password.')
param windowsProfilePassword string = 'AKSPowerDemo01'

@description('The address space for the subnet Cosmos.')
param snetCosmosAddressSpace string = '0.0.0.0/0'

@description('If we should deploy the AKS Application Gateway')
param deployAgwAKS string = '1'

@description('If we should deploy role assignemnts')
param deployRoleAssignments string = '1'

var resourceGroupName = 'aks-power-${environment}-we-rg'
var spokeVnetName = 'aks-power-${environment}-we-vnet'

module platform 'modules/platform/deploy.bicep' = {
  name: 'platform-deployment'
  params: {
    location: location
    resourceGroupName: resourceGroupName
  }
}
