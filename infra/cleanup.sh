#!/bin/bash
# ============================================================================
# Cleanup Script - Delete Document Processing System Resources
# ============================================================================

set -e

echo "========================================"
echo "Document Processing System Cleanup"
echo "========================================"
echo ""
echo "⚠️  WARNING: This will DELETE all resources ⚠️"
echo ""

# Check if logged in to Azure
az account show > /dev/null 2>&1 || {
    echo "Not logged in to Azure. Please run 'az login' first."
    exit 1
}

echo "Select environment to delete:"
echo "1) Development (rg-docproc-dev)"
echo "2) Production (rg-docproc-prod)"
echo "3) Both"
echo "4) Cancel"
echo ""

read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        RESOURCE_GROUPS=("rg-docproc-dev")
        ;;
    2)
        RESOURCE_GROUPS=("rg-docproc-prod")
        echo ""
        echo "⚠️  You are about to delete PRODUCTION resources! ⚠️"
        ;;
    3)
        RESOURCE_GROUPS=("rg-docproc-dev" "rg-docproc-prod")
        echo ""
        echo "⚠️  You are about to delete ALL environments! ⚠️"
        ;;
    4)
        echo "Cleanup cancelled."
        exit 0
        ;;
    *)
        echo "Invalid choice. Cleanup cancelled."
        exit 1
        ;;
esac

echo ""
echo "The following resource groups will be PERMANENTLY DELETED:"
for rg in "${RESOURCE_GROUPS[@]}"; do
    echo "  - $rg"
    # Check if resource group exists and list resources
    if az group exists --name "$rg" --query "true" -o tsv | grep -q "true"; then
        echo "    Resources in $rg:"
        az resource list --resource-group "$rg" --query "[].{Name:name, Type:type}" -o table | sed 's/^/      /'
    else
        echo "    (Resource group does not exist)"
    fi
done

echo ""
echo "⚠️  THIS ACTION CANNOT BE UNDONE ⚠️"
echo ""
read -p "Type 'DELETE' to confirm deletion: " confirmation

if [[ "$confirmation" != "DELETE" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete resource groups
for rg in "${RESOURCE_GROUPS[@]}"; do
    if az group exists --name "$rg" --query "true" -o tsv | grep -q "true"; then
        echo ""
        echo "Deleting resource group: $rg"
        az group delete \
            --name "$rg" \
            --yes \
            --no-wait
        echo "Deletion initiated for $rg (running in background)"
    else
        echo "Resource group $rg does not exist, skipping..."
    fi
done

echo ""
echo "========================================"
echo "Cleanup Initiated"
echo "========================================"
echo "Resource group deletions are running in the background."
echo "This may take several minutes to complete."
echo ""
echo "To check deletion status:"
for rg in "${RESOURCE_GROUPS[@]}"; do
    echo "  az group show --name $rg"
done
echo ""
echo "To list all running deletions:"
echo "  az group list --query \"[?properties.provisioningState=='Deleting'].name\" -o table"
