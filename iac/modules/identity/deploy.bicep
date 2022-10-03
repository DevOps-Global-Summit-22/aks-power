@description('The location where resources should be deployed.')
param location string = resourceGroup().location

@description('Environment of the deployment. Allowed values are dev prepro and prod.')
@allowed([
  'dev'
  'prod'
])
param environment string

resource aks_msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'aks-power-${environment}-we-aks-id'
  location: location
}

@description('AKS principal id.')
output aksPrincipalId string = aks_msi.properties.principalId
