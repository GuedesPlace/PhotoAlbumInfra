@description('location for resources')
param location string= resourceGroup().location

@description('location for resources')
param locationCDN string= 'northeurope'

var applicationInsightsName = 'ai${uniqueString(resourceGroup().id)}'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

module web 'web.bicep' = {
  name:'webSpace'
  params:{
    location:location
    locationCDN:locationCDN
  }
}
module api 'api.bicep' = {
  name: 'functionApi'
  params:{
    location:location
    instrumentaitionKey:applicationInsights.properties.InstrumentationKey
  }
}

output aiConnectionString string = applicationInsights.properties.ConnectionString
output html5ClientUrl string = web.outputs.cdnWebsiteHost
output apiUrl string = api.outputs.functionUrl
output apiVerificationId string = api.outputs.verificationId

