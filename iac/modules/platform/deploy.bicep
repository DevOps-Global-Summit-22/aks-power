targetScope = 'subscription'

@description('The location where resources should be deployed.')
param location string = deployment().location

@description('Infra Resource Group Name')
param spokeResourceGroupName string

@description('Jump Resource Group Name')
param jumpResourceGroupName string

resource spoke_rg 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  location: location
  name: spokeResourceGroupName
  properties: {}
}

resource jump_rg 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  location: location
  name: jumpResourceGroupName
  properties: {}
}

@description('The name of the spoke resource group')
output spokeResourceGroupName string = spoke_rg.name

@description('The name of the jump resource group')
output jumpResourceGroupName string = jump_rg.name
