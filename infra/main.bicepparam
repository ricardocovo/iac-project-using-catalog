// ============================================================================
// Document Processing System - Development Environment Parameters
// ============================================================================

using './main.bicep'

// Environment configuration
param environmentName = 'dev'
param location = 'eastus'
param projectName = 'docproc'

// Organizational metadata
param costCenter = 'CC-001'
param owner = 'Platform Team'
param dataClassification = 'internal'

// Storage configuration (cost-optimized for dev)
param storageAccountSkuName = 'Standard_LRS'
param enableBlobSoftDelete = true
param blobSoftDeleteRetentionDays = 7

// Cosmos DB configuration (cost-optimized for dev)
param cosmosDbOfferType = 'Standard'
param cosmosDbConsistencyLevel = 'Session'
param cosmosDbAutoscaleEnabled = true
param cosmosDbAutoscaleMinThroughput = 400
param cosmosDbAutoscaleMaxThroughput = 1000

// AI Services configuration (free/low-cost tiers for dev)
param documentIntelligenceSku = 'F0'
param aiServicesSku = 'F0'

// Search configuration (basic tier for dev)
param searchServiceSku = 'basic'

// Service Bus configuration
param serviceBusSku = 'Standard'

// Function App configuration (consumption plan for dev)
param functionAppPlanSku = 'Y1'

// Web App configuration (basic tier for dev)
param webAppPlanSku = 'B1'
param webAppRuntime = 'dotnet'
param webAppRuntimeVersion = '8'
