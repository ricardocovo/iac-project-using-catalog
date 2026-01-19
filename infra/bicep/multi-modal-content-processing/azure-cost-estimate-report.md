# Azure Cost Estimation Report
## Multi-Modal Content Processing Architecture

**Generated:** January 16, 2026  
**Template:** main.bicep  
**Region:** East US (default)  
**Environment:** Production estimate with moderate usage

---

## Executive Summary

This architecture deploys a complete multi-modal content processing solution with AI capabilities, container-based compute, and managed data services. The estimated monthly cost ranges from **$700 to $2,500** depending on usage patterns, with annual costs between **$8,400 and $30,000**.

**Key Cost Drivers:**
1. Azure OpenAI Services (40-60% of total cost)
2. Cosmos DB with Autoscale (15-25% of total cost)
3. Container Apps compute (10-20% of total cost)
4. AI Search Service (5-10% of total cost)

---

## Resource Inventory

The template deploys the following Azure resources:

### Monitoring & Observability
- 1x Log Analytics Workspace
- 1x Application Insights

### Security & Identity
- 1x Key Vault
- 2x Managed Identities (User-Assigned)

### Storage
- 1x Storage Account (General Purpose v2)
  - 3x Blob Containers (uploads, processed, temp)
  - Queue Services

### Data Services
- 1x Cosmos DB Account (NoSQL API)
  - 1x Database
  - 1x Container with Hierarchical Partition Keys
  - Autoscale: 1,000-4,000 RU/s

### AI Services
- 1x Azure OpenAI Service (S0)
  - GPT-4 deployment (10 capacity)
  - GPT-4 Vision deployment (10 capacity)
  - Text-Embedding-Ada-002 (20 capacity)
- 1x Computer Vision (S1)
- 1x Azure AI Search (Basic SKU)

### Container Services
- 1x Container Registry (Basic SKU)
- 1x Container Apps Environment
- 2x Container Apps
  - Processor App: 0-10 replicas, 0.5 vCPU, 1 GB RAM
  - API App: 1-10 replicas, 0.5 vCPU, 1 GB RAM

---

## Detailed Cost Breakdown

### 1. Monitoring Services

| Resource | SKU/Configuration | Monthly Cost | Annual Cost |
|----------|------------------|--------------|-------------|
| Log Analytics Workspace | Pay-as-you-go, 30-day retention | $25-$100 | $300-$1,200 |
| Application Insights | Included with Log Analytics | Included | Included |

**Assumptions:**
- 10-50 GB data ingestion per month
- 30-day data retention
- Cost: ~$2.50/GB for ingestion

---

### 2. Security Services

| Resource | SKU/Configuration | Monthly Cost | Annual Cost |
|----------|------------------|--------------|-------------|
| Key Vault | Standard tier | $0-$5 | $0-$60 |
| Managed Identities | Free | $0 | $0 |

**Assumptions:**
- <10,000 operations/month
- No HSM-protected keys

---

### 3. Storage Services

| Resource | SKU/Configuration | Monthly Cost | Annual Cost |
|----------|------------------|--------------|-------------|
| Storage Account | General Purpose v2, LRS | $20-$50 | $240-$600 |
| - Blob Storage | Hot tier | $15-$40 | $180-$480 |
| - Queue Storage | Standard | $5-$10 | $60-$120 |

**Assumptions:**
- 100-500 GB blob storage
- 10-50 million transactions/month
- Minimal data egress

---

### 4. Data Services - Cosmos DB

| Resource | SKU/Configuration | Monthly Cost | Annual Cost |
|----------|------------------|--------------|-------------|
| Cosmos DB (NoSQL) | Autoscale 1K-4K RU/s | $60-$290 | $720-$3,480 |

**Pricing Details:**
- Minimum (1,000 RU/s autoscale): ~$58/month
- Average (2,000 RU/s): ~$145/month
- Maximum (4,000 RU/s): ~$290/month
- Autoscale pricing: $0.012/hour per 100 RU/s
- Storage: First 25 GB free, $0.25/GB thereafter

**Assumptions:**
- Autoscale operates at 50% of max capacity on average
- <100 GB storage
- Single-region write, multi-region read optional

---

### 5. AI Services

| Resource | SKU/Configuration | Monthly Cost | Annual Cost |
|----------|------------------|--------------|-------------|
| Azure OpenAI (S0) | Standard tier | $300-$1,500 | $3,600-$18,000 |
| - GPT-4 (10 capacity) | Input/Output tokens | $200-$1,000 | $2,400-$12,000 |
| - GPT-4 Vision (10 capacity) | Input/Output tokens | $75-$350 | $900-$4,200 |
| - Text-Embedding-Ada-002 (20 capacity) | Token-based | $25-$150 | $300-$1,800 |
| Computer Vision (S1) | Standard tier | $60 | $720 |
| AI Search (Basic) | 1 replica, 1 partition | $75 | $900 |

**Azure OpenAI Pricing (as of Jan 2026):**
- GPT-4 (0613): $0.03/1K input tokens, $0.06/1K output tokens
- GPT-4 Vision: $0.01/1K input tokens, $0.03/1K output tokens
- Text-Embedding-Ada-002: $0.0001/1K tokens

**Assumptions:**
- Moderate AI usage: 5-25M tokens/month
- Computer Vision: 10,000 transactions/month
- AI Search: Basic tier with 2 GB storage limit

---

### 6. Container Services

| Resource | SKU/Configuration | Monthly Cost | Annual Cost |
|----------|------------------|--------------|-------------|
| Container Registry | Basic SKU | $5 | $60 |
| Container Apps Environment | Managed infrastructure | $0 | $0 |
| Container Apps - Processor | 0-10 replicas, 0.5 vCPU, 1 GB | $5-$100 | $60-$1,200 |
| Container Apps - API | 1-10 replicas, 0.5 vCPU, 1 GB | $35-$175 | $420-$2,100 |

**Container Apps Pricing:**
- Active vCPU-seconds: $0.000012/second (~$31.10/month for 1 vCPU always-on)
- Active memory (GB-seconds): $0.000002/second (~$5.18/month for 1 GB always-on)
- Idle resources: $0 when scaled to zero (processor app)
- Requests: First 2M free, then $0.40/million

**Assumptions:**
- Processor App: Scales to zero when idle, average 2 replicas during load
- API App: Minimum 1 replica always running, average 3 replicas
- 50% idle time for API app
- <5M requests/month

---

### 7. Additional Costs

| Item | Monthly Cost | Annual Cost |
|------|-------------|-------------|
| Data Transfer (Egress) | $10-$50 | $120-$600 |
| RBAC Operations | $0 | $0 |
| Managed Identity Operations | $0 | $0 |

---

## Total Estimated Monthly Costs

### Conservative Estimate (Low Usage)

| Category | Monthly Cost |
|----------|-------------|
| Monitoring | $25 |
| Security | $2 |
| Storage | $20 |
| Cosmos DB | $60 |
| AI Services | $435 |
| Container Services | $45 |
| Data Transfer | $10 |
| **TOTAL** | **~$597** |

### Moderate Estimate (Average Usage)

| Category | Monthly Cost |
|----------|-------------|
| Monitoring | $60 |
| Security | $3 |
| Storage | $35 |
| Cosmos DB | $145 |
| AI Services | $800 |
| Container Services | $120 |
| Data Transfer | $30 |
| **TOTAL** | **~$1,193** |

### High Estimate (Heavy Usage)

| Category | Monthly Cost |
|----------|-------------|
| Monitoring | $100 |
| Security | $5 |
| Storage | $50 |
| Cosmos DB | $290 |
| AI Services | $1,885 |
| Container Services | $280 |
| Data Transfer | $50 |
| **TOTAL** | **~$2,660** |

---

## Annual Cost Summary

| Usage Level | Annual Cost |
|-------------|-------------|
| Conservative | **$7,164** |
| Moderate | **$14,316** |
| High | **$31,920** |

---

## Cost Optimization Recommendations

### 1. Azure OpenAI Optimization (Potential Savings: 30-50%)

**Current:** Pay-as-you-go with capacity reservations
- GPT-4: 10 capacity units
- GPT-4 Vision: 10 capacity units  
- Text-Embedding: 20 capacity units

**Recommendations:**
- ✅ **Monitor token usage closely** - Use Application Insights to track actual consumption
- ✅ **Implement caching** - Cache embeddings and common responses (potential 20-40% reduction)
- ✅ **Right-size capacity** - Start with lower capacity and scale up based on demand
- ✅ **Consider Provisioned Throughput** - If usage is predictable and high (>500M tokens/month), provisioned throughput can save 40-50%
- ✅ **Use GPT-3.5-Turbo** where appropriate - 10x cheaper than GPT-4 for simpler tasks
- ✅ **Optimize prompts** - Reduce token count with efficient prompt engineering

**Estimated Savings:** $150-$750/month

---

### 2. Cosmos DB Optimization (Potential Savings: 30-40%)

**Current:** Autoscale 1,000-4,000 RU/s

**Recommendations:**
- ✅ **Start with 1,000 RU/s** manual throughput ($60/month) instead of autoscale
- ✅ **Use serverless tier** for development/testing (pay per operation, no minimum)
- ✅ **Implement caching** - Use Redis/in-memory cache for frequently accessed data
- ✅ **Optimize queries** - Add proper indexes, avoid cross-partition queries
- ✅ **Batch operations** - Use bulk APIs for high-volume writes
- ✅ **Consider Reserved Capacity** - 1-year commitment saves 20%, 3-year saves 30%

**Estimated Savings:** $50-$120/month

---

### 3. Container Apps Optimization (Potential Savings: 40-60%)

**Current:** 2 apps with 0-10 replicas each

**Recommendations:**
- ✅ **Enable scale-to-zero** for processor app (already configured) - Saves during idle periods
- ✅ **Set aggressive scale-down rules** - Scale down to minimum replicas quickly
- ✅ **Right-size resources** - Monitor CPU/memory usage and adjust:
  - Consider 0.25 vCPU if current usage is low
  - Reduce memory to 0.5 GB if possible
- ✅ **Use consumption plan** (current setup) vs dedicated plan
- ✅ **Optimize container images** - Smaller images = faster cold starts

**Estimated Savings:** $50-$150/month

---

### 4. AI Search Optimization (Potential Savings: 0% - already optimal)

**Current:** Basic tier ($75/month)

**Recommendations:**
- ✅ **Basic tier is appropriate** for development and small-scale production
- ⚠️ **Monitor storage usage** - Basic tier limited to 2 GB
- ⚠️ **Consider Free tier** for development environments (15 MB limit)
- ✅ **Scale up only when needed** - Standard tier is $250/month

**Estimated Savings:** $0 (already optimal for production workload)

---

### 5. Storage Optimization (Potential Savings: 30-50%)

**Current:** Hot tier blob storage

**Recommendations:**
- ✅ **Use lifecycle management** - Move processed files to Cool tier after 30 days
- ✅ **Archive old data** - Move to Archive tier after 90 days (98% cheaper)
- ✅ **Enable blob soft delete** - 7-day retention instead of 14 days
- ✅ **Use LRS** (already configured) instead of GRS for non-critical data
- ✅ **Clean up temporary data** - Delete temp container files automatically

**Storage Tier Pricing (per GB/month):**
- Hot: $0.018
- Cool: $0.01  
- Archive: $0.002

**Estimated Savings:** $10-$25/month

---

### 6. Development Environment Strategy (Potential Savings: 70-80%)

**Recommendations:**
- ✅ **Use separate dev environment** with:
  - Cosmos DB Serverless (no minimum cost)
  - AI Search Free tier
  - Container Apps scaled to zero when not in use
  - Storage Cool tier
  - Lower OpenAI capacity (2-5 units)
- ✅ **Automate environment shutdown** - Use Azure Automation to stop/start resources
- ✅ **Share resources** across dev/test environments where possible

**Estimated Dev Environment Cost:** $150-$300/month (vs $700-$2,500 for production)

---

### 7. Reserved Capacity & Commitments

**Long-term Savings (1-3 year commitment):**

| Service | Reservation Period | Savings |
|---------|-------------------|---------|
| Cosmos DB | 1 year | 20% |
| Cosmos DB | 3 years | 30% |
| Container Apps | 1 year | 15% |

**Estimated Savings with 1-year reservations:** $150-$300/month  
**Estimated Savings with 3-year reservations:** $250-$500/month

---

## Implementation Priority

### High Priority (Immediate Impact)
1. ✅ **Enable Cosmos DB caching** and optimize queries
2. ✅ **Monitor and right-size OpenAI capacity** based on actual usage
3. ✅ **Implement storage lifecycle policies** for blob data
4. ✅ **Configure aggressive scale-down rules** for Container Apps

### Medium Priority (1-3 months)
5. ✅ **Implement prompt optimization** and response caching for AI services
6. ✅ **Set up cost alerts** in Azure Cost Management
7. ✅ **Review and optimize container resource allocations**
8. ✅ **Create separate dev/test environments** with lower-cost configurations

### Low Priority (Long-term)
9. ✅ **Evaluate Reserved Capacity** after 3-6 months of production usage
10. ✅ **Consider multi-region deployment** only if required for SLA
11. ✅ **Implement advanced caching strategy** with Redis/CDN

---

## Assumptions & Disclaimers

### Pricing Assumptions
- All prices based on **East US** region (January 2026)
- **Pay-as-you-go** pricing model
- No existing Azure commitments or Enterprise Agreements
- Does NOT include:
  - Azure support plans ($29-$1,000+/month)
  - Third-party marketplace solutions  
  - Custom domain SSL certificates
  - Advanced security features (Azure Firewall, DDoS Protection)

### Usage Assumptions
- **OpenAI:** 5-25 million tokens/month
- **Cosmos DB:** Autoscale operating at 50% of maximum capacity
- **Container Apps:** 50% average utilization
- **Computer Vision:** 10,000 transactions/month
- **Storage:** 100-500 GB data, 10-50M transactions/month
- **Data Transfer:** Minimal egress (<100 GB/month)

### Important Notes
- ⚠️ **Prices vary by region** - Some regions are 10-30% more expensive
- ⚠️ **EA/CSP pricing differs** - Enterprise Agreements may have negotiated discounts
- ⚠️ **Usage can spike** - Monitor costs closely during initial deployment
- ⚠️ **AI costs are highly variable** - Token usage depends entirely on application behavior
- ✅ **Always verify current pricing** using the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)

---

## Monitoring & Cost Management

### Recommended Tools
1. **Azure Cost Management + Billing** - Set budgets and alerts
2. **Application Insights** - Monitor service usage and optimize
3. **Azure Monitor Workbooks** - Create cost dashboards
4. **Azure Advisor** - Get personalized cost recommendations

### Suggested Alerts
- Monthly budget alert at 50%, 75%, 90% thresholds
- Daily spending anomaly detection
- Per-service cost alerts (especially OpenAI)
- Resource utilization alerts (identify over-provisioned resources)

---

## Next Steps

1. ✅ **Deploy to development environment first** with cost-optimized settings
2. ✅ **Monitor usage for 2-4 weeks** to establish baseline
3. ✅ **Adjust resource allocations** based on actual usage patterns
4. ✅ **Implement cost optimization recommendations** from high-priority list
5. ✅ **Set up cost alerts and budgets** before production deployment
6. ✅ **Review monthly costs** and adjust strategy as needed

---

## Additional Resources

- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Cost Management Documentation](https://learn.microsoft.com/azure/cost-management-billing/)
- [Azure OpenAI Pricing](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/)
- [Cosmos DB Pricing](https://azure.microsoft.com/pricing/details/cosmos-db/)
- [Container Apps Pricing](https://azure.microsoft.com/pricing/details/container-apps/)
- [Azure Architecture Center - Cost Optimization](https://learn.microsoft.com/azure/architecture/framework/cost/)

---

**Report Generated By:** Azure Price Estimator  
**Last Updated:** January 16, 2026  
**Version:** 1.0
