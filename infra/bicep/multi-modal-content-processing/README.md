# Multi-Modal Content Processing Infrastructure

This directory contains Bicep templates for deploying a complete multi-modal content processing solution on Azure.

## Architecture Overview

The solution includes:

### Storage Layer
- **Storage Account**: Blob storage for file uploads and Queue storage for async processing
- **Cosmos DB**: NoSQL database with hierarchical partition keys for metadata and vector search

### Compute Layer
- **Container Apps Environment**: Serverless hosting environment
- **Content Processor (Container App)**: Queue-driven background processor
- **Content Processor API (Container App)**: RESTful API for uploads and queries

### AI/ML Services
- **Azure OpenAI**: GPT-4, GPT-4 Vision, and text embeddings
- **Azure AI Vision**: Computer vision and OCR
- **Azure AI Search**: Full-text and semantic search

### Security & Configuration
- **Key Vault**: Secrets management
- **Managed Identities**: Secure service-to-service authentication
- **Container Registry**: Container image storage

### Monitoring
- **Log Analytics Workspace**: Centralized logging
- **Application Insights**: APM and telemetry

## Prerequisites

- Azure CLI installed
- Bicep CLI installed (`az bicep install`)
- Azure subscription with sufficient permissions
- Resource quotas for AI services in target region

## Deployment

### 1. Create Resource Group

```bash
az group create \
  --name rg-mmcp-dev \
  --location eastus
```

### 2. Review and Update Parameters

Edit `main.bicepparam` to customize:
- `environmentName`: Environment identifier (dev, test, prod)
- `appName`: Application prefix (3-10 chars)
- `location`: Azure region (if different from resource group)
- `openAiDeployments`: Model deployments (verify regional availability)
- `cosmosDbMaxThroughput`: Autoscale max RU/s
- `searchServiceSku`: Search service tier
- `containerAppsMinReplicas` / `containerAppsMaxReplicas`: Scaling limits

### 3. Validate Deployment

```bash
az deployment group validate \
  --resource-group rg-mmcp-dev \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### 4. Preview Changes

```bash
az deployment group what-if \
  --resource-group rg-mmcp-dev \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### 5. Deploy Infrastructure

```bash
az deployment group create \
  --resource-group rg-mmcp-dev \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --name mmcp-deployment-$(date +%Y%m%d-%H%M%S)
```

## Post-Deployment

### 1. Update Container Images

Replace the placeholder container images with your actual applications:

```bash
# Build and push processor image
docker build -t <acr-name>.azurecr.io/content-processor:latest ./processor
docker push <acr-name>.azurecr.io/content-processor:latest

# Build and push API image
docker build -t <acr-name>.azurecr.io/content-api:latest ./api
docker push <acr-name>.azurecr.io/content-api:latest

# Update Container Apps
az containerapp update \
  --name <processor-app-name> \
  --resource-group rg-mmcp-dev \
  --image <acr-name>.azurecr.io/content-processor:latest

az containerapp update \
  --name <api-app-name> \
  --resource-group rg-mmcp-dev \
  --image <acr-name>.azurecr.io/content-api:latest
```

### 2. Verify RBAC Assignments

Check that managed identities have proper access:

```bash
# List role assignments
az role assignment list \
  --resource-group rg-mmcp-dev \
  --output table
```

### 3. Test API Endpoint

```bash
# Get API URL
API_URL=$(az deployment group show \
  --resource-group rg-mmcp-dev \
  --name <deployment-name> \
  --query properties.outputs.apiAppUrl.value \
  --output tsv)

# Test endpoint
curl https://$API_URL/health
```

## Outputs

The deployment provides the following outputs:

- `apiAppUrl`: Public URL for the Content Processor API
- `storageAccountName`: Name of the storage account
- `cosmosDbEndpoint`: Cosmos DB endpoint URL
- `containerRegistryLoginServer`: ACR login server
- `openAiEndpoint`: Azure OpenAI endpoint
- `visionEndpoint`: Azure AI Vision endpoint
- `searchEndpoint`: Azure AI Search endpoint
- `keyVaultUri`: Key Vault URI
- `appInsightsConnectionString`: Application Insights connection string

## Architecture Decisions

### Security
- **Key-based auth disabled** for Storage and Cosmos DB (RBAC only)
- **Managed identities** for all service-to-service authentication
- **Private endpoints** ready (set `publicNetworkAccess: 'Disabled'`)
- **Container registry** anonymous pull disabled

### Scaling
- **Container Apps** auto-scale 0-10 replicas (configurable)
- **Processor** scales on queue depth (10 messages per replica)
- **API** scales on concurrent requests (50 per replica)
- **Cosmos DB** autoscales 1000-4000 RU/s (configurable)

### Data Modeling
- **Hierarchical partition keys** (`/userId`, `/contentType`) for Cosmos DB
- **Vector embeddings** stored in Cosmos DB for semantic search
- **Blob containers**: uploads, processed, temp
- **Queues**: processing-queue, failed-queue

## Cost Optimization

- Container Apps scale to zero when idle
- Cosmos DB autoscale reduces costs during low usage
- AI Search basic tier suitable for development
- Consider reserved instances for production workloads

## Troubleshooting

### Module Not Found Errors

Ensure module paths are correct:
```bash
# Restore Bicep modules
bicep restore main.bicep
```

### RBAC Propagation

Role assignments may take 5-10 minutes to propagate. If containers fail to access resources, wait and retry.

### OpenAI Model Availability

Some models may not be available in all regions. Check:
- [Azure OpenAI Model Availability](https://learn.microsoft.com/azure/ai-services/openai/concepts/models)

### Container Apps Startup Failures

Check container logs:
```bash
az containerapp logs show \
  --name <app-name> \
  --resource-group rg-mmcp-dev \
  --follow
```

## Clean Up

To delete all resources:

```bash
az group delete \
  --name rg-mmcp-dev \
  --yes \
  --no-wait
```

## Next Steps

1. Implement application code for processor and API
2. Set up CI/CD pipeline for automated deployments
3. Configure private endpoints for production
4. Enable diagnostic settings for compliance
5. Set up custom alerts and dashboards
6. Implement content moderation policies

## References

- [Multi-Modal Content Processing Specifications](../../../docs/architecture/multi-modal-content-processing-specifications.md)
- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Azure Cosmos DB Best Practices](https://learn.microsoft.com/azure/cosmos-db/)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/)
