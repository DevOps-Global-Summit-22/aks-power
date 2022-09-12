@description('The location where resources should be deployed.')
param location string = resourceGroup().location

@description('Environment of the deployment. Allowed values are dev prepro and prod.')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('The address space for the subnet Cosmos.')
param snetCosmosAddressSpace string = '10.0.0.0/29'

@description('The address space for the subnet Key Vault.')
param snetkvAddressSpace string = '10.0.0.8/29'

@description('The address space for the subnet Container Registry.')
param snetcrAddressSpace string = '10.0.0.16/29'

@description('The address space for the subnet Aks.')
param snetAksAddressSpace string = '10.0.1.0/24'

@description('The address space for the subnet of the AKS ingress controller.')
param snetaksagwAddressSpace string = '10.0.2.0/24'

// Spoke mp virtual network vnet

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'aks-power-netw-${environment}-we-vnet'
  location: location
  properties: {
    enableDdosProtection: false
    addressSpace: {
      addressPrefixes: [
        snetCosmosAddressSpace
        snetkvAddressSpace
        snetcrAddressSpace
        snetAksAddressSpace
        snetaksagwAddressSpace
      ]
    }
    subnets: [
      {
        name: 'aks-power-netw-${environment}-we-cosmos-snet'
        properties: {
          addressPrefix: snetCosmosAddressSpace
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'aks-power-netw-${environment}-we-kv-snet'
        properties: {
          addressPrefix: snetkvAddressSpace
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'aks-power-netw-${environment}-we-cr-snet'
        properties: {
          addressPrefix: snetcrAddressSpace
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'aks-power-netw-${environment}-we-aks-snet'
        properties: {
          addressPrefix: snetAksAddressSpace
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'aks-power-netw-${environment}-we-aks-agw-snet'
        properties: {
          addressPrefix: snetaksagwAddressSpace
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

//outputs
@description('vnet Name')
output spokeVnetName string = vnet.name

@description('vnet Id')
output vnetID string = vnet.id
