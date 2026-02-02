targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Environment name (e.g., dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environmentName string = 'dev'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Project name used for resource naming')
@minLength(3)
@maxLength(10)
param projectName string

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Project: projectName
  ManagedBy: 'Bicep'
  DeployedOn: utcNow('yyyy-MM-dd')
}

// ============================================================================
// Variables
// ============================================================================

var uniqueSuffix string = uniqueString(resourceGroup().id)
var storageAccountName string = toLower('st${projectName}${environmentName}${uniqueSuffix}')
var serviceBusNamespaceName string = 'sb-${projectName}-${environmentName}-${uniqueSuffix}'
var documentIntelligenceName string = 'di-${projectName}-${environmentName}-${uniqueSuffix}'
var queueName string = 'document-processing-queue'
var inputContainerName string = 'documents-input'
var outputContainerName string = 'documents-output'

// ============================================================================
// Modules from ACR Catalog
// ============================================================================

// Storage Account for document storage
module storageAccount 'br:iacmodulecatalog.azurecr.io/storage/storage-account:0.31.0' = {
  name: '${deployment().name}-storage'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    accessTier: 'Hot'
    publicNetworkAccess: 'Enabled'
    blobServices: {
      deleteRetentionPolicy: {
        enabled: true
        days: 7
      }
      containerDeleteRetentionPolicy: {
        enabled: true
        days: 7
      }
      containers: [
        {
          name: inputContainerName
          publicAccess: 'None'
        }
        {
          name: outputContainerName
          publicAccess: 'None'
        }
      ]
    }
  }
}

// Service Bus Namespace with Queue
module serviceBus 'br:iacmodulecatalog.azurecr.io/data/service-bus-namespace:0.16.0' = {
  name: '${deployment().name}-servicebus'
  params: {
    name: serviceBusNamespaceName
    location: location
    tags: tags
    skuName: 'Standard'
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    queues: [
      {
        name: queueName
        maxDeliveryCount: 10
        lockDuration: 'PT5M'
        defaultMessageTimeToLive: 'P14D'
        deadLetteringOnMessageExpiration: true
        enablePartitioning: false
        requiresDuplicateDetection: false
        requiresSession: false
      }
    ]
  }
}

// Azure AI Document Intelligence
module documentIntelligence 'br:iacmodulecatalog.azurecr.io/ai/cognitive-services-account:0.14.1' = {
  name: '${deployment().name}-docintell'
  params: {
    name: documentIntelligenceName
    location: location
    tags: tags
    kind: 'FormRecognizer'
    skuName: 'S0'
    customSubDomainName: documentIntelligenceName
    publicNetworkAccess: 'Enabled'
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Storage Account name')
output storageAccountName string = storageAccount.outputs.name

@description('Storage Account ID')
output storageAccountId string = storageAccount.outputs.resourceId

@description('Input container name')
output inputContainerName string = inputContainerName

@description('Output container name')
output outputContainerName string = outputContainerName

@description('Service Bus Namespace name')
output serviceBusNamespaceName string = serviceBus.outputs.name

@description('Service Bus Namespace ID')
output serviceBusNamespaceId string = serviceBus.outputs.resourceId

@description('Service Bus Queue name')
output serviceBusQueueName string = queueName

@description('Document Intelligence name')
output documentIntelligenceName string = documentIntelligence.outputs.name

@description('Document Intelligence ID')
output documentIntelligenceId string = documentIntelligence.outputs.resourceId

@description('Document Intelligence endpoint')
output documentIntelligenceEndpoint string = documentIntelligence.outputs.endpoint
