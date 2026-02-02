#!/bin/bash

# Script to deploy Azure infrastructure using Bicep
# Usage: ./deploy.sh <environment> [resource-group-name]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if environment parameter is provided
if [ -z "$1" ]; then
    print_error "Environment parameter is required!"
    echo "Usage: ./deploy.sh <environment> [resource-group-name]"
    echo "Environments: dev, staging, prod"
    exit 1
fi

ENVIRONMENT=$1
PARAM_FILE="main.${ENVIRONMENT}.bicepparam"

# Check if parameter file exists
if [ ! -f "$PARAM_FILE" ]; then
    print_error "Parameter file '$PARAM_FILE' not found!"
    exit 1
fi

# Set resource group name
if [ -z "$2" ]; then
    RESOURCE_GROUP="rg-docproc-${ENVIRONMENT}"
    print_info "Using default resource group: $RESOURCE_GROUP"
else
    RESOURCE_GROUP=$2
    print_info "Using provided resource group: $RESOURCE_GROUP"
fi

# Get location from parameter file (default to eastus if not found)
LOCATION=$(grep "location = " "$PARAM_FILE" | cut -d "'" -f 2 || echo "eastus")

print_info "Deployment Configuration:"
echo "  Environment: $ENVIRONMENT"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Parameter File: $PARAM_FILE"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Azure
print_info "Checking Azure CLI login status..."
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
print_info "Using subscription: $SUBSCRIPTION_NAME"

# Create resource group if it doesn't exist
print_info "Checking if resource group exists..."
if ! az group exists --name "$RESOURCE_GROUP" | grep -q "true"; then
    print_info "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
    print_info "Resource group '$RESOURCE_GROUP' already exists."
fi

# Validate the deployment
print_info "Validating Bicep template..."
if az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters "$PARAM_FILE" \
    --output none; then
    print_info "Template validation successful!"
else
    print_error "Template validation failed!"
    exit 1
fi

# Ask for confirmation
echo ""
read -p "Do you want to proceed with the deployment? (yes/no): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy][Ee][Ss]$ ]]; then
    print_warning "Deployment cancelled."
    exit 0
fi

# Deploy the infrastructure
print_info "Starting deployment..."
DEPLOYMENT_NAME="main-$(date +%Y%m%d-%H%M%S)"

if az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters "$PARAM_FILE" \
    --name "$DEPLOYMENT_NAME" \
    --output table; then
    print_info "Deployment completed successfully!"
    
    # Show outputs
    echo ""
    print_info "Deployment Outputs:"
    az deployment group show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs \
        --output table
else
    print_error "Deployment failed!"
    exit 1
fi

print_info "Deployment complete!"
