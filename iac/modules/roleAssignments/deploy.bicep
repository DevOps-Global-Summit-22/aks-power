@description('AKS principal id.')
param principalId string

@description('RoleDefinitionId')
param roleDefinitionId string

resource roleDefinitionResource 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: roleDefinitionId
}

resource role_assignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionResource.id)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleDefinitionResource.id
  }
  scope: resourceGroup()
}
