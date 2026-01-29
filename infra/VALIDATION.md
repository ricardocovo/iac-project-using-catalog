# Bicep Template Validation Guide

This document provides step-by-step instructions for validating the Bicep templates before deployment.

## Prerequisites

- Azure CLI installed and logged in
- Bicep CLI version 0.24.0 or later
- Access to target Azure subscription

## Validation Steps

### 1. Syntax Validation

Check for syntax errors in the Bicep template:

```bash
cd infra/
bicep build main.bicep --stdout > /dev/null
```

Expected output: No errors (warnings are acceptable).

### 2. Linting

Run the Bicep linter to check for best practices:

```bash
bicep lint main.bicep
```

The linter will check for:
- Unused parameters and variables
- Security best practices
- Naming conventions
- API version warnings

### 3. Format Check

Ensure consistent formatting:

```bash
bicep format main.bicep
```

This will auto-format the file according to Bicep conventions.

### 4. Module Validation

Verify all referenced modules are accessible:

```bash
bicep restore main.bicep
```

This downloads and caches all external modules. Expected modules:
- `avm/res/operational-insights/workspace`
- `avm/res/insights/component`
- `avm/res/key-vault/vault`
- `avm/res/storage/storage-account`
- `avm/res/document-db/database-account`
- `avm/res/cognitive-services/account`
- `avm/res/search/search-service`
- `avm/res/service-bus/namespace`
- `avm/res/web/serverfarm`
- `avm/res/web/site`
- `avm/ptn/authorization/resource-role-assignment`

### 5. Parameter File Validation

Validate parameter files:

```bash
# Development parameters
az bicep build-params main.bicepparam

# Production parameters
az bicep build-params main.prod.bicepparam
```

### 6. Azure Validation

Validate against Azure (requires active subscription):

```bash
# Create a test resource group
az group create --name rg-bicep-validation-test --location eastus

# Validate development template
az deployment group validate \
  --resource-group rg-bicep-validation-test \
  --template-file main.bicep \
  --parameters main.bicepparam

# Validate production template
az deployment group validate \
  --resource-group rg-bicep-validation-test \
  --template-file main.bicep \
  --parameters main.prod.bicepparam

# Clean up test resource group
az group delete --name rg-bicep-validation-test --yes --no-wait
```

### 7. What-If Analysis

Preview what resources will be created:

```bash
az deployment group what-if \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters main.bicepparam
```

Review the output carefully to ensure:
- Correct number of resources
- Proper naming conventions
- Expected resource types
- Appropriate configurations

## Expected Resources

The template should create the following resources:

### Core Infrastructure (26 resources)

1. **Monitoring & Logging (3)**
   - Log Analytics Workspace
   - Application Insights
   - Diagnostic Settings (multiple)

2. **Security (1)**
   - Key Vault

3. **Storage (1)**
   - Storage Account (with 3 blob containers)

4. **Database (1)**
   - Cosmos DB Account (with 1 database and 4 containers)

5. **AI Services (3)**
   - AI Document Intelligence (Form Recognizer)
   - AI Services (for embeddings/chat)
   - AI Search Service

6. **Messaging (1)**
   - Service Bus Namespace (with 5 queues)

7. **Compute (4)**
   - Function App Hosting Plan
   - Function App
   - Web App Hosting Plan
   - Web App

8. **Role Assignments (11)**
   - Function App → Storage Blob Data Contributor
   - Function App → Cosmos DB Data Contributor
   - Function App → Service Bus Data Owner
   - Function App → Cognitive Services User (Document Intelligence)
   - Function App → Cognitive Services User (AI Services)
   - Function App → Search Index Data Contributor
   - Function App → Key Vault Secrets User
   - Web App → Cosmos DB Data Reader
   - Web App → Cognitive Services User
   - Web App → Search Index Data Reader
   - Web App → Key Vault Secrets User

## Checklist

Use this checklist to verify the template:

- [ ] No syntax errors
- [ ] Linter passes (no errors, warnings acceptable)
- [ ] All modules restore successfully
- [ ] Parameter files are valid
- [ ] Azure validation succeeds
- [ ] What-if output shows expected resources
- [ ] Resource names follow naming conventions
- [ ] All parameters have @description decorators
- [ ] No secrets in outputs
- [ ] Managed identities configured for compute resources
- [ ] RBAC roles assigned appropriately
- [ ] Diagnostic settings configured for all resources
- [ ] Tags applied to all resources
- [ ] Cost-appropriate SKUs for environment

## Common Issues and Solutions

### Issue: Module Not Found

**Error**: `BCP190: The artifact with reference "br/public:avm/..." has not been restored`

**Solution**: Run `bicep restore main.bicep` to download modules.

### Issue: Validation Fails - Resource Provider Not Registered

**Error**: `The subscription is not registered to use namespace...`

**Solution**: Register required resource providers:
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

### Issue: Parameter Value Out of Range

**Error**: Parameter value validation failed

**Solution**: Check parameter constraints in the template and ensure values in parameter files are within allowed ranges.

### Issue: Quota Exceeded

**Error**: Operation could not be completed as it results in exceeding quota limits

**Solution**: 
1. Request quota increase in Azure Portal
2. Use lower SKUs for development
3. Clean up unused resources

### Issue: Name Already Exists

**Error**: The resource name is already in use

**Solution**: The template uses `uniqueString()` to generate unique names. This should be rare, but you can:
1. Change the `projectName` parameter
2. Deploy to a different resource group
3. Delete the existing resource if safe to do so

## Performance Testing

After validation, consider:

1. **Deployment Time**: Track how long deployment takes
   - Expected: 15-25 minutes for initial deployment
   - Subsequent deployments: 5-10 minutes (only changes deployed)

2. **Resource Provisioning**: Verify all resources are in "Succeeded" state

3. **Connectivity**: Test connectivity between resources
   - Function App can access Storage
   - Function App can access Cosmos DB
   - Web App can access AI Services

4. **Role Assignments**: Verify managed identities have correct permissions
   ```bash
   # List role assignments for Function App
   az role assignment list \
     --assignee <function-app-principal-id> \
     --all
   ```

## Security Review

Before production deployment:

- [ ] Review all role assignments (principle of least privilege)
- [ ] Verify HTTPS-only enforcement
- [ ] Check TLS version (minimum 1.2)
- [ ] Confirm public access is disabled where appropriate
- [ ] Review Key Vault access policies/RBAC
- [ ] Verify soft delete is enabled for Key Vault and Storage
- [ ] Check diagnostic logging is enabled for all resources
- [ ] Review network security (consider private endpoints for production)

## Compliance Validation

Ensure the deployment meets organizational requirements:

- [ ] All resources have required tags
- [ ] Cost center is specified
- [ ] Owner is identified
- [ ] Data classification is set
- [ ] Resources deployed in approved regions
- [ ] Approved SKUs and tiers used
- [ ] Naming conventions followed

## Next Steps After Validation

Once validation passes:

1. Create a change request (if required by your process)
2. Schedule deployment window
3. Run deployment script (`deploy-dev.sh` or `deploy-prod.sh`)
4. Verify deployment outputs
5. Complete post-deployment configuration
6. Run integration tests
7. Document any issues or deviations

## Automated Validation (CI/CD)

Consider automating validation in your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
name: Validate Bicep Templates

on:
  pull_request:
    paths:
      - 'infra/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Bicep
        run: |
          curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
          chmod +x ./bicep
          sudo mv ./bicep /usr/local/bin/bicep
      
      - name: Build Bicep
        run: |
          cd infra
          bicep build main.bicep --stdout > /dev/null
      
      - name: Lint Bicep
        run: |
          cd infra
          bicep lint main.bicep
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Validate Template
        run: |
          az deployment group validate \
            --resource-group ${{ secrets.RESOURCE_GROUP }} \
            --template-file infra/main.bicep \
            --parameters infra/main.bicepparam
```

## Contact

For questions or issues with validation:
- Review Azure Bicep documentation: https://learn.microsoft.com/azure/azure-resource-manager/bicep/
- Check Azure Verified Modules: https://aka.ms/avm
- Contact the platform team

