param location string= resourceGroup().location
@description('instrumentationkey of application insight.')
param instrumentaitionKey string

var storageAccountType = 'Standard_LRS'


var functionAppName = 'fn${uniqueString(resourceGroup().id)}'
var hostingPlanName = 'plan${uniqueString(resourceGroup().id)}'
var storageAccountNameFunction = 'safun${uniqueString(resourceGroup().id)}'
var functionWorkerRuntime = 'dotnet'

resource storageAccountFunction 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountNameFunction
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}



resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountNameFunction};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountFunction.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountNameFunction};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountFunction.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~10'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: instrumentaitionKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}
output functionUrl string = functionApp.properties.defaultHostName
output verificationId string = functionApp.properties.customDomainVerificationId
