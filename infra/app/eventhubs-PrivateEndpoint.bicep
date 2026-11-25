param location string
param tags object = {}
param vNetName string
param eventHubSubnetName string
param eventHubNamespaceId string

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vNetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnet
  name: eventHubSubnetName
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.servicebus.windows.net'
  location: 'global'
  tags: tags
}

resource dnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${vNetName}-eventhub-link'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: 'eventhub-private-endpoint'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'eventhub-connection'
        properties: {
          privateLinkServiceId: eventHubNamespaceId
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-09-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'eventhub'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}
