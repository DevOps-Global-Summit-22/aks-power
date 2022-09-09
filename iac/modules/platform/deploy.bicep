targetScope = 'subscription'

@description('The location where resources should be deployed.')
param location string = deployment().location

@description('Infra Resource Group Name')
param resourceGroupName string

resource rg 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  location: location
  name: resourceGroupName
  properties: {}
}

@description('The name of the mp infra resource group')
output resourceGroupName string = rg.name
