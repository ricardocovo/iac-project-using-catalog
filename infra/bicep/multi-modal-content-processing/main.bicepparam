using './main.bicep'

// ============================================================================
// REQUIRED PARAMETERS
// ============================================================================

// Environment name (dev, test, prod)
param environmentName = 'dev'

// Application name prefix (3-10 characters)
param appName = 'mmcp'

// ============================================================================
// OPTIONAL PARAMETERS
// ============================================================================

// Resource location (default: resource group location)
// param location = 'eastus'

// Container registry admin user (default: false for security)
param containerRegistryAdminUserEnabled = false

// AI services public network access (Enabled or Disabled)
param aiServicesPublicNetworkAccess = 'Enabled'

// OpenAI model deployments
// Note: Ensure models are available in your target region
param openAiDeployments = [
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

// Cosmos DB configuration
param cosmosDbMaxThroughput = 4000

// AI Search SKU (basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2)
param searchServiceSku = 'basic'

// Container Apps scaling configuration
param containerAppsMinReplicas = 0
param containerAppsMaxReplicas = 10

// Tags for all resources
param tags = {
  project: 'multi-modal-content-processing'
  costCenter: 'engineering'
}
