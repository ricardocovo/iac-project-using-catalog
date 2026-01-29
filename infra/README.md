# Document Processing System - Azure Infrastructure

This directory contains Azure Bicep templates for deploying a comprehensive document processing system with AI capabilities.

## Architecture Overview

The infrastructure includes the following Azure services:

### Core Services
- **Azure Blob Storage**: Document storage with three containers (raw-documents, processed-documents, metadata)
- **Azure Cosmos DB**: NoSQL database for metadata, processing results, chat history, and user sessions
- **Azure AI Document Intelligence**: Document analysis and structure extraction
- **Azure AI Search**: Vector search and semantic search capabilities
- **Azure Functions**: Event-driven serverless processing with support for Durable Functions
- **Azure Service Bus**: Reliable message queuing with dead letter queues
- **Azure AI Services**: Embeddings and chat capabilities
- **Azure Web App**: User interface for document chat and management

### Supporting Services
- **Azure Key Vault**: Centralized secrets management
- **Application Insights**: Application performance monitoring
- **Log Analytics Workspace**: Centralized logging and diagnostics

## Architecture Diagram

```
┌─────────────────┐
│   User/Client   │
└────────┬────────┘
         │
    ┌────▼─────┐
    │ Web App  │◄────────┐
    └────┬─────┘         │
         │               │
    ┌────▼──────────┐    │
    │  AI Services  │    │
    │  (Chat/LLM)   │    │
    └────┬──────────┘    │
         │               │
    ┌────▼──────────┐    │
    │  AI Search    │    │
    │ (Vector Store)│    │
    └────┬──────────┘    │
         │               │
    ┌────▼──────────┐    │
    │  Cosmos DB    │◄───┤
    │  (Metadata)   │    │
    └───────────────┘    │
                         │
┌──────────────────────┐ │
│  Blob Storage        │ │
│  (Documents)         │ │
└────┬─────────────────┘ │
     │                   │
     │ (Trigger)         │
     │                   │
┌────▼──────────────┐    │
│  Function Apps    │────┘
│  - Ingestion      │
│  - Classification │
│  - Intelligence   │
│  - Embedding      │
│  - Orchestrator   │
└────┬──────────────┘
     │
┌────▼──────────────┐
│  Service Bus      │
│  (Queues)         │
└────┬──────────────┘
     │
┌────▼──────────────┐
│  Document         │
│  Intelligence     │
└───────────────────┘
```

## File Structure

```
infra/
├── main.bicep                    # Main orchestration template
├── main.bicepparam              # Development environment parameters
├── main.prod.bicepparam         # Production environment parameters
└── README.md                    # This file
```

## Prerequisites

Before deploying this infrastructure, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   az --version
   az login
   ```

2. **Bicep CLI** installed (version 0.24.0 or later)
   ```bash
   az bicep version
   az bicep upgrade
   ```

3. **Azure Subscription** with appropriate permissions:
   - Contributor role (or higher) on the target resource group
   - User Access Administrator role for creating role assignments

4. **Resource Providers** registered:
   ```bash
   az provider register --namespace Microsoft.Storage
   az provider register --namespace Microsoft.DocumentDB
   az provider register --namespace Microsoft.CognitiveServices
   az provider register --namespace Microsoft.Search
   az provider register --namespace Microsoft.ServiceBus
   az provider register --namespace Microsoft.Web
   az provider register --namespace Microsoft.KeyVault
   az provider register --namespace Microsoft.Insights
   az provider register --namespace Microsoft.OperationalInsights
   ```

## Deployment Instructions

### 1. Create Resource Group

```bash
# For development environment
az group create \
  --name rg-docproc-dev \
  --location eastus

# For production environment
az group create \
  --name rg-docproc-prod \
  --location eastus
```

### 2. Validate the Bicep Template

```bash
# Validate development deployment
az deployment group validate \
  --resource-group rg-docproc-dev \
  --template-file main.bicep \
  --parameters main.bicepparam

# Validate production deployment
az deployment group validate \
  --resource-group rg-docproc-prod \
  --template-file main.bicep \
  --parameters main.prod.bicepparam
```

### 3. Preview Changes (What-If)

```bash
# Preview development deployment
az deployment group what-if \
  --resource-group rg-docproc-dev \
  --template-file main.bicep \
  --parameters main.bicepparam

# Preview production deployment
az deployment group what-if \
  --resource-group rg-docproc-prod \
  --template-file main.bicep \
  --parameters main.prod.bicepparam
```

### 4. Deploy the Infrastructure

```bash
# Deploy to development
az deployment group create \
  --resource-group rg-docproc-dev \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --name docproc-deployment-$(date +%Y%m%d-%H%M%S)

# Deploy to production
az deployment group create \
  --resource-group rg-docproc-prod \
  --template-file main.bicep \
  --parameters main.prod.bicepparam \
  --name docproc-deployment-$(date +%Y%m%d-%H%M%S) \
  --confirm-with-what-if
```

### 5. Retrieve Deployment Outputs

```bash
# Get all outputs
az deployment group show \
  --resource-group rg-docproc-dev \
  --name <deployment-name> \
  --query properties.outputs

# Get specific output (e.g., Function App name)
az deployment group show \
  --resource-group rg-docproc-dev \
  --name <deployment-name> \
  --query properties.outputs.functionAppName.value \
  --output tsv
```

## Configuration

### Environment-Specific Parameters

The deployment supports three environments with different configurations:

#### Development (`main.bicepparam`)
- **Cost-optimized** for development and testing
- Consumption plan for Functions (pay-per-execution)
- Basic/Free tiers for AI services
- Standard LRS storage
- Minimal autoscale for Cosmos DB (400-1000 RU/s)

#### Production (`main.prod.bicepparam`)
- **Production-ready** with high availability
- Premium plan for Functions (always-on, VNet integration)
- Standard tiers for AI services
- Zone-redundant storage (ZRS)
- Higher autoscale for Cosmos DB (400-4000 RU/s)
- Multiple replicas for Search Service

### Customizable Parameters

Key parameters you can customize:

| Parameter | Description | Default (Dev) | Default (Prod) |
|-----------|-------------|---------------|----------------|
| `environmentName` | Environment name | `dev` | `prod` |
| `location` | Azure region | `eastus` | `eastus` |
| `projectName` | Project identifier | `docproc` | `docproc` |
| `storageAccountSkuName` | Storage replication | `Standard_LRS` | `Standard_ZRS` |
| `cosmosDbAutoscaleMaxThroughput` | Max RU/s | `1000` | `4000` |
| `documentIntelligenceSku` | Doc Intelligence tier | `F0` | `S0` |
| `searchServiceSku` | Search tier | `basic` | `standard` |
| `functionAppPlanSku` | Function plan | `Y1` | `EP1` |
| `webAppPlanSku` | Web App plan | `B1` | `S1` |

## Security Features

### Managed Identities

All compute resources (Function Apps, Web App) are configured with system-assigned managed identities and appropriate RBAC roles:

- **Function App**:
  - Storage Blob Data Contributor (blob access)
  - Cosmos DB Data Contributor (database write access)
  - Service Bus Data Owner (queue operations)
  - Cognitive Services User (AI services)
  - Search Index Data Contributor (indexing)
  - Key Vault Secrets User (secret access)

- **Web App**:
  - Cosmos DB Data Reader (database read access)
  - Cognitive Services User (AI services)
  - Search Index Data Reader (search queries)
  - Key Vault Secrets User (secret access)

### Network Security

- HTTPS enforced on all web-facing services
- TLS 1.2 minimum for all connections
- Public blob access disabled
- FTPS disabled on App Services

### Secret Management

- All secrets stored in Key Vault
- No secrets in outputs or configuration
- Managed identities for authentication (no connection strings)

## Post-Deployment Steps

After deploying the infrastructure, complete these steps:

### 1. Configure AI Search Index

Create a search index with vector fields:

```bash
# Use Azure Portal or Azure CLI to create index
# Include fields for: content, contentVector, metadata, documentId, etc.
```

### 2. Deploy Function App Code

```bash
# Deploy your Functions code
func azure functionapp publish <function-app-name>
```

### 3. Deploy Web App Code

```bash
# Deploy your Web App code
az webapp deployment source config-zip \
  --resource-group rg-docproc-dev \
  --name <web-app-name> \
  --src app.zip
```

### 4. Configure CORS (if needed)

```bash
az webapp cors add \
  --resource-group rg-docproc-dev \
  --name <web-app-name> \
  --allowed-origins https://yourdomain.com
```

### 5. Set Up Custom Domain (Production)

```bash
# Add custom domain
az webapp config hostname add \
  --resource-group rg-docproc-prod \
  --webapp-name <web-app-name> \
  --hostname yourdomain.com

# Bind SSL certificate
az webapp config ssl bind \
  --resource-group rg-docproc-prod \
  --name <web-app-name> \
  --certificate-thumbprint <thumbprint> \
  --ssl-type SNI
```

## Monitoring and Observability

### Application Insights

All services send telemetry to Application Insights for monitoring:

- Request rates and response times
- Dependency tracking (Cosmos DB, Storage, AI Services)
- Exception tracking
- Custom metrics and events

### Log Analytics

Diagnostic logs from all services are collected in Log Analytics:

```kusto
// Query example: Function execution failures
AzureDiagnostics
| where ResourceType == "MICROSOFT.WEB/SITES"
| where Category == "FunctionAppLogs"
| where Level == "Error"
| order by TimeGenerated desc
```

### Metrics and Alerts

Key metrics to monitor:

- Function execution count and duration
- Service Bus queue depth
- Cosmos DB RU consumption
- Storage account transactions
- AI service API calls and latency

## Cost Estimation

### Development Environment (Monthly)
- Storage Account: ~$5-10
- Cosmos DB (400-1000 RU/s): ~$25-50
- AI Services (F0): Free
- Search Service (Basic): ~$75
- Service Bus (Standard): ~$10
- Functions (Consumption): ~$5-20
- Web App (B1): ~$13
- Application Insights: ~$5-10
- **Total: ~$140-200/month**

### Production Environment (Monthly)
- Storage Account (ZRS): ~$20-40
- Cosmos DB (400-4000 RU/s): ~$100-200
- AI Services (S0): ~$100-500
- Search Service (Standard, 2 replicas): ~$250
- Service Bus (Standard): ~$10
- Functions (EP1): ~$150
- Web App (S1): ~$70
- Application Insights: ~$20-50
- **Total: ~$720-1,300/month**

*Costs vary based on usage, data volume, and region.*

## Troubleshooting

### Common Issues

1. **Deployment fails with "Resource provider not registered"**
   - Solution: Register required resource providers (see Prerequisites)

2. **Role assignments fail**
   - Solution: Ensure you have User Access Administrator role

3. **Function App can't access Storage/Cosmos DB**
   - Solution: Verify managed identity is enabled and role assignments are correct

4. **AI services quota exceeded**
   - Solution: Request quota increase or use S0 tier

5. **Bicep module not found**
   - Solution: Ensure you have internet connectivity and can access Azure Container Registry

### Support

For issues or questions:
1. Check Azure Portal for resource status and diagnostics
2. Review Application Insights for errors
3. Check Log Analytics for detailed logs
4. Consult Azure documentation

## Clean Up

To remove all resources:

```bash
# Delete development resource group
az group delete \
  --name rg-docproc-dev \
  --yes \
  --no-wait

# Delete production resource group
az group delete \
  --name rg-docproc-prod \
  --yes \
  --no-wait
```

⚠️ **Warning**: This will permanently delete all resources and data. Ensure you have backups if needed.

## Contributing

When modifying these templates:

1. Follow the Bicep best practices in `.github/instructions/bicep-code-best-practices.instructions.md`
2. Use lowerCamelCase for naming
3. Add `@description` decorators to all parameters
4. Test in development before production
5. Validate and lint before committing:
   ```bash
   bicep build main.bicep --stdout
   az bicep lint --file main.bicep
   ```

## References

- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Verified Modules](https://aka.ms/avm)
- [Azure AI Document Intelligence](https://learn.microsoft.com/azure/ai-services/document-intelligence/)
- [Azure AI Search](https://learn.microsoft.com/azure/search/)
- [Azure Durable Functions](https://learn.microsoft.com/azure/azure-functions/durable/)

## License

Copyright (c) 2024. All rights reserved.
