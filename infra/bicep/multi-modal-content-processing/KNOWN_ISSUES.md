# Known Issues

## Module Catalog Issues

The following issues exist in the iac-module-catalog modules that prevent successful compilation:

### 1. Search Service Module (`search-service.bicep`)

**Issue**: Two type mismatches in the underlying AVM module reference
- Line 42: `sku` property expects a string but receives an object
- Line 47: `publicNetworkAccess` expects 'Disabled'|'Enabled' (capitalized) but receives 'disabled'|'enabled' (lowercase)

**Impact**: Cannot compile templates using the search-service module

**Workaround**: Module needs to be fixed in catalog

### 2. Storage Account Module (`storage-account.bicep`)

**Issue**: Line 68 references `outputs.primaryEndpoints` which doesn't exist in the AVM module
- The property should likely be `primaryEndpoints` directly or handled differently

**Impact**: Cannot compile templates using storage-account module outputs for primaryEndpoints

**Workaround**: Don't reference `storageAccount.outputs.primaryEndpoints` in your templates

## Template Limitations

### RBAC Role Assignments

RBAC role assignments have been removed from the template due to complexity with resource references. 

**Post-Deployment Configuration Required:**

After deploying the infrastructure, manually assign the following roles:

#### Processor Identity Roles
```bash
PROCESSOR_IDENTITY_ID=$(az identity show \
  --name <processor-identity-name> \
  --resource-group <rg-name> \
  --query principalId -o tsv)

# Storage Blob Data Contributor
az role assignment create \
  --assignee $PROCESSOR_IDENTITY_ID \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Storage/storageAccounts/<storage-name>

# Storage Queue Data Contributor  
az role assignment create \
  --assignee $PROCESSOR_IDENTITY_ID \
  --role "Storage Queue Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Storage/storageAccounts/<storage-name>

# Cosmos DB Built-in Data Contributor
az cosmosdb sql role assignment create \
  --account-name <cosmos-account-name> \
  --resource-group <rg-name> \
  --scope "/" \
  --principal-id $PROCESSOR_IDENTITY_ID \
  --role-definition-id 00000000-0000-0000-0000-000000000002

# Cognitive Services User (OpenAI)
az role assignment create \
  --assignee $PROCESSOR_IDENTITY_ID \
  --role "Cognitive Services User" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.CognitiveServices/accounts/<openai-name>

# Cognitive Services User (Vision)
az role assignment create \
  --assignee $PROCESSOR_IDENTITY_ID \
  --role "Cognitive Services User" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.CognitiveServices/accounts/<vision-name>

# Search Index Data Contributor
az role assignment create \
  --assignee $PROCESSOR_IDENTITY_ID \
  --role "Search Index Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Search/searchServices/<search-name>

# AcrPull
az role assignment create \
  --assignee $PROCESSOR_IDENTITY_ID \
  --role "AcrPull" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.ContainerRegistry/registries/<acr-name>
```

#### API Identity Roles
```bash
API_IDENTITY_ID=$(az identity show \
  --name <api-identity-name> \
  --resource-group <rg-name> \
  --query principalId -o tsv)

# Storage Blob Data Contributor & Queue Data Contributor
az role assignment create --assignee $API_IDENTITY_ID --role "Storage Blob Data Contributor" --scope <storage-scope>
az role assignment create --assignee $API_IDENTITY_ID --role "Storage Queue Data Contributor" --scope <storage-scope>

# Cosmos DB Built-in Data Reader
az cosmosdb sql role assignment create \
  --account-name <cosmos-account-name> \
  --resource-group <rg-name> \
  --scope "/" \
  --principal-id $API_IDENTITY_ID \
  --role-definition-id 00000000-0000-0000-0000-000000000001

# Search Index Data Reader
az role assignment create --assignee $API_IDENTITY_ID --role "Search Index Data Reader" --scope <search-scope>

# AcrPull
az role assignment create --assignee $API_IDENTITY_ID --role "AcrPull" --scope <acr-scope>
```

### Queue Storage

The storage account module doesn't support creating queues directly. Queues must be created post-deployment:

```bash
az storage queue create --name processing-queue --account-name <storage-name>
az storage queue create --name failed-queue --account-name <storage-name>
```

## Recommendations

1. **Fix Module Catalog**: Update the search-service and storage-account modules in the catalog
2. **Add Queue Support**: Enhance storage-account module to support queue creation
3. **RBAC Support**: Consider adding RBAC assignment capabilities to modules or create a separate RBAC module

## Testing Status

✅ Bicep syntax is valid (excluding catalog module issues)
✅ Parameters file created
✅ README with deployment instructions
❌ Cannot compile due to catalog module bugs
❌ Untested deployment (blocked by compilation)

