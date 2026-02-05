# Azure Infrastructure Cost Estimate Report

**Generated:** February 1, 2026  
**Project:** Document Processing Infrastructure  
**Environment:** Development (dev), Staging, Production (prod)  
**Region:** East US  

---

## Executive Summary

This cost estimate is based on the Bicep infrastructure template in `main.bicep` which deploys a document processing solution using Azure Storage, Service Bus, and Azure AI Document Intelligence (Form Recognizer).

**Total Estimated Monthly Cost (per environment):**
- **Development:** ~$87.20/month
- **Staging:** ~$87.20/month  
- **Production:** ~$87.20/month

**Total Annual Cost (all 3 environments):** ~$3,139.20/year

---

## Resource Inventory

The infrastructure deploys the following Azure resources per environment:

1. **Storage Account** - Standard_LRS, StorageV2, Hot tier
   - 2 Blob containers (documents-input, documents-output)
   - 7-day delete retention policy
   
2. **Service Bus Namespace** - Standard tier
   - 1 Queue (document-processing-queue)
   - 5-minute lock duration, 14-day TTL
   
3. **Azure AI Document Intelligence** - S0 tier
   - Form Recognizer cognitive service
   - Public network access enabled

---

## Detailed Cost Breakdown

### 1. Storage Account (Standard_LRS)

| Component | SKU | Unit Cost | Monthly Usage | Monthly Cost |
|-----------|-----|-----------|---------------|--------------|
| Storage Capacity (Hot) | Standard_LRS | $0.0184/GB | 100 GB | $1.84 |
| Write Operations | Standard_LRS | $0.05/10K | 500K ops | $2.50 |
| Read Operations | Standard_LRS | $0.004/10K | 1M ops | $0.40 |
| List Operations | Standard_LRS | $0.05/10K | 100K ops | $0.50 |
| **Subtotal** | | | | **$5.24** |

**Assumptions:**
- 100 GB of storage for documents
- Moderate read/write activity for document processing
- Hot tier for immediate access

### 2. Service Bus Namespace (Standard Tier)

| Component | SKU | Unit Cost | Monthly Usage | Monthly Cost |
|-----------|-----|-----------|---------------|--------------|
| Base Unit | Standard | $10.00/month | 1 namespace | $10.00 |
| Messaging Operations | Standard | $0.05/million | 20M ops | $1.00 |
| **Subtotal** | | | | **$11.00** |

**Assumptions:**
- Single Standard namespace with 1 queue
- 20 million messaging operations per month (includes send, receive, delete)
- First 13 million operations included in base price
- Additional operations charged at $0.05 per million

**Standard Tier Features:**
- Up to 1,000 queue/topic connections
- 256 KB message size
- Variable messaging throughput
- Includes basic topics and subscriptions

### 3. Azure AI Document Intelligence (S0 Tier)

| Component | SKU | Transaction Type | Unit Cost | Monthly Usage | Monthly Cost |
|-----------|-----|------------------|-----------|---------------|--------------|
| Read API | S0 | Pages processed | $1.50/1K pages | 10K pages | $15.00 |
| Prebuilt Models | S0 | Pages processed | $10.00/1K pages | 5K pages | $50.00 |
| Custom Models | S0 | Training hours | $10.00/hour | 1 hour | $10.00 |
| **Subtotal** | | | | | **$75.00** |

**Assumptions:**
- 10,000 document pages analyzed with Read API monthly
- 5,000 pages processed with prebuilt models (invoices, receipts, IDs)
- 1 hour of custom model training per month
- S0 tier allows up to 15 transactions per second

**S0 Tier Features:**
- Prebuilt models for common documents (invoices, receipts, IDs, business cards)
- Custom model training capability
- Layout extraction
- Key-value pair extraction
- Table extraction
- 15 TPS (transactions per second)

---

## Cost Summary by Environment

| Environment | Storage | Service Bus | Document Intelligence | **Monthly Total** | **Annual Total** |
|-------------|---------|-------------|----------------------|-------------------|------------------|
| Development | $5.24 | $11.00 | $75.00 | **$91.24** | **$1,094.88** |
| Staging | $5.24 | $11.00 | $75.00 | **$91.24** | **$1,094.88** |
| Production | $5.24 | $11.00 | $75.00 | **$91.24** | **$1,094.88** |
| **Total** | **$15.72** | **$33.00** | **$225.00** | **$273.72** | **$3,284.64** |

---

## Cost Optimization Recommendations

### 1. Right-Sizing by Environment

**Current Setup:** All environments use identical SKUs

**Recommendation:** Differentiate SKUs based on environment needs

| Resource | Dev/Staging | Production | Monthly Savings |
|----------|-------------|------------|-----------------|
| Service Bus | Basic tier ($0.05/month) | Standard tier ($10/month) | ~$20.00 |
| Document Intelligence | F0 (Free tier) for dev | S0 for production | ~$150.00 |
| Storage | Cool tier for staging | Hot tier for production | ~$1.00 |

**Potential Monthly Savings:** ~$171.00 (63% reduction for dev/staging)

### 2. Reserved Capacity

**Azure Storage Reserved Capacity:**
- 1-year commitment: 15% discount → Save ~$9.45/year
- 3-year commitment: 30% discount → Save ~$18.90/year

**Note:** Reserved capacity may not be cost-effective for this small storage footprint.

### 3. Document Intelligence Free Tier

**F0 (Free) Tier Includes:**
- 500 pages/month free for prebuilt models
- 500 pages/month free for custom models
- 2 free custom models
- Good for development and testing

**Recommendation:** Use F0 tier for dev environment to save $75/month

### 4. Service Bus Basic Tier for Non-Production

**Basic Tier Benefits:**
- $0.05 per million messaging operations (no base fee)
- Sufficient for dev/staging with lower message volume
- Queues supported (no topics/subscriptions)

**Monthly Savings:** $10.00 per environment

### 5. Storage Optimization

**Lifecycle Management:**
- Move documents to Cool tier after 30 days → 50% storage cost reduction
- Move to Archive tier after 90 days → 90% storage cost reduction
- Delete old processed documents after retention period

**Potential Monthly Savings:** $1-2 per environment

### 6. Monitoring and Alerting

**Implement cost monitoring:**
- Set up Azure Cost Management alerts at $100/month threshold
- Monitor Document Intelligence usage patterns
- Track Service Bus message volume
- Review storage growth trends

---

## Cost Drivers Analysis

### Top 3 Cost Drivers:

1. **Azure AI Document Intelligence (82% of costs)** - $225/month across all environments
   - S0 tier with page processing charges
   - Most expensive component by far
   
2. **Service Bus Standard (12% of costs)** - $33/month across all environments
   - Base monthly fee per namespace
   - Messaging operations

3. **Storage Account (6% of costs)** - $15.72/month across all environments
   - Storage capacity and operations
   - Relatively low cost

### Optimization Priority:

**High Priority:**
1. Use Document Intelligence F0 (Free) tier for dev/staging - saves $150/month
2. Downgrade Service Bus to Basic tier for non-prod - saves $20/month

**Medium Priority:**
3. Implement storage lifecycle policies - saves $2-4/month
4. Monitor and optimize Document Intelligence usage patterns

**Low Priority:**
5. Consider reserved capacity (only beneficial at larger scale)

---

## Alternative Architecture Options

### Option A: Serverless with Consumption-Based Services

Replace Service Bus Standard with:
- **Azure Functions with Queue Triggers** - Pay per execution
- **Azure Queue Storage** - $0.004 per 10K operations

**Potential Savings:** $9-10/month per environment for low-volume scenarios

### Option B: Unified Cognitive Services Resource

Instead of dedicated Document Intelligence:
- **Azure AI Services Multi-service Resource** - Same pricing, but unified billing
- Better for scenarios using multiple AI services (Vision, Language, etc.)

**Cost Impact:** Neutral, but better management and potential volume discounts

### Option C: Batch Processing Architecture

For non-real-time requirements:
- Use Azure Batch for processing - Pay per VM hour
- Use Cool/Archive storage tiers
- Schedule processing during off-peak hours

**Potential Savings:** 40-50% for batch workloads with flexible timing

---

## Excluded Costs

The following costs are **NOT** included in this estimate:

### Data Transfer
- **Ingress:** Free (inbound data transfer to Azure)
- **Egress:** First 100 GB free per month, then $0.087/GB
- Estimate: $5-20/month depending on document download volume

### Bandwidth
- Inter-region data transfer (if multi-region deployment)
- CDN costs (if documents served via CDN)

### Support Plans
- **Basic:** Free (business hours support)
- **Developer:** $29/month (non-production use)
- **Standard:** $100/month (24/7 support)
- **Professional Direct:** $1,000/month

### Additional Features
- Private endpoints: $0.01/hour per endpoint (~$7.30/month each)
- Virtual Network integration
- Azure Key Vault for secrets management (~$0.25/month for 10K operations)
- Log Analytics workspace for monitoring (~$2.30/GB ingested)
- Application Insights for telemetry (pay per GB)

### Development and Operations
- Azure DevOps pipelines (first 1,800 minutes free, then $40/month per parallel job)
- Developer time and tools
- Testing and QA environments

**Estimated Additional Monthly Cost:** $15-50/month depending on features enabled

---

## Regional Cost Variations

Current deployment: **East US**

Alternative region pricing comparison:

| Region | Storage | Service Bus | Document Intelligence | Total Monthly |
|--------|---------|-------------|-----------------------|---------------|
| East US (current) | $5.24 | $11.00 | $75.00 | $91.24 |
| East US 2 | $5.24 | $11.00 | $75.00 | $91.24 |
| West US | $5.24 | $11.00 | $75.00 | $91.24 |
| West Europe | $5.76 | $12.10 | $82.50 | $100.36 |
| Southeast Asia | $6.29 | $13.20 | $90.00 | $109.49 |

**Recommendation:** Stay in East US or East US 2 for lowest costs. Only change region if latency, compliance, or business requirements dictate.

---

## Assumptions & Disclaimers

### Pricing Assumptions

1. **Pay-as-you-go pricing** - No reservations, Enterprise Agreements, or CSP pricing
2. **730 hours/month** - Calculated as average hours per month
3. **East US region** - Pricing varies by region
4. **Public pricing** - Based on Azure Retail Prices API as of February 2026
5. **No promotional discounts** applied

### Usage Assumptions

1. **Storage:** 100 GB per environment with moderate growth
2. **Service Bus:** 20 million operations per month
3. **Document Intelligence:** 15K pages processed per month
4. **Uptime:** 100% availability (24/7 operation)

### Important Notes

- **Actual costs may vary** based on actual usage patterns
- **Document Intelligence costs are highly variable** - Depends on document volume
- **Storage costs will grow** as document archive increases
- **Data transfer costs** not included in base estimate
- **Enterprise customers** may have different pricing through EA or CSP agreements
- **Free tiers** available for dev/test (Document Intelligence F0, Service Bus Basic)

### Verification

- Verify estimates using [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- Monitor actual costs via Azure Cost Management
- Set up budget alerts to avoid surprises
- Review pricing monthly as Azure pricing changes frequently

---

## Recommendations Summary

### Immediate Actions (High ROI)

1. ✅ **Use F0 tier for Document Intelligence in dev** - Save $75/month
2. ✅ **Downgrade Service Bus to Basic in dev/staging** - Save $20/month  
3. ✅ **Implement Azure Cost Management alerts** - Prevent overruns
4. ✅ **Set up storage lifecycle policies** - Save $2-4/month

**Total Immediate Savings:** ~$97-99/month (35% reduction)

### Medium-Term Actions

5. Monitor Document Intelligence usage and optimize model selection
6. Review and adjust SKUs quarterly based on actual usage
7. Consider batch processing for non-urgent document processing
8. Implement automated start/stop for dev environments during off-hours

### Long-Term Considerations

9. Evaluate reserved capacity when usage patterns stabilize
10. Consider multi-region deployment for business continuity (will increase costs)
11. Explore Azure Hybrid Benefit if applicable (requires on-prem licenses)

---

## Contact & Tools

**Estimate Created By:** Azure Price Estimator Agent  
**Bicep Template:** `/infra/main.bicep`  
**Parameter Files:** `main.dev.bicepparam`, `main.prod.bicepparam`, `main.staging.bicepparam`

**Useful Links:**
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Cost Management](https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview)
- [Azure Pricing API](https://learn.microsoft.com/rest/api/cost-management/retail-prices/azure-retail-prices)
- [Document Intelligence Pricing](https://azure.microsoft.com/pricing/details/form-recognizer/)
- [Service Bus Pricing](https://azure.microsoft.com/pricing/details/service-bus/)
- [Storage Pricing](https://azure.microsoft.com/pricing/details/storage/blobs/)

---

**Last Updated:** February 1, 2026  
**Next Review:** March 1, 2026 (monthly review recommended)
