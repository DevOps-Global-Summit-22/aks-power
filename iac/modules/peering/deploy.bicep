@description('Environment of the deployment. Allowed values are dev prepro and prod.')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('The location where jump resources should be deployed.')
param jumpResourceGroupName string

//Existing resources
resource spoke_vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: 'aks-power-netw-${environment}-we-vnet'
}

//Existing resources
resource jump_vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  scope: resourceGroup(subscription().subscriptionId, jumpResourceGroupName)
  name: 'aks-power-jump-netw-${environment}-we-vnet'
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: 'spoke-to-jump-${environment}'
  parent: spoke_vnet
  properties: {
    peeringState: 'Connected'
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: jump_vnet.properties.addressSpace.addressPrefixes
    }
  }
}
