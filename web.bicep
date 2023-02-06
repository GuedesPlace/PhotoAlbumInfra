param location string= resourceGroup().location
param locationCDN string = 'northeurope'

var storageAccountType = 'Standard_LRS'
var storageAccountNameWeb = 'saweb${uniqueString(resourceGroup().id)}'
var endpointName = 'photoalbum${uniqueString(resourceGroup().id)}'

resource storageAccountWeb 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountNameWeb
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  // This is the Storage Account Contributor role, which is the minimum role permission we can give. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#:~:text=17d1049b-9a84-46fb-8f53-869881c3d3ab
  name: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'DeploymentScript'
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccountWeb
  name: guid(resourceGroup().id, managedIdentity.id, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deploymentScript'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  dependsOn: [
    // we need to ensure we wait for the role assignment to be deployed before trying to access the storage account
    roleAssignment
  ]
  properties: {
    azPowerShellVersion: '3.0'
    scriptContent: loadTextContent('./scripts/enable-static-website.ps1')
    retentionInterval: 'PT4H'
    environmentVariables: [
      {
        name: 'ResourceGroupName'
        value: resourceGroup().name
      }
      {
        name: 'StorageAccountName'
        value: storageAccountWeb.name
      }
      {
        name: 'IndexDocumentPath'
        value: 'index.html'
      }
      {
        name: 'ErrorDocument404Path'
        value: 'error.html'
      }
    ]
  }
}

resource profile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: 'PhotoCDN'
  location: locationCDN
  sku: {
    name: 'Standard_Microsoft'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/endpoints@2021-06-01' = {
  parent: profile
  name: endpointName
  location: locationCDN
  properties: {
    originHostHeader: substring(storageAccountWeb.properties.primaryEndpoints.web,8, length(storageAccountWeb.properties.primaryEndpoints.web)-9)
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: [
      'application/eot'
      'application/font'
      'application/font-sfnt'
      'application/javascript'
      'application/json'
      'application/opentype'
      'application/otf'
      'application/pkcs7-mime'
      'application/truetype'
      'application/ttf'
      'application/vnd.ms-fontobject'
      'application/xhtml+xml'
      'application/xml'
      'application/xml+rss'
      'application/x-font-opentype'
      'application/x-font-truetype'
      'application/x-font-ttf'
      'application/x-httpd-cgi'
      'application/x-javascript'
      'application/x-mpegurl'
      'application/x-opentype'
      'application/x-otf'
      'application/x-perl'
      'application/x-ttf'
      'font/eot'
      'font/ttf'
      'font/otf'
      'font/opentype'
      'image/svg+xml'
      'text/css'
      'text/csv'
      'text/html'
      'text/javascript'
      'text/js'
      'text/plain'
      'text/richtext'
      'text/tab-separated-values'
      'text/xml'
      'text/x-script'
      'text/x-component'
      'text/x-java-source'
    ]
    isCompressionEnabled: true
    origins: [
      {
        name: 'origin1'
        properties: {
          hostName: substring(storageAccountWeb.properties.primaryEndpoints.web,8, length(storageAccountWeb.properties.primaryEndpoints.web)-9)
          priority:1
          weight:1000
          enabled:true              
        }
      }
    ]
    deliveryPolicy: {
      rules: [
          {
              name: 'enforceHTTPS'
              order: 1
              conditions: [
                  {
                      name: 'RequestScheme'
                      parameters: {
                          typeName: 'DeliveryRuleRequestSchemeConditionParameters'
                          matchValues: [
                              'HTTP'
                          ]
                          operator: 'Equal'
                          negateCondition: false
                          transforms: []
                      }
                  }
              ]
              actions: [
                  {
                      name: 'UrlRedirect'
                      parameters: {
                          typeName: 'DeliveryRuleUrlRedirectActionParameters'
                          redirectType: 'Found'
                          destinationProtocol: 'Https'
                      }
                  }
              ]
          }
      ]
  }
  }
}
resource enpointOrigin 'Microsoft.Cdn/profiles/endpoints/origins@2021-06-01' = {
  parent:endpoint
  name:'origin1'
  properties: {
    hostName:substring(storageAccountWeb.properties.primaryEndpoints.web,8, length(storageAccountWeb.properties.primaryEndpoints.web)-9)
    priority:1
    weight:1000
    enabled:true
  }
}

output staticWebsiteUrl string = storageAccountWeb.properties.primaryEndpoints.web
output staticWebSiteHost string = substring(storageAccountWeb.properties.primaryEndpoints.web,8, length(storageAccountWeb.properties.primaryEndpoints.web)-9)
output cdnWebsiteHost string = endpoint.properties.hostName
output cdnId string = profile.id
output cdnEndpoint string = endpoint.id
output cdnEndpointName string =endpoint.name
output cdnName string = profile.name



