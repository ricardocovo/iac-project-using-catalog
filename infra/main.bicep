// ============================================================================
// Document Processing System - Main Bicep Template
// ============================================================================
// This template deploys a comprehensive document processing system with:
// - Azure Blob Storage for document storage
// - Azure Cosmos DB for metadata and state management
// - Azure AI Document Intelligence for document analysis
// - Azure AI Search for vector search and semantic search
// - Azure Functions for event-driven processing
// - Azure Service Bus for reliable messaging
// - Azure AI Services for embeddings and chat
// - Azure Web App for user interface
// - Supporting services (Key Vault, Application Insights, Log Analytics)
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('The environment name (dev, staging, prod). Used for resource naming and configuration.')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environmentName string = 'dev'

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('The name of the project. Used for resource naming.')
@minLength(3)
@maxLength(10)
param projectName string = 'docproc'

@description('The cost center code for billing and tracking purposes.')
param costCenter string = 'CC-001'

@description('The owner or team responsible for this deployment.')
param owner string = 'Platform Team'

@description('The data classification level for the system.')
@allowed([
  'public'
  'internal'
  'confidential'
  'restricted'
])
param dataClassification string = 'internal'

@description('The Storage Account SKU name.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
])
param storageAccountSkuName string = environmentName == 'prod' ? 'Standard_ZRS' : 'Standard_LRS'

@description('The Cosmos DB account offer type.')
@allowed([
  'Standard'
])
param cosmosDbOfferType string = 'Standard'

@description('The Cosmos DB consistency level.')
@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
param cosmosDbConsistencyLevel string = 'Session'

@description('Enable Cosmos DB autoscale.')
param cosmosDbAutoscaleEnabled bool = true

@description('The maximum throughput for Cosmos DB autoscale (in RU/s).')
param cosmosDbAutoscaleMaxThroughput int = 4000

@description('The SKU name for Azure AI Document Intelligence.')
@allowed([
  'F0'
  'S0'
])
param documentIntelligenceSku string = environmentName == 'prod' ? 'S0' : 'F0'

@description('The SKU name for Azure AI Search.')
@allowed([
  'free'
  'basic'
  'standard'
  'standard2'
  'standard3'
])
param searchServiceSku string = environmentName == 'prod' ? 'standard' : 'basic'

@description('The SKU name for Azure Service Bus.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param serviceBusSku string = environmentName == 'prod' ? 'Standard' : 'Standard'

@description('The SKU name for Azure Functions hosting plan.')
@allowed([
  'Y1' // Consumption
  'EP1' // Elastic Premium 1
  'EP2' // Elastic Premium 2
  'EP3' // Elastic Premium 3
])
param functionAppPlanSku string = environmentName == 'prod' ? 'EP1' : 'Y1'

@description('The SKU name for Azure App Service (Web App).')
@allowed([
  'F1' // Free
  'B1' // Basic 1
  'B2' // Basic 2
  'S1' // Standard 1
  'S2' // Standard 2
])
param webAppPlanSku string = environmentName == 'prod' ? 'S1' : 'B1'

@description('The runtime stack for the Web App.')
@allowed([
  'dotnet'
  'node'
  'python'
])
param webAppRuntime string = 'dotnet'

@description('The runtime version for the Web App.')
param webAppRuntimeVersion string = '8'

@description('Enable soft delete for Blob Storage.')
param enableBlobSoftDelete bool = true

@description('The number of days to retain deleted blobs.')
@minValue(1)
@maxValue(365)
param blobSoftDeleteRetentionDays int = 7

@description('The SKU name for Azure AI Services (for embeddings and chat).')
@allowed([
  'F0'
  'S0'
])
param aiServicesSku string = environmentName == 'prod' ? 'S0' : 'F0'

// ============================================================================
// VARIABLES
// ============================================================================

var uniqueSuffix = uniqueString(resourceGroup().id, projectName, environmentName)
var resourcePrefix = '${projectName}-${environmentName}'

// Resource names
var storageAccountName = toLower('${replace(resourcePrefix, '-', '')}${uniqueSuffix}')
var cosmosDbAccountName = toLower('${resourcePrefix}-cosmos-${uniqueSuffix}')
var documentIntelligenceName = '${resourcePrefix}-docint-${uniqueSuffix}'
var searchServiceName = toLower('${resourcePrefix}-search-${uniqueSuffix}')
var serviceBusNamespaceName = '${resourcePrefix}-sb-${uniqueSuffix}'
var keyVaultName = toLower('${take('${resourcePrefix}-kv-${uniqueSuffix}', 24)}')
var logAnalyticsName = '${resourcePrefix}-logs-${uniqueSuffix}'
var applicationInsightsName = '${resourcePrefix}-appins-${uniqueSuffix}'
var functionAppPlanName = '${resourcePrefix}-funcplan-${uniqueSuffix}'
var webAppPlanName = '${resourcePrefix}-webplan-${uniqueSuffix}'
var functionAppName = '${resourcePrefix}-func-${uniqueSuffix}'
var webAppName = '${resourcePrefix}-web-${uniqueSuffix}'
var aiServicesName = '${resourcePrefix}-ai-${uniqueSuffix}'

// Storage containers
var storageContainers = [
  'raw-documents'
  'processed-documents'
  'metadata'
]

// Cosmos DB database and containers
var cosmosDbDatabaseName = 'document-processing-db'
var cosmosDbContainers = [
  {
    name: 'document-metadata'
    partitionKey: '/documentType'
  }
  {
    name: 'processing-results'
    partitionKey: '/documentId'
  }
  {
    name: 'chat-history'
    partitionKey: '/sessionId'
  }
  {
    name: 'user-sessions'
    partitionKey: '/userId'
  }
]

// Service Bus queues
var serviceBusQueues = [
  'document-ingestion-queue'
  'classification-queue'
  'intelligence-processing-queue'
  'embedding-queue'
  'indexing-queue'
]

// Common tags for all resources
var commonTags = {
  Environment: environmentName
  Project: projectName
  CostCenter: costCenter
  Owner: owner
  DataClassification: dataClassification
  ManagedBy: 'Bicep'
}

// ============================================================================
// MODULES - Monitoring and Security (Foundation)
// ============================================================================

// Log Analytics Workspace
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: 'logAnalytics-deployment'
  params: {
    name: logAnalyticsName
    location: location
    tags: commonTags
    retentionInDays: 90
    skuName: 'PerGB2018'
  }
}

// Application Insights
module applicationInsights 'br/public:avm/res/insights/component:0.4.2' = {
  name: 'applicationInsights-deployment'
  params: {
    name: applicationInsightsName
    location: location
    tags: commonTags
    workspaceResourceId: logAnalytics.outputs.resourceId
    kind: 'web'
    applicationType: 'web'
  }
}

// Key Vault
module keyVault 'br/public:avm/res/key-vault/vault:0.11.0' = {
  name: 'keyVault-deployment'
  params: {
    name: keyVaultName
    location: location
    tags: commonTags
    sku: 'standard'
    enableRbacAuthorization: true
    enableVaultForDeployment: true
    enableVaultForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
  }
}

// ============================================================================
// MODULES - Storage and Data Services
// ============================================================================

// Storage Account
module storageAccount 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: 'storageAccount-deployment'
  params: {
    name: storageAccountName
    location: location
    tags: commonTags
    skuName: storageAccountSkuName
    kind: 'StorageV2'
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    blobServices: {
      deleteRetentionPolicyEnabled: enableBlobSoftDelete
      deleteRetentionPolicyDays: blobSoftDeleteRetentionDays
      containers: [
        for container in storageContainers: {
          name: container
          publicAccess: 'None'
        }
      ]
      diagnosticSettings: [
        {
          workspaceResourceId: logAnalytics.outputs.resourceId
          logCategoriesAndGroups: [
            {
              categoryGroup: 'allLogs'
            }
          ]
          metricCategories: [
            {
              category: 'Transaction'
            }
          ]
        }
      ]
    }
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        metricCategories: [
          {
            category: 'Transaction'
          }
        ]
      }
    ]
  }
}

// Cosmos DB Account
module cosmosDb 'br/public:avm/res/document-db/database-account:0.11.1' = {
  name: 'cosmosDb-deployment'
  params: {
    name: cosmosDbAccountName
    location: location
    tags: commonTags
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: environmentName == 'prod'
      }
    ]
    databaseAccountOfferType: cosmosDbOfferType
    defaultConsistencyLevel: cosmosDbConsistencyLevel
    enableAutomaticFailover: environmentName == 'prod'
    enableMultipleWriteLocations: false
    sqlDatabases: [
      {
        name: cosmosDbDatabaseName
        containers: [
          for container in cosmosDbContainers: {
            name: container.name
            paths: [
              container.partitionKey
            ]
            kind: 'Hash'
            throughput: cosmosDbAutoscaleEnabled ? null : 400
            autoscaleSettingsMaxThroughput: cosmosDbAutoscaleEnabled ? cosmosDbAutoscaleMaxThroughput : null
          }
        ]
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
        metricCategories: [
          {
            category: 'Requests'
          }
        ]
      }
    ]
  }
}

// ============================================================================
// MODULES - AI Services
// ============================================================================

// Azure AI Document Intelligence (Form Recognizer)
module documentIntelligence 'br/public:avm/res/cognitive-services/account:0.9.1' = {
  name: 'documentIntelligence-deployment'
  params: {
    name: documentIntelligenceName
    location: location
    tags: commonTags
    kind: 'FormRecognizer'
    sku: documentIntelligenceSku
    customSubDomainName: documentIntelligenceName
    publicNetworkAccess: 'Enabled'
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
  }
}

// Azure AI Services (for embeddings and chat)
module aiServices 'br/public:avm/res/cognitive-services/account:0.9.1' = {
  name: 'aiServices-deployment'
  params: {
    name: aiServicesName
    location: location
    tags: commonTags
    kind: 'AIServices'
    sku: aiServicesSku
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
  }
}

// Azure AI Search
module searchService 'br/public:avm/res/search/search-service:0.9.0' = {
  name: 'searchService-deployment'
  params: {
    name: searchServiceName
    location: location
    tags: commonTags
    sku: searchServiceSku
    replicaCount: environmentName == 'prod' ? 2 : 1
    partitionCount: 1
    semanticSearch: 'standard'
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
  }
}

// ============================================================================
// MODULES - Messaging
// ============================================================================

// Service Bus Namespace
module serviceBus 'br/public:avm/res/service-bus/namespace:0.11.1' = {
  name: 'serviceBus-deployment'
  params: {
    name: serviceBusNamespaceName
    location: location
    tags: commonTags
    skuObject: {
      name: serviceBusSku
    }
    queues: [
      for queue in serviceBusQueues: {
        name: queue
        maxDeliveryCount: 10
        lockDuration: 'PT5M'
        requiresDuplicateDetection: false
        requiresSession: false
        enablePartitioning: false
        deadLetteringOnMessageExpiration: true
        defaultMessageTimeToLive: 'P14D'
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
  }
}

// ============================================================================
// MODULES - Compute (Functions and Web App)
// ============================================================================

// Function App Hosting Plan
module functionAppPlan 'br/public:avm/res/web/serverfarm:0.4.0' = {
  name: 'functionAppPlan-deployment'
  params: {
    name: functionAppPlanName
    location: location
    tags: commonTags
    skuName: functionAppPlanSku
    kind: functionAppPlanSku == 'Y1' ? 'FunctionApp' : 'Elastic'
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
  }
}

// Function App
module functionApp 'br/public:avm/res/web/site:0.12.0' = {
  name: 'functionApp-deployment'
  params: {
    name: functionAppName
    location: location
    tags: commonTags
    kind: 'functionapp'
    serverFarmResourceId: functionAppPlan.outputs.resourceId
    managedIdentities: {
      systemAssigned: true
    }
    appInsightResourceId: applicationInsights.outputs.resourceId
    storageAccountResourceId: storageAccount.outputs.resourceId
    storageAccountRequired: true
    siteConfig: {
      alwaysOn: functionAppPlanSku != 'Y1'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      netFrameworkVersion: 'v8.0'
      use32BitWorkerProcess: false
    }
    appSettingsKeyValuePairs: {
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
      AzureWebJobsStorage__accountName: storageAccount.outputs.name
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.outputs.connectionString
      CosmosDb__Endpoint: cosmosDb.outputs.endpoint
      CosmosDb__DatabaseName: cosmosDbDatabaseName
      DocumentIntelligence__Endpoint: documentIntelligence.outputs.endpoint
      AiServices__Endpoint: aiServices.outputs.endpoint
      SearchService__Endpoint: 'https://${searchService.outputs.name}.search.windows.net'
      ServiceBus__Namespace: '${serviceBus.outputs.name}.servicebus.windows.net'
      KeyVault__VaultUri: keyVault.outputs.uri
    }
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
  }
}

// Web App Hosting Plan
module webAppPlan 'br/public:avm/res/web/serverfarm:0.4.0' = {
  name: 'webAppPlan-deployment'
  params: {
    name: webAppPlanName
    location: location
    tags: commonTags
    skuName: webAppPlanSku
    kind: 'app'
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
  }
}

// Web App
module webApp 'br/public:avm/res/web/site:0.12.0' = {
  name: 'webApp-deployment'
  params: {
    name: webAppName
    location: location
    tags: commonTags
    kind: 'app'
    serverFarmResourceId: webAppPlan.outputs.resourceId
    managedIdentities: {
      systemAssigned: true
    }
    appInsightResourceId: applicationInsights.outputs.resourceId
    httpsOnly: true
    siteConfig: {
      alwaysOn: webAppPlanSku != 'F1'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      netFrameworkVersion: webAppRuntime == 'dotnet' ? 'v${webAppRuntimeVersion}.0' : null
      nodeVersion: webAppRuntime == 'node' ? '~${webAppRuntimeVersion}' : null
      pythonVersion: webAppRuntime == 'python' ? webAppRuntimeVersion : null
    }
    appSettingsKeyValuePairs: {
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.outputs.connectionString
      CosmosDb__Endpoint: cosmosDb.outputs.endpoint
      CosmosDb__DatabaseName: cosmosDbDatabaseName
      SearchService__Endpoint: 'https://${searchService.outputs.name}.search.windows.net'
      AiServices__Endpoint: aiServices.outputs.endpoint
      KeyVault__VaultUri: keyVault.outputs.uri
    }
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
  }
}

// ============================================================================
// ROLE ASSIGNMENTS
// ============================================================================

// Function App - Storage Blob Data Contributor
module functionAppStorageRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'functionAppStorageRoleAssignment-deployment'
  params: {
    principalId: functionApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
    resourceId: storageAccount.outputs.resourceId
  }
}

// Function App - Cosmos DB Data Contributor
module functionAppCosmosDbRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'functionAppCosmosDbRoleAssignment-deployment'
  params: {
    principalId: functionApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: '00000000-0000-0000-0000-000000000002' // Cosmos DB Built-in Data Contributor
    resourceId: cosmosDb.outputs.resourceId
  }
}

// Function App - Service Bus Data Owner
module functionAppServiceBusRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'functionAppServiceBusRoleAssignment-deployment'
  params: {
    principalId: functionApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: '090c5cfd-751d-490a-894a-3ce6f1109419' // Azure Service Bus Data Owner
    resourceId: serviceBus.outputs.resourceId
  }
}

// Function App - Cognitive Services User
module functionAppCognitiveServicesRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'functionAppCognitiveServicesRoleAssignment-deployment'
  params: {
    principalId: functionApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908' // Cognitive Services User
    resourceId: documentIntelligence.outputs.resourceId
  }
}

// Function App - AI Services User
module functionAppAiServicesRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'functionAppAiServicesRoleAssignment-deployment'
  params: {
    principalId: functionApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908' // Cognitive Services User
    resourceId: aiServices.outputs.resourceId
  }
}

// Function App - Search Index Data Contributor
module functionAppSearchRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'functionAppSearchRoleAssignment-deployment'
  params: {
    principalId: functionApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7' // Search Index Data Contributor
    resourceId: searchService.outputs.resourceId
  }
}

// Function App - Key Vault Secrets User
module functionAppKeyVaultRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'functionAppKeyVaultRoleAssignment-deployment'
  params: {
    principalId: functionApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    resourceId: keyVault.outputs.resourceId
  }
}

// Web App - Cosmos DB Data Reader
module webAppCosmosDbRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'webAppCosmosDbRoleAssignment-deployment'
  params: {
    principalId: webApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: '00000000-0000-0000-0000-000000000001' // Cosmos DB Built-in Data Reader
    resourceId: cosmosDb.outputs.resourceId
  }
}

// Web App - AI Services User
module webAppAiServicesRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'webAppAiServicesRoleAssignment-deployment'
  params: {
    principalId: webApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908' // Cognitive Services User
    resourceId: aiServices.outputs.resourceId
  }
}

// Web App - Search Index Data Reader
module webAppSearchRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'webAppSearchRoleAssignment-deployment'
  params: {
    principalId: webApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f' // Search Index Data Reader
    resourceId: searchService.outputs.resourceId
  }
}

// Web App - Key Vault Secrets User
module webAppKeyVaultRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'webAppKeyVaultRoleAssignment-deployment'
  params: {
    principalId: webApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    resourceId: keyVault.outputs.resourceId
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the resource group.')
output resourceGroupName string = resourceGroup().name

@description('The location where resources were deployed.')
output location string = location

@description('The environment name.')
output environment string = environmentName

// Storage outputs
@description('The resource ID of the Storage Account.')
output storageAccountResourceId string = storageAccount.outputs.resourceId

@description('The name of the Storage Account.')
output storageAccountName string = storageAccount.outputs.name

@description('The primary endpoints for the Storage Account.')
output storageAccountPrimaryEndpoints object = storageAccount.outputs.primaryBlobEndpoint

// Cosmos DB outputs
@description('The resource ID of the Cosmos DB account.')
output cosmosDbResourceId string = cosmosDb.outputs.resourceId

@description('The name of the Cosmos DB account.')
output cosmosDbAccountName string = cosmosDb.outputs.name

@description('The endpoint URL for the Cosmos DB account.')
output cosmosDbEndpoint string = cosmosDb.outputs.endpoint

@description('The name of the Cosmos DB database.')
output cosmosDbDatabaseName string = cosmosDbDatabaseName

// AI Services outputs
@description('The resource ID of the Document Intelligence service.')
output documentIntelligenceResourceId string = documentIntelligence.outputs.resourceId

@description('The name of the Document Intelligence service.')
output documentIntelligenceName string = documentIntelligence.outputs.name

@description('The endpoint URL for the Document Intelligence service.')
output documentIntelligenceEndpoint string = documentIntelligence.outputs.endpoint

@description('The resource ID of the AI Services account.')
output aiServicesResourceId string = aiServices.outputs.resourceId

@description('The name of the AI Services account.')
output aiServicesName string = aiServices.outputs.name

@description('The endpoint URL for the AI Services account.')
output aiServicesEndpoint string = aiServices.outputs.endpoint

// Search outputs
@description('The resource ID of the Search Service.')
output searchServiceResourceId string = searchService.outputs.resourceId

@description('The name of the Search Service.')
output searchServiceName string = searchService.outputs.name

@description('The endpoint URL for the Search Service.')
output searchServiceEndpoint string = 'https://${searchService.outputs.name}.search.windows.net'

// Service Bus outputs
@description('The resource ID of the Service Bus namespace.')
output serviceBusResourceId string = serviceBus.outputs.resourceId

@description('The name of the Service Bus namespace.')
output serviceBusName string = serviceBus.outputs.name

@description('The endpoint for the Service Bus namespace.')
output serviceBusEndpoint string = '${serviceBus.outputs.name}.servicebus.windows.net'

// Function App outputs
@description('The resource ID of the Function App.')
output functionAppResourceId string = functionApp.outputs.resourceId

@description('The name of the Function App.')
output functionAppName string = functionApp.outputs.name

@description('The default hostname of the Function App.')
output functionAppDefaultHostname string = functionApp.outputs.defaultHostname

@description('The principal ID of the Function App managed identity.')
output functionAppPrincipalId string = functionApp.outputs.systemAssignedMIPrincipalId

// Web App outputs
@description('The resource ID of the Web App.')
output webAppResourceId string = webApp.outputs.resourceId

@description('The name of the Web App.')
output webAppName string = webApp.outputs.name

@description('The default hostname of the Web App.')
output webAppDefaultHostname string = webApp.outputs.defaultHostname

@description('The principal ID of the Web App managed identity.')
output webAppPrincipalId string = webApp.outputs.systemAssignedMIPrincipalId

// Monitoring outputs
@description('The resource ID of the Log Analytics workspace.')
output logAnalyticsResourceId string = logAnalytics.outputs.resourceId

@description('The name of the Log Analytics workspace.')
output logAnalyticsName string = logAnalytics.outputs.name

@description('The resource ID of the Application Insights component.')
output applicationInsightsResourceId string = applicationInsights.outputs.resourceId

@description('The name of the Application Insights component.')
output applicationInsightsName string = applicationInsights.outputs.name

@description('The connection string for Application Insights.')
output applicationInsightsConnectionString string = applicationInsights.outputs.connectionString

// Key Vault outputs
@description('The resource ID of the Key Vault.')
output keyVaultResourceId string = keyVault.outputs.resourceId

@description('The name of the Key Vault.')
output keyVaultName string = keyVault.outputs.name

@description('The URI of the Key Vault.')
output keyVaultUri string = keyVault.outputs.uri
