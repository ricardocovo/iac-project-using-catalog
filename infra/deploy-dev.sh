#!/bin/bash
# ============================================================================
# Deploy Document Processing System to Development Environment
# ============================================================================

set -e

# Configuration
RESOURCE_GROUP="rg-docproc-dev"
LOCATION="eastus"
DEPLOYMENT_NAME="docproc-deployment-$(date +%Y%m%d-%H%M%S)"
TEMPLATE_FILE="main.bicep"
PARAMETERS_FILE="main.bicepparam"

echo "========================================"
echo "Document Processing System Deployment"
echo "Environment: Development"
echo "========================================"
echo ""

# Check if logged in to Azure
echo "Checking Azure login status..."
az account show > /dev/null 2>&1 || {
    echo "Not logged in to Azure. Please run 'az login' first."
    exit 1
}

# Display current subscription
echo "Current subscription:"
az account show --query "{Name:name, SubscriptionId:id}" -o table
echo ""

read -p "Is this the correct subscription? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please switch to the correct subscription using 'az account set -s <subscription-id>'"
    exit 1
fi

# Create resource group if it doesn't exist
echo "Creating resource group if not exists..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags Environment=dev Project=document-processing ManagedBy=Bicep
echo ""

# Validate the template
echo "Validating Bicep template..."
az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMETERS_FILE" \
    --no-prompt
echo ""

# Show what-if results
echo "Generating deployment preview (what-if)..."
az deployment group what-if \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMETERS_FILE" \
    --no-prompt
echo ""

read -p "Proceed with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Deploy the template
echo "Deploying infrastructure..."
az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMETERS_FILE" \
    --name "$DEPLOYMENT_NAME" \
    --no-prompt \
    --query properties.outputs -o json | tee deployment-outputs.json

echo ""
echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo "Deployment name: $DEPLOYMENT_NAME"
echo "Resource group: $RESOURCE_GROUP"
echo "Outputs saved to: deployment-outputs.json"
echo ""

# Display key outputs
echo "Key Resources:"
az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query "properties.outputs.{FunctionApp:functionAppName.value, WebApp:webAppName.value, Storage:storageAccountName.value, CosmosDB:cosmosDbAccountName.value}" \
    -o table

echo ""
echo "Next steps:"
echo "1. Deploy Function App code"
echo "2. Deploy Web App code"
echo "3. Configure AI Search index"
echo "4. Test the end-to-end flow"
