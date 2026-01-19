// Multi-Modal Content Processing Architecture
// This Bicep template deploys a complete multi-modal content processing solution on Azure
// including storage, compute, AI services, and monitoring components.

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Environment name (e.g., dev, test, prod)')
@minLength(3)
@maxLength(10)
param environmentName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Application name prefix for resource naming')
@minLength(3)
@maxLength(10)
param appName string

@description('Container registry admin user enabled')
param containerRegistryAdminUserEnabled bool = false

@description('Enable public network access for AI services')
@allowed(['Enabled', 'Disabled'])
param aiServicesPublicNetworkAccess string = 'Enabled'

@description('OpenAI model deployments')
param openAiDeployments array = [
  {
    name: 'gpt-4'
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    name: 'gpt-4-vision'
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: 'vision-preview'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    name: 'text-embedding-ada-002'
    model: {
      format: 'OpenAI'
      name: 'text-embedding-ada-002'
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: 20
    }
  }
]

@description('Cosmos DB autoscale max throughput')
@minValue(1000)
@maxValue(100000)
param cosmosDbMaxThroughput int = 4000

@description('AI Search SKU')
@allowed(['basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param searchServiceSku string = 'basic'

@description('Container Apps minimum replicas')
@minValue(0)
@maxValue(30)
param containerAppsMinReplicas int = 0

@description('Container Apps maximum replicas')
@minValue(1)
@maxValue(30)
param containerAppsMaxReplicas int = 10

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// VARIABLES
// ============================================================================

var resourceToken = toLower(uniqueString(resourceGroup().id, appName, environmentName))
var namingPrefix = '${appName}-${environmentName}'

// Resource names
var logAnalyticsName = '${namingPrefix}-logs-${resourceToken}'
var appInsightsName = '${namingPrefix}-insights-${resourceToken}'
var keyVaultName = take('${namingPrefix}-kv-${resourceToken}', 24)
var storageAccountName = take('${toLower(appName)}${toLower(environmentName)}st${resourceToken}', 24)
var cosmosDbAccountName = '${namingPrefix}-cosmos-${resourceToken}'
var containerRegistryName = take('${toLower(appName)}${toLower(environmentName)}acr${resourceToken}', 50)
var containerAppsEnvName = '${namingPrefix}-cae-${resourceToken}'
var openAiAccountName = '${namingPrefix}-openai-${resourceToken}'
var visionAccountName = '${namingPrefix}-vision-${resourceToken}'
var searchServiceName = '${namingPrefix}-search-${resourceToken}'

// Container App names
var processorAppName = '${namingPrefix}-processor'
var apiAppName = '${namingPrefix}-api'

// Managed identity names
var processorIdentityName = '${namingPrefix}-processor-identity'
var apiIdentityName = '${namingPrefix}-api-identity'

// Cosmos DB configuration
var cosmosDbDatabaseName = 'ContentProcessing'
var cosmosDbContainerName = 'ProcessedContent'

// Storage configuration
var blobContainerNames = ['uploads', 'processed', 'temp']
var queueNames = ['processing-queue', 'failed-queue']

// Default tags
var defaultTags = {
  environment: environmentName
  application: appName
  architecture: 'multi-modal-content-processing'
  managedBy: 'bicep'
}
var allTags = union(defaultTags, tags)

// ============================================================================
// MODULES - MONITORING
// ============================================================================

module logAnalytics '../../../../iac-module-catalog/catalog/monitoring/log-analytics-workspace.bicep' = {
  name: 'logAnalytics-deployment'
  params: {
    name: logAnalyticsName
    location: location
    dataRetention: 30
    tags: allTags
  }
}

module appInsights '../../../../iac-module-catalog/catalog/monitoring/application-insights.bicep' = {
  name: 'appInsights-deployment'
  params: {
    name: appInsightsName
    location: location
    workspaceResourceId: logAnalytics.outputs.resourceId
    tags: allTags
  }
}

// ============================================================================
// MODULES - SECURITY
// ============================================================================

module keyVault '../../../../iac-module-catalog/catalog/security/key-vault.bicep' = {
  name: 'keyVault-deployment'
  params: {
    name: keyVaultName
    location: location
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
    tags: allTags
  }
}

module processorIdentity '../../../../iac-module-catalog/catalog/security/managed-identity.bicep' = {
  name: 'processorIdentity-deployment'
  params: {
    name: processorIdentityName
    location: location
    tags: allTags
  }
}

module apiIdentity '../../../../iac-module-catalog/catalog/security/managed-identity.bicep' = {
  name: 'apiIdentity-deployment'
  params: {
    name: apiIdentityName
    location: location
    tags: allTags
  }
}

// ============================================================================
// MODULES - STORAGE
// ============================================================================

module storageAccount '../../../../iac-module-catalog/catalog/storage/storage-account.bicep' = {
  name: 'storageAccount-deployment'
  params: {
    name: storageAccountName
    location: location
    publicNetworkAccess: 'Enabled'
    blobServices: {
      containers: [
        for containerName in blobContainerNames: {
          name: containerName
          publicAccess: 'None'
        }
      ]
    }
    tags: allTags
  }
}

// ============================================================================
// MODULES - DATA
// ============================================================================

module cosmosDb '../../../../iac-module-catalog/catalog/data/cosmos-db-account.bicep' = {
  name: 'cosmosDb-deployment'
  params: {
    name: cosmosDbAccountName
    location: location
    defaultConsistencyLevel: 'Session'
    automaticFailover: true
    networkRestrictions: {
      publicNetworkAccess: 'Enabled'
      networkAclBypass: 'AzureServices'
    }
    sqlDatabases: [
      {
        name: cosmosDbDatabaseName
        containers: [
          {
            name: cosmosDbContainerName
            partitionKeyPaths: [
              '/userId'
              '/contentType'
            ]
            autoscaleMaxThroughput: cosmosDbMaxThroughput
            indexingPolicy: {
              automatic: true
              indexingMode: 'consistent'
              includedPaths: [
                {
                  path: '/*'
                }
              ]
              excludedPaths: [
                {
                  path: '/"_etag"/?'
                }
              ]
            }
          }
        ]
      }
    ]
    tags: allTags
  }
}

// ============================================================================
// MODULES - AI SERVICES
// ============================================================================

module openAi '../../../../iac-module-catalog/catalog/ai/cognitive-services-account.bicep' = {
  name: 'openAi-deployment'
  params: {
    name: openAiAccountName
    location: location
    kind: 'OpenAI'
    skuName: 'S0'
    publicNetworkAccess: aiServicesPublicNetworkAccess
    customSubDomainName: openAiAccountName
    deployments: openAiDeployments
    managedIdentities: {
      systemAssigned: true
    }
    tags: allTags
  }
}

module visionService '../../../../iac-module-catalog/catalog/ai/cognitive-services-account.bicep' = {
  name: 'visionService-deployment'
  params: {
    name: visionAccountName
    location: location
    kind: 'ComputerVision'
    skuName: 'S1'
    publicNetworkAccess: aiServicesPublicNetworkAccess
    customSubDomainName: visionAccountName
    managedIdentities: {
      systemAssigned: true
    }
    tags: allTags
  }
}

module searchService '../../../../iac-module-catalog/catalog/ai/search-service.bicep' = {
  name: 'searchService-deployment'
  params: {
    name: searchServiceName
    location: location
    skuName: searchServiceSku
    replicaCount: 1
    partitionCount: 1
    publicNetworkAccess: 'Enabled'
    tags: allTags
  }
}

// ============================================================================
// MODULES - CONTAINERS
// ============================================================================

module containerRegistry '../../../../iac-module-catalog/catalog/storage/container-registry.bicep' = {
  name: 'containerRegistry-deployment'
  params: {
    name: containerRegistryName
    location: location
    adminUserEnabled: containerRegistryAdminUserEnabled
    publicNetworkAccess: 'Enabled'
    managedIdentities: {
      systemAssigned: true
    }
    tags: allTags
  }
}

module containerAppsEnvironment '../../../../iac-module-catalog/catalog/containers/container-apps-environment.bicep' = {
  name: 'containerAppsEnv-deployment'
  params: {
    name: containerAppsEnvName
    location: location
    workspaceResourceId: logAnalytics.outputs.resourceId
    tags: allTags
  }
}

// Container App - Content Processor (Queue Consumer)
module processorApp '../../../../iac-module-catalog/catalog/containers/container-app.bicep' = {
  name: 'processorApp-deployment'
  params: {
    name: processorAppName
    location: location
    environmentResourceId: containerAppsEnvironment.outputs.resourceId
    containers: [
      {
        name: 'processor'
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          cpu: json('0.5')
          memory: '1Gi'
        }
        env: [
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: appInsights.outputs.connectionString
          }
          {
            name: 'AZURE_STORAGE_ACCOUNT_NAME'
            value: storageAccount.outputs.name
          }
          {
            name: 'AZURE_COSMOS_DB_ENDPOINT'
            value: cosmosDb.outputs.endpoint
          }
          {
            name: 'AZURE_COSMOS_DB_DATABASE'
            value: cosmosDbDatabaseName
          }
          {
            name: 'AZURE_COSMOS_DB_CONTAINER'
            value: cosmosDbContainerName
          }
          {
            name: 'AZURE_OPENAI_ENDPOINT'
            value: openAi.outputs.endpoint
          }
          {
            name: 'AZURE_VISION_ENDPOINT'
            value: visionService.outputs.endpoint
          }
          {
            name: 'AZURE_SEARCH_SERVICE_NAME'
            value: searchService.outputs.name
          }
          {
            name: 'PROCESSING_QUEUE_NAME'
            value: queueNames[0]
          }
        ]
      }
    ]
    ingressConfiguration: {
      external: false
      targetPort: 80
    }
    scaleConfiguration: {
      minReplicas: containerAppsMinReplicas
      maxReplicas: containerAppsMaxReplicas
      rules: []
    }
    managedIdentities: {
      userAssignedResourceIds: [
        processorIdentity.outputs.resourceId
      ]
    }
    tags: allTags
  }
}

// Container App - Content Processor API (HTTP API)
module apiApp '../../../../iac-module-catalog/catalog/containers/container-app.bicep' = {
  name: 'apiApp-deployment'
  params: {
    name: apiAppName
    location: location
    environmentResourceId: containerAppsEnvironment.outputs.resourceId
    containers: [
      {
        name: 'api'
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          cpu: json('0.5')
          memory: '1Gi'
        }
        env: [
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: appInsights.outputs.connectionString
          }
          {
            name: 'AZURE_STORAGE_ACCOUNT_NAME'
            value: storageAccount.outputs.name
          }
          {
            name: 'AZURE_COSMOS_DB_ENDPOINT'
            value: cosmosDb.outputs.endpoint
          }
          {
            name: 'AZURE_COSMOS_DB_DATABASE'
            value: cosmosDbDatabaseName
          }
          {
            name: 'AZURE_COSMOS_DB_CONTAINER'
            value: cosmosDbContainerName
          }
          {
            name: 'AZURE_SEARCH_SERVICE_NAME'
            value: searchService.outputs.name
          }
          {
            name: 'PROCESSING_QUEUE_NAME'
            value: queueNames[0]
          }
        ]
      }
    ]
    ingressConfiguration: {
      external: true
      targetPort: 80
    }
    scaleConfiguration: {
      minReplicas: 1
      maxReplicas: containerAppsMaxReplicas
      rules: []
    }
    managedIdentities: {
      userAssignedResourceIds: [
        apiIdentity.outputs.resourceId
      ]
    }
    tags: allTags
  }
}

// NOTE: RBAC role assignments should be configured post-deployment
// Use Azure CLI or Portal to assign necessary roles to managed identities
// Required roles:
// - Storage Blob Data Contributor & Queue Data Contributor for both identities
// - Cosmos DB Built-in Data Contributor/Reader
// - Cognitive Services User
// - Search Index Data Contributor/Reader
// - AcrPull

// ============================================================================

@description('The name of the resource group')
output resourceGroupName string = resourceGroup().name

@description('The location of the resources')
output location string = location

// Storage outputs
@description('Storage account name')
output storageAccountName string = storageAccount.outputs.name

@description('Storage account resource ID')
output storageAccountId string = storageAccount.outputs.resourceId

// Cosmos DB outputs
@description('Cosmos DB account name')
output cosmosDbAccountName string = cosmosDb.outputs.name

@description('Cosmos DB endpoint')
output cosmosDbEndpoint string = cosmosDb.outputs.endpoint

@description('Cosmos DB database name')
output cosmosDbDatabaseName string = cosmosDbDatabaseName

@description('Cosmos DB container name')
output cosmosDbContainerName string = cosmosDbContainerName

// Container Registry outputs
@description('Container registry name')
output containerRegistryName string = containerRegistry.outputs.name

@description('Container registry login server')
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer

// Container Apps outputs
@description('Container Apps environment name')
output containerAppsEnvironmentName string = containerAppsEnvironment.outputs.name

@description('Processor app name')
output processorAppName string = processorApp.outputs.name

@description('API app name')
output apiAppName string = apiApp.outputs.name

@description('API app URL')
output apiAppUrl string = apiApp.outputs.fqdn

// AI Services outputs
@description('OpenAI account name')
output openAiAccountName string = openAi.outputs.name

@description('OpenAI endpoint')
output openAiEndpoint string = openAi.outputs.endpoint

@description('Vision service account name')
output visionAccountName string = visionService.outputs.name

@description('Vision service endpoint')
output visionEndpoint string = visionService.outputs.endpoint

@description('Search service name')
output searchServiceName string = searchService.outputs.name

// Security outputs
@description('Key Vault name')
output keyVaultName string = keyVault.outputs.name

@description('Key Vault URI')
output keyVaultUri string = keyVault.outputs.uri

@description('Processor managed identity principal ID')
output processorIdentityPrincipalId string = processorIdentity.outputs.principalId

@description('API managed identity principal ID')
output apiIdentityPrincipalId string = apiIdentity.outputs.principalId

// Monitoring outputs
@description('Application Insights name')
output appInsightsName string = appInsights.outputs.name

@description('Application Insights connection string')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('Log Analytics workspace name')
output logAnalyticsName string = logAnalytics.outputs.name
