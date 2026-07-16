// main.bicep
//
// Deploys a single tagged storage account, deliberately simple - the point
// of this project is the deployment mechanism, not the complexity of what
// is deployed.

@description('Name of the storage account - must be globally unique, lowercase alphanumeric only')
param storageAccountName string

@description('Azure region for the storage account')
param location string = resourceGroup().location

@description('Environment tag value')
@allowed([
  'NonProduction'
  'Production'
])
param environmentTag string = 'NonProduction'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: {
    CostCenter: 'LAB001'
    Owner: 'jane'
    Environment: environmentTag
    DeployedBy: 'github-actions-oidc'
    LastUpdated: 'PipelineRepeatabilityTest'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryEndpoint string = storageAccount.properties.primaryEndpoints.blob
