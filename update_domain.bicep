@description('url for html5 client')
param html5ClientUrl string

@description('url for api client')
param apiUrl string


var profileName = 'PhotoCDN'
var endpointName = 'photoalbum${uniqueString(resourceGroup().id)}'
var functionAppName = 'fn${uniqueString(resourceGroup().id)}'

resource uiCustomDomain 'Microsoft.Cdn/profiles/endpoints/customDomains@2021-06-01' = {
  name: '${profileName}/${endpointName}/ui'
  properties: {
    hostName: html5ClientUrl
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}
resource apiCustomDomain 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: apiUrl
  parent: functionApp
  properties: {
    azureResourceType: 'Website'
    customHostNameDnsRecordType: 'CName'
    hostNameType: 'Verified'
    sslState: 'Disabled'
  }
}
