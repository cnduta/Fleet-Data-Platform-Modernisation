// ============================================================
// Fleet Data Platform Modernisation - Infrastructure as Code
// Author: Caroline Nduta
// Region: UK South
// ============================================================

param location string = 'uksouth'
param prefix string = 'fleetcn'
param environment string = 'prod'

// ============================================================
// KEY VAULT
// ============================================================
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'kv-${prefix}-${environment}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
  }
}

// ============================================================
// STORAGE ACCOUNT (ADLS Gen2)
// ============================================================
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${prefix}datalake${environment}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource bronzeContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/bronze'
  properties: {
    publicAccess: 'None'
  }
}

resource silverContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/silver'
  properties: {
    publicAccess: 'None'
  }
}

resource goldContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/gold'
  properties: {
    publicAccess: 'None'
  }
}

// ============================================================
// AZURE DATA FACTORY
// ============================================================
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: 'adf-${prefix}-${environment}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

// ============================================================
// EVENT HUBS NAMESPACE + HUB
// ============================================================
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' = {
  name: 'ehn-${prefix}-${environment}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 1
  }
  properties: {}
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2022-10-01-preview' = {
  parent: eventHubNamespace
  name: 'eh-fleet-events'
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
  }
}

// ============================================================
// LOG ANALYTICS WORKSPACE
// ============================================================
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-${prefix}-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ============================================================
// SYNAPSE WORKSPACE
// ============================================================
resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: 'synw-${prefix}-${environment}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: storageAccount.properties.primaryEndpoints.dfs
      filesystem: 'gold'
    }
    sqlAdministratorLogin: 'sqladmin'
    sqlAdministratorLoginPassword: 'FleetP@ss2024!'
  }
}

// ============================================================
// OUTPUTS
// ============================================================
output storageAccountName string = storageAccount.name
output dataFactoryName string = dataFactory.name
output synapseWorkspaceName string = synapseWorkspace.name
output eventHubNamespaceName string = eventHubNamespace.name
output keyVaultName string = keyVault.name
output logAnalyticsName string = logAnalytics.name
