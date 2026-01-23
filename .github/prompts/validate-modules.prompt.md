---
description: Validates that all Bicep modules comply with organizational standards by verifying they exist in the approved registry
agent: bicep-implement
---

# Validate Bicep Module Registry Compliance

You are tasked with validating that all Bicep modules used in this repository comply with organizational standards.

## Validation Requirements

All Bicep module references must:
1. Use the approved organizational registry: `iacmodulecatalog.azurecr.io`
2. Follow the format: `br:iacmodulecatalog.azurecr.io/<module-path>:<version>`
3. Not use local path references for shared modules (local paths like `./modules` or `../modules` are not allowed for reusable components)
4. Versions referenced should exist in the approved registry.

## Steps to Perform

1. **Scan all Bicep files** (`.bicep`) in the repository
2. **Identify module references** by looking for:
   - `module <name> 'br:...'` statements
   - `module <name> '../...'` or `module <name> './...'` statements
3. **Check compliance**:
   - ✅ Valid: `module storage 'br:iacmodulecatalog.azurecr.io/storage/storageaccount:1.0.0'`
   - ❌ Invalid: `module storage '../modules/storage.bicep'`
   - ❌ Invalid: `module storage 'br:publicregistry.azurecr.io/storage:1.0'`
4. **Report findings**:
   - List all non-compliant module references
   - Specify the file path and line number
   - Explain why each reference is non-compliant
   - Suggest the correct format

## Expected Output Format

### Summary
- Total Bicep files scanned: X
- Compliant modules: Y
- Non-compliant modules: Z

### Non-Compliant Modules (if any)

**File:** `path/to/file.bicep` (Line: XX)