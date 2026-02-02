# Azure Infrastructure Deployment Guide

This guide provides instructions for deploying the document processing infrastructure to Azure.

## Quick Start

### Prerequisites
- Azure CLI installed and configured
- Bicep CLI (included with Azure CLI 2.20.0+)
- Azure subscription with appropriate permissions
- Bash shell (Linux, macOS, or WSL on Windows)

### Deploy in 3 Steps

1. **Login to Azure**
   ```bash
   az login
   ```

2. **Navigate to infrastructure directory**
   ```bash
   cd infra
   ```

3. **Run deployment script**
   ```bash
   ./deploy.sh dev
   ```

## What Gets Deployed

The infrastructure includes:

### Core Services
- **Azure Storage Account** (General Purpose v2)
  - Two blob containers: `documents-input` and `documents-output`
  - TLS 1.2+ encryption, soft delete enabled
  
- **Azure Service Bus** (Standard tier)
  - Queue: `document-processing-queue`
  - Dead letter queue enabled
  - Message TTL: 14 days
  
- **Azure AI Document Intelligence** (S0 tier)
  - Custom subdomain for API access
  - Supports OCR, form recognition, layout analysis

### Resource Naming
Resources are automatically named using the pattern:
- Storage: `st{project}{env}{uniqueHash}`
- Service Bus: `sb-{project}-{env}-{uniqueHash}`
- Document Intelligence: `di-{project}-{env}-{uniqueHash}`

## Deployment Options

### Option 1: Using Deployment Script (Recommended)

```bash
cd infra
./deploy.sh dev                        # Deploy to dev
./deploy.sh staging                    # Deploy to staging
./deploy.sh prod                       # Deploy to prod
```

The script will:
- Validate your Azure login
- Check if the resource group exists (creates if needed)
- Validate the Bicep template
- Ask for confirmation before deploying
- Show deployment outputs after completion

### Option 2: Manual Deployment

```bash
# Create resource group
az group create --name rg-docproc-dev --location eastus

# Deploy infrastructure
az deployment group create \
  --resource-group rg-docproc-dev \
  --template-file infra/main.bicep \
  --parameters infra/main.dev.bicepparam
```

## Environment Configuration

### Development Environment
File: `infra/main.dev.bicepparam`
- Environment: dev
- Project: docproc
- Location: eastus

### Staging Environment
File: `infra/main.staging.bicepparam`
- Environment: staging
- Project: docproc
- Location: eastus

### Production Environment
File: `infra/main.prod.bicepparam`
- Environment: prod
- Project: docproc
- Location: eastus

You can customize these files to change:
- Azure region (`location`)
- Project name (`projectName`)
- Environment name (`environmentName`)

## Validation

### Before Deployment

```bash
cd infra

# Syntax check
bicep build main.bicep

# Lint check
bicep lint main.bicep

# Dry-run validation
az deployment group validate \
  --resource-group rg-docproc-dev \
  --template-file main.bicep \
  --parameters main.dev.bicepparam
```

### After Deployment

```bash
# List deployed resources
az resource list --resource-group rg-docproc-dev --output table

# Get deployment outputs
az deployment group show \
  --resource-group rg-docproc-dev \
  --name main \
  --query properties.outputs
```

## Architecture Reference

For detailed architecture specifications, see:
- [Architecture Specification](docs/specifications/architecture-specification.md)
- [Architecture Diagram](docs/architecture/azure-architecture.svg)

## Cost Estimates

### Development Environment (Estimated Monthly)
- Storage Account (LRS): ~$1-5
- Service Bus (Standard): ~$10
- Document Intelligence (S0): ~$50-100
- **Total**: ~$60-115/month

### Production Considerations
- Consider upgrading Service Bus to Premium for higher throughput
- Use GRS storage for geo-redundancy
- Monitor Document Intelligence usage and adjust tier as needed

## Security Recommendations

1. **Enable Managed Identities** for service-to-service authentication
2. **Store secrets** in Azure Key Vault
3. **Configure Private Endpoints** for production environments
4. **Enable diagnostic logging** to Azure Monitor
5. **Implement RBAC** with least privilege principle

## Troubleshooting

### Issue: Storage account name already exists
**Solution**: Storage account names must be globally unique. The template uses `uniqueString()` which should prevent conflicts.

### Issue: Document Intelligence not available in region
**Solution**: Change the `location` parameter to a supported region (e.g., eastus, westus2, westeurope)

### Issue: Quota exceeded
**Solution**: Request quota increase via Azure Portal or contact support

### View Deployment Errors
```bash
az deployment group show \
  --resource-group rg-docproc-dev \
  --name main \
  --query properties.error
```

## Cleanup

To delete all resources:

```bash
# Development
az group delete --name rg-docproc-dev --yes --no-wait

# Staging
az group delete --name rg-docproc-staging --yes --no-wait

# Production
az group delete --name rg-docproc-prod --yes --no-wait
```

⚠️ **Warning**: This will permanently delete all resources in the resource group.

## Next Steps

After deployment:

1. **Configure application settings** to use the deployed resources
2. **Set up CI/CD pipeline** for automated deployments
3. **Enable monitoring** with Application Insights
4. **Configure alerts** for critical metrics
5. **Implement backup strategy** for production data

## Support

For issues or questions:
- Review the [Architecture Specification](docs/specifications/architecture-specification.md)
- Check the [Infrastructure README](infra/README.md)
- Consult [Azure Documentation](https://learn.microsoft.com/azure/)

---
*Last Updated: February 1, 2026*
