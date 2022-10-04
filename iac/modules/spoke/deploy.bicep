@description('The location where resources should be deployed.')
param location string = resourceGroup().location

@description('Environment of the deployment. Allowed values are dev prepro and prod.')
@allowed([
  'dev'
  'prod'
])
param environment string

var aksKubernetesVersion = '1.23.5'

//IP Calculations
var agwSubnetAddress = split(split(spoke_vnet::agw_subnet.properties.addressPrefix, '/')[0], '.')
var agwfinalAddress = int(agwSubnetAddress[3]) + 4
var agwIpAddress = '${agwSubnetAddress[0]}.${agwSubnetAddress[1]}.${agwSubnetAddress[2]}.${string(agwfinalAddress)}'

//Virtual Network
resource spoke_vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: 'aks-power-netw-${environment}-we-vnet'

  resource agw_subnet 'subnets@2021-05-01' existing = {
    name: 'aks-power-netw-${environment}-we-aks-agw-snet'
  }
}

//Application Gateway
resource agw_pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'aks-power-${environment}-we-agw-aks-pip'
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

resource agw 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: 'aks-power-${environment}-we-aks-agw'
  location: location
  properties: {
    autoscaleConfiguration: {
      maxCapacity: (environment == 'prod') ? 4 : 2
      minCapacity: (environment == 'prod') ? 2 : 1
    }
    backendAddressPools: [
      {
        name: 'aks-power-${environment}-we-agw-aks-pool'
        properties: {
          backendAddresses: [
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'aks-power-${environment}-we-agw-aks-http'
        properties: {
          connectionDraining: {
            drainTimeoutInSec: 60
            enabled: true
          }
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          port: 80
          protocol: 'Http'
          requestTimeout: 30
        }
      }
    ]
    enableHttp2: true
    frontendIPConfigurations: [
      {
        name: 'appGatewayPublicFrontendIP'
        properties: {
          publicIPAddress: {
            id: agw_pip.id
          }
        }
      }
      {
        name: 'appGatewayPrivateFrontendIP'
        properties: {
          privateIPAddress: agwIpAddress
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: spoke_vnet::agw_subnet.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: spoke_vnet::agw_subnet.id
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'aks-power-${environment}-we-agw-aks-listener-001'
        properties: {
          frontendIPConfiguration: {
            id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/aks-power-${environment}-we-aks-agw/frontendIPConfigurations/appGatewayPrivateFrontendIP'
          }
          frontendPort: {
            id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/aks-power-${environment}-we-aks-agw/frontendPorts/port_80'
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'aks-power-${environment}-we-agw-aks-rule'
        properties: {
          backendAddressPool: {
            id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/aks-power-${environment}-we-aks-agw/backendAddressPools/aks-power-${environment}-we-agw-aks-pool'
          }
          backendHttpSettings: {
            id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/aks-power-${environment}-we-aks-agw/backendHttpSettingsCollection/aks-power-${environment}-we-agw-aks-http'
          }
          httpListener: {
            id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/aks-power-${environment}-we-aks-agw/httpListeners/aks-power-${environment}-we-agw-aks-listener-001'
          }
        }
      }
    ]
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    sslCertificates: []
    trustedRootCertificates: []
    sslProfiles: []
    trustedClientCertificates: []
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}

//Cosmos DB
resource cosmos_account 'Microsoft.DocumentDB/databaseAccounts@2021-10-15-preview' = {
  name: 'aks-power-${environment}-we-cosmosdb'
  kind: 'GlobalDocumentDB'
  location: location
  tags: {
    'defaultExperience': 'Core (SQL)'
    'hidden-cosmos-mmspecial': ''
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    isVirtualNetworkFilterEnabled: false
    virtualNetworkRules: []
    disableKeyBasedMetadataWriteAccess: false
    enableFreeTier: false
    enableAnalyticalStorage: false
    analyticalStorageConfiguration: {
      schemaType: 'WellDefined'
    }
    databaseAccountOfferType: 'Standard'
    defaultIdentity: 'FirstPartyIdentity'
    networkAclBypass: 'None'
    disableLocalAuth: false
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: true
      }
    ]
    cors: []
    capabilities: []
    ipRules: []
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 8
        backupStorageRedundancy: 'Geo'
      }
    }
    networkAclBypassResourceIds: []
    diagnosticLogSettings: {
      enableFullTextQuery: 'None'
    }
  }
}

// Cosmos DB SQL DB 
resource sqldb_encrypted_document 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-11-15-preview' = {
  name: 'EncryptedDocumentsDatabase'
  parent: cosmos_account
  properties: {
    resource: {
      id: 'EncryptedDocumentsDatabase'
    }
    options: {
      autoscaleSettings: {
        maxThroughput: 4000
      }
    }
  }
}

// Cosmos Private Endpoint
resource pe_cosmos 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'aks-power-${environment}-we-cosmos-pe'
  dependsOn: [
    spoke_vnet
  ]

  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'aks-power-${environment}-we-cosmos-pl_1'
        properties: {
          privateLinkServiceId: cosmos_account.id
          groupIds: [
            'Sql'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '${spoke_vnet.id}/subnets/aks-power-netw-${environment}-we-cosmos-snet'
    }
  }
}

// Azure KeyVault

resource kv 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: 'akspower${environment}wakv'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

resource pe_kvt 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'aks-power-${environment}-we-kv-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'aks-power-${environment}-we-kv-pl'
        properties: {
          privateLinkServiceId: kv.id
          groupIds: [
            'vault'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '${spoke_vnet.id}/subnets/aks-power-netw-${environment}-we-kv-snet'
    }
    customDnsConfigs: []
  }
}

//Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: 'akspower${environment}wacr'
  location: location

  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'enabled'
      }
      exportPolicy: {
        status: 'enabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    anonymousPullEnabled: false
  }
}

resource pe_cr 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'aks-power-${environment}-we-cr-pe'
  dependsOn: [
    spoke_vnet
  ]
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'aks-power-${environment}-we-cr-pl'
        properties: {
          privateLinkServiceId: containerRegistry.id
          groupIds: [
            'registry'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '${spoke_vnet.id}/subnets/aks-power-netw-${environment}-we-cr-snet'
    }
    customDnsConfigs: []
  }
}

// AKS 

resource aks_msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: 'aks-power-${environment}-we-aks-id'
}

resource pdns_aks 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'aks-pdns-${environment}.privatelink.${location}.azmk8s.io'
  location: location
}

resource pdns_aks_vnet_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  dependsOn: [
    spoke_vnet
  ]
  name: 'aks-pdns-${environment}-spoke-vnet-link'
  location: location
  parent: pdns_aks
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: spoke_vnet.id
    }
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2022-01-02-preview' = {
  name: 'aks-power-${environment}-we-aks'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aks_msi.id}': {}
    }
  }
  sku: {
    name: 'Basic'
    tier: 'Paid'
  }
  properties: {
    kubernetesVersion: aksKubernetesVersion
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
    dnsPrefix: 'aks-power-${environment}-we-aks'

    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0
        count: 1
        vmSize: 'Standard_D4s_v5'
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        mode: 'System'
        maxPods: 110
        maxCount: 20
        minCount: 1
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: '${spoke_vnet.id}/subnets/aks-power-netw-${environment}-we-aks-snet'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        enableAutoScaling: true
      }
    ]
    windowsProfile: {
      adminUsername: 'usernameakspower'
      adminPassword: 'AKSPowerGlobalSummit2022'
      enableCSIProxy: true
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    enableRBAC: true
    identityProfile: {
      kubeletidentity: {
        resourceId: aks_msi.id
        clientId: aks_msi.properties.clientId
        objectId: aks_msi.properties.principalId
      }
    }
    nodeResourceGroup: 'aks-power-autogenerated-aks-${environment}-we-rg'
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      outboundType: 'loadBalancer'
      loadBalancerSku: 'standard'
    }

    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: pdns_aks.id
      enablePrivateClusterPublicFQDN: false
    }
    addonProfiles: {
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: agw.id
        }
      }
    }
  }
}

resource agent_pool_windows 'Microsoft.ContainerService/managedClusters/agentPools@2021-08-01' = {
  name: 'winmf'
  parent: aks
  properties: {
    count: 1
    enableFIPS: false
    orchestratorVersion: aksKubernetesVersion
    kubeletDiskType: 'OS'
    maxPods: 30
    maxCount: 20
    minCount: 1
    nodeLabels: {
      usePPG: 'true'
    }
    enableAutoScaling: true
    mode: 'User'
    osType: 'Windows'
    osDiskType: 'Managed'
    type: 'VirtualMachineScaleSets'
    vmSize: 'Standard_D4s_v5'
    vnetSubnetID: '${spoke_vnet.id}/subnets/aks-power-netw-${environment}-we-aks-snet'
  }
}

resource agent_pool_linux 'Microsoft.ContainerService/managedClusters/agentPools@2021-08-01' = {
  name: 'lin'
  parent: aks
  properties: {
    count: 1
    maxCount: 5
    minCount: 1
    nodeLabels: {
      usePPG: 'false'
    }
    enableFIPS: false
    enableAutoScaling: true
    orchestratorVersion: aksKubernetesVersion
    kubeletDiskType: 'OS'
    maxPods: 30
    mode: 'User'
    osType: 'Linux'
    osSKU: 'Ubuntu'
    osDiskType: 'Managed'
    type: 'VirtualMachineScaleSets'
    vmSize: 'Standard_D4s_v5'
    vnetSubnetID: '${spoke_vnet.id}/subnets/aks-power-netw-${environment}-we-aks-snet'
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
  }
}

@description('AKS principal id.')
output aksPrincipalId string = aks_msi.properties.principalId
