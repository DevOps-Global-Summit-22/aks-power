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

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'aks-power-${environment}-we-jump-vm-nic'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: environment == 'prod' ? 'akspowerprojump' : 'akspower${environment}jump'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }

    osProfile: {
      computerName: environment == 'prod' ? 'akspowerprojump' : 'akspower${environment}jump'
      adminUsername: 'githubuser'
      adminPassword: 'GitHubuser$2022'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-11'
        sku: 'win11-22h2-pro'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource nic_ghrunner 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'aks-power-${environment}-we-run-vm-nic'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource vm_ghrunner 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: environment == 'prod' ? 'akspowerprorun' : 'akspower${environment}run'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }

    osProfile: {
      computerName: 'akspower${environment}run'
      adminUsername: 'githubuser'
      adminPassword: 'GitHubuser$2022'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic_ghrunner.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}
