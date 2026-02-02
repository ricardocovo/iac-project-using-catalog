# Infrastructure Deployment

This directory contains Bicep templates for deploying the document processing architecture on Azure.

## Architecture Overview

The infrastructure deploys the following Azure resources:

1. **Azure Storage Account** - Stores input and output documents
   - Input container: `documents-input`
   - Output container: `documents-output`
   - Features: Soft delete, encryption at rest, HTTPS only

2. **Azure Service Bus** - Message queue for document processing workflow
   - Standard tier namespace
   - Queue: `document-processing-queue`
   - Dead letter queue enabled
   - Message TTL: 14 days

3. **Azure AI Document Intelligence** - AI-powered document analysis
   - SKU: S0 (Standard)
   - Supports OCR, form recognition, and layout analysis

## Prerequisites

- Azure CLI installed and logged in
- Bicep CLI installed (comes with Azure CLI 2.20.0+)
- Appropriate Azure permissions to create resources
- An Azure subscription

## Deployment

### 1. Create Resource Group

```bash
az group create \
  --name rg-docproc-dev \
  --location eastus
```

### 2. Deploy Infrastructure

#### Development Environment

```bash
az deployment group create \
  --resource-group rg-docproc-dev \
  --template-file infra/main.bicep \
  --parameters infra/main.dev.bicepparam
```

#### Staging Environment

```bash
az deployment group create \
  --resource-group rg-docproc-staging \
  --template-file infra/main.bicep \
  --parameters infra/main.staging.bicepparam
```

#### Production Environment

```bash
az deployment group create \
  --resource-group rg-docproc-prod \
  --template-file infra/main.bicep \
  --parameters infra/main.prod.bicepparam
```

### 3. Verify Deployment

```bash
# List deployed resources
az resource list --resource-group rg-docproc-dev --output table

# Get deployment outputs
az deployment group show \
  --resource-group rg-docproc-dev \
  --name main \
  --query properties.outputs
```

## Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `environmentName` | string | Environment name (dev/staging/prod) | `dev` |
| `projectName` | string | Project name (3-10 chars) | Required |
| `location` | string | Azure region | Resource Group location |
| `tags` | object | Resource tags | Auto-generated |

## Outputs

The deployment provides the following outputs:

- `storageAccountName` - Name of the storage account
- `storageAccountId` - Resource ID of the storage account
- `inputContainerName` - Name of the input container
- `outputContainerName` - Name of the output container
- `serviceBusNamespaceName` - Name of the Service Bus namespace
- `serviceBusNamespaceId` - Resource ID of the Service Bus namespace
- `serviceBusQueueName` - Name of the queue
- `documentIntelligenceName` - Name of the Document Intelligence service
- `documentIntelligenceId` - Resource ID of the Document Intelligence service
- `documentIntelligenceEndpoint` - Endpoint URL for Document Intelligence

## Resource Naming Convention

Resources follow a consistent naming pattern:

- Storage Account: `st<projectName><env><uniqueHash>`
- Service Bus: `sb-<projectName>-<env>-<uniqueHash>`
- Document Intelligence: `di-<projectName>-<env>-<uniqueHash>`

## Security Considerations

- Storage accounts require HTTPS (TLS 1.2+)
- Blob public access is disabled
- Soft delete enabled for containers and blobs (7 days)
- Service Bus uses TLS 1.2+
- Managed identities recommended for service-to-service authentication

## Cost Optimization

### Development Environment
- Storage: Standard LRS tier
- Service Bus: Standard tier
- Document Intelligence: S0 tier

### Production Recommendations
- Consider Standard GRS for storage redundancy
- Upgrade to Service Bus Premium for higher throughput
- Monitor Document Intelligence usage and adjust tier as needed

## Testing

### Validate Bicep Template

```bash
# Check syntax
az bicep build --file infra/main.bicep

# Validate deployment (no actual deployment)
az deployment group validate \
  --resource-group rg-docproc-dev \
  --template-file infra/main.bicep \
  --parameters infra/main.dev.bicepparam
```

### What-If Analysis

```bash
az deployment group what-if \
  --resource-group rg-docproc-dev \
  --template-file infra/main.bicep \
  --parameters infra/main.dev.bicepparam
```

## Cleanup

To delete all resources:

```bash
az group delete --name rg-docproc-dev --yes --no-wait
```

## Troubleshooting

### Common Issues

1. **Storage account name conflict**: Storage account names must be globally unique. The template uses `uniqueString()` to avoid conflicts.

2. **Document Intelligence not available**: Ensure the selected region supports Azure AI Document Intelligence.

3. **Quota limits**: Check subscription quotas for Cognitive Services.

### Get Deployment Logs

```bash
az deployment group show \
  --resource-group rg-docproc-dev \
  --name main \
  --query properties.error
```

## Additional Resources

- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Architecture Specification](../docs/specifications/architecture-specification.md)
- [Azure AI Document Intelligence](https://learn.microsoft.com/azure/ai-services/document-intelligence/)
