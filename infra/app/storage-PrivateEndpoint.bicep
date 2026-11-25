param location string
param tags object = {}
param virtualNetworkName string
param subnetName string
param resourceName string
param enableBlob bool = true
param enableQueue bool = false
param enableTable bool = false

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: virtualNetworkName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: resourceName
}

var services = [
  {
    name: 'blob'
    enabled: enableBlob
  }
  {
    name: 'queue'
    enabled: enableQueue
  }
  {
    name: 'table'
    enabled: enableTable
  }
]

module privateDnsZones 'br/public:avm/res/network/private-dns-zone:0.7.1' = [for service in services: if (service.enabled) {
  name: '${service.name}-private-dns-zone-deployment'
  params: {
    name: 'privatelink.${service.name}.${environment().suffixes.storage}'
    location: 'global'
    tags: tags
    virtualNetworkLinks: [
      {
        name: '${resourceName}-${service.name}-link-${take(uniqueString(resourceName, virtualNetworkName), 4)}'
        virtualNetworkResourceId: vnet.id
        registrationEnabled: false
        location: 'global'
        tags: tags
      }
    ]
  }
}]

module privateEndpoints 'br/public:avm/res/network/private-endpoint:0.11.0' = [for (service, i) in services: if (service.enabled) {
  name: '${service.name}-private-endpoint-deployment'
  params: {
    name: '${service.name}-private-endpoint'
    location: location
    tags: tags
    subnetResourceId: '${vnet.id}/subnets/${subnetName}'
    privateLinkServiceConnections: [
      {
        name: '${service.name}PrivateLinkConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            service.name
          ]
        }
      }
    ]
    customDnsConfigs: []
    privateDnsZoneGroup: {
      privateDnsZoneGroupConfigs: [
        {
          name: 'storage-${service.name}'
          privateDnsZoneResourceId: privateDnsZones[i]!.outputs.resourceId
        }
      ]
    }
  }
}]
