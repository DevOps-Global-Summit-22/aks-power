@description('The location where resources should be deployed.')
param location string = resourceGroup().location

@description('Environment of the deployment. Allowed values are dev prepro and prod.')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('The location where spoke resources should be deployed.')
param spokeResourceGroupName string

@description('The address space for the subnet jump.')
param snetJumpAddressSpace string = '192.178.3.0/24'

@description('The address space for the subnet bastion.')
param snetBastionAddressSpace string = '192.178.4.0/24'

//Existing resources
resource spoke_vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  scope: resourceGroup(subscription().subscriptionId, spokeResourceGroupName)
  name: 'aks-power-netw-${environment}-we-vnet'
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'aks-power-jump-netw-${environment}-we-vnet'
  location: location
  properties: {
    enableDdosProtection: false
    addressSpace: {
      addressPrefixes: [
        snetJumpAddressSpace
        snetBastionAddressSpace
      ]
    }
    subnets: [
      {
        name: 'aks-power-netw-${environment}-we-jump-snet'
        properties: {
          addressPrefix: snetJumpAddressSpace
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: snetBastionAddressSpace
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: 'jump-to-spoke-${environment}'
  parent: vnet
  properties: {
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: spoke_vnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: spoke_vnet.properties.addressSpace.addressPrefixes
    }
  }
}

resource bastion_pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'aks-power-${environment}-we-bastion-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}

resource bastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: 'bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    disableCopyPaste: false
    enableFileCopy: true
    ipConfigurations: [
      {
        name: 'ipconf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastion_pip.id
          }
          subnet: {
            id: vnet.properties.subnets[1].id
          }
        }
      }
    ]
  }
}
