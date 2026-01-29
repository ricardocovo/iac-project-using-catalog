// ============================================================================
// Document Processing System - Production Environment Parameters
// ============================================================================

using './main.bicep'

// Environment configuration
param environmentName = 'prod'
param location = 'eastus'
param projectName = 'docproc'

// Organizational metadata
param costCenter = 'CC-001'
param owner = 'Platform Team'
param dataClassification = 'confidential'

// Storage configuration (production-ready)
param storageAccountSkuName = 'Standard_ZRS'
param enableBlobSoftDelete = true
param blobSoftDeleteRetentionDays = 30

// Cosmos DB configuration (production-ready with autoscale)
param cosmosDbOfferType = 'Standard'
param cosmosDbConsistencyLevel = 'Session'
param cosmosDbAutoscaleEnabled = true
param cosmosDbAutoscaleMinThroughput = 400
param cosmosDbAutoscaleMaxThroughput = 4000

// AI Services configuration (standard tiers for production)
param documentIntelligenceSku = 'S0'
param aiServicesSku = 'S0'

// Search configuration (standard tier with replicas)
param searchServiceSku = 'standard'

// Service Bus configuration
param serviceBusSku = 'Standard'

// Function App configuration (premium plan for production)
param functionAppPlanSku = 'EP1'

// Web App configuration (standard tier for production)
param webAppPlanSku = 'S1'
param webAppRuntime = 'dotnet'
param webAppRuntimeVersion = '8'
