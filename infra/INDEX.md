# Document Processing System - Infrastructure Documentation Index

## 📚 Documentation Overview

This directory contains a complete Azure Bicep infrastructure-as-code solution for an intelligent document processing system.

## 📖 Document Guide

### Getting Started (Read First)
1. **[DEPLOYMENT-SUMMARY.md](./DEPLOYMENT-SUMMARY.md)** - Quick overview of what's deployed
   - Infrastructure components
   - Resource counts and configurations
   - Quick start guide
   - Key outputs and next steps

2. **[README.md](./README.md)** - Complete deployment guide
   - Detailed prerequisites
   - Step-by-step deployment instructions
   - Environment-specific configurations
   - Cost estimates and monitoring setup
   - Troubleshooting and cleanup procedures

### Implementation Details
3. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Comprehensive architecture documentation
   - System overview and data flow diagrams
   - Component details and integration points
   - Data schemas (Cosmos DB, AI Search)
   - Processing pipeline walkthrough
   - Security architecture
   - Scalability and DR considerations

4. **[VALIDATION.md](./VALIDATION.md)** - Validation and testing procedures
   - Pre-deployment validation steps
   - Bicep linting and formatting
   - Azure validation commands
   - Expected resources checklist
   - Common issues and solutions
   - CI/CD automation examples

## 🗂️ File Reference

### Infrastructure Templates
- **`main.bicep`** - Main Bicep template (all resources)
- **`main.bicepparam`** - Development environment parameters
- **`main.prod.bicepparam`** - Production environment parameters

### Deployment Scripts
- **`deploy-dev.sh`** - Automated dev deployment with validation
- **`deploy-prod.sh`** - Automated prod deployment with safeguards
- **`cleanup.sh`** - Safe resource cleanup script

### Configuration
- **`.gitignore`** - Git ignore patterns for build artifacts

## 🚀 Quick Reference

### Deploy to Development
```bash
cd infra/
./deploy-dev.sh
```

### Deploy to Production
```bash
cd infra/
./deploy-prod.sh
```

### Validate Template
```bash
cd infra/
bicep build main.bicep --stdout
bicep lint main.bicep
```

### Clean Up Resources
```bash
cd infra/
./cleanup.sh
```

## 🎯 What's Deployed

### Core Services (26 resources total)
- ✅ **Log Analytics Workspace** - Centralized logging
- ✅ **Application Insights** - Application monitoring
- ✅ **Key Vault** - Secret management
- ✅ **Storage Account** - Document storage (3 containers)
- ✅ **Cosmos DB** - NoSQL database (4 containers)
- ✅ **AI Document Intelligence** - Document analysis
- ✅ **AI Services** - Embeddings and chat
- ✅ **AI Search** - Vector and semantic search
- ✅ **Service Bus** - Message queuing (5 queues)
- ✅ **Function App** - Event processing (.NET 8)
- ✅ **Web App** - User interface (.NET 8)
- ✅ **11 Role Assignments** - Managed identity permissions

### Key Features
- ✅ Managed identities for secure access
- ✅ RBAC-based permissions (least privilege)
- ✅ Comprehensive diagnostic logging
- ✅ Environment-specific configurations
- ✅ Cost-optimized SKUs per environment
- ✅ Resource tagging for governance
- ✅ Soft delete and backup enabled
- ✅ HTTPS and TLS 1.2+ enforced

## 📊 Architecture Patterns

### Document Processing Pipeline
```
Upload → Blob → Function → Service Bus →
Classification → Intelligence → Embedding →
Indexing → AI Search → Chat Interface
```

### RAG (Retrieval Augmented Generation)
```
User Query → Vectorize → Search (Hybrid) →
Retrieve Context → LLM → Response
```

### Orchestration
- Durable Functions for workflow coordination
- Service Bus queues for reliable messaging
- Cosmos DB for state management

## 🔐 Security Highlights

- No connection strings in code
- Managed identities throughout
- Key Vault for secrets
- No secrets in outputs
- Encryption at rest and in transit
- Soft delete for data protection
- RBAC for fine-grained access

## 💰 Cost Estimates

| Environment | Monthly Cost | Use Case |
|-------------|--------------|----------|
| Development | ~$140-200 | Dev/Test |
| Production | ~$720-1,300 | Production workloads |

*Varies based on usage, data volume, and API calls*

## 📋 Prerequisites

- Azure CLI with Bicep (v0.24.0+)
- Azure subscription with Contributor access
- Registered resource providers
- Internet access for module downloads

## 🔗 External References

- [Azure Bicep Docs](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Verified Modules](https://aka.ms/avm)
- [AI Document Intelligence](https://learn.microsoft.com/azure/ai-services/document-intelligence/)
- [Azure AI Search](https://learn.microsoft.com/azure/search/)
- [Durable Functions](https://learn.microsoft.com/azure/azure-functions/durable/)

## 🎓 Learning Path

### New to Azure Bicep?
1. Start with [README.md](./README.md) - Prerequisites and deployment
2. Review [DEPLOYMENT-SUMMARY.md](./DEPLOYMENT-SUMMARY.md) - What gets deployed
3. Deploy to dev environment using `deploy-dev.sh`

### Need to Customize?
1. Review [ARCHITECTURE.md](./ARCHITECTURE.md) - Understand the system
2. Modify parameters in `main.bicepparam`
3. Validate using steps in [VALIDATION.md](./VALIDATION.md)
4. Deploy and test changes

### Preparing for Production?
1. Review [ARCHITECTURE.md](./ARCHITECTURE.md) - Scalability and security
2. Customize `main.prod.bicepparam` for your needs
3. Follow [VALIDATION.md](./VALIDATION.md) - Complete checklist
4. Use `deploy-prod.sh` with safeguards enabled

## 🤝 Contributing

When modifying these templates:
1. Follow Bicep best practices (see `.github/instructions/`)
2. Use lowerCamelCase naming
3. Add @description to parameters
4. Test in dev before prod
5. Update documentation
6. Run `bicep lint` before committing

## 📞 Support

For questions or issues:
1. Check the relevant documentation file above
2. Review [VALIDATION.md](./VALIDATION.md) for common issues
3. Consult Azure documentation
4. Contact the platform team

---

**Status**: ✅ Production Ready  
**Version**: 1.0  
**Last Updated**: 2024-01-29  
**Maintained By**: Platform Team
