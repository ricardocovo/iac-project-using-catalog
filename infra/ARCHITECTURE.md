# Document Processing System - Architecture Details

## System Overview

This infrastructure supports an intelligent document processing pipeline that:
1. Ingests documents via blob storage uploads
2. Classifies documents using AI
3. Extracts structured data using Azure AI Document Intelligence
4. Generates embeddings and indexes content for semantic search
5. Enables conversational AI interface for document querying

## Component Architecture

### Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                         USER INTERACTION                          │
└─────────────┬────────────────────────────────────┬───────────────┘
              │                                    │
              ▼ (Upload)                          ▼ (Query)
    ┌─────────────────┐                  ┌──────────────────┐
    │  Blob Storage   │                  │    Web App       │
    │  (raw-docs)     │                  │  (.NET 8 / UI)   │
    └────────┬────────┘                  └────────┬─────────┘
             │                                     │
             │ Trigger                             │
             ▼                                     ▼
    ┌─────────────────┐                  ┌──────────────────┐
    │  Function App   │                  │   AI Services    │
    │  (Ingestion)    │                  │ (Chat/LLM API)   │
    └────────┬────────┘                  └────────┬─────────┘
             │                                     │
             ▼                                     ▼
    ┌─────────────────┐                  ┌──────────────────┐
    │  Service Bus    │◄─────────────────│   AI Search      │
    │  (Queues)       │                  │ (Vector Store)   │
    └────────┬────────┘                  └────────┬─────────┘
             │                                     │
             ├───► Classification Queue            │
             ├───► Intelligence Queue              │
             ├───► Embedding Queue                 │
             └───► Indexing Queue                  │
                                                   │
    ┌─────────────────┐                           │
    │  Durable Func   │                           │
    │  (Orchestrator) │◄──────────────────────────┘
    └────────┬────────┘
             │
             ├───► Document Intelligence
             ├───► Cosmos DB (metadata)
             └───► Blob Storage (processed)
```

### Resource Grouping

#### Foundation Layer
**Purpose**: Monitoring, logging, and security

| Resource | Purpose | SKU (Dev/Prod) |
|----------|---------|----------------|
| Log Analytics Workspace | Centralized logging | PerGB2018 |
| Application Insights | APM and telemetry | Standard |
| Key Vault | Secrets management | Standard |

**Dependencies**: None (foundation for other resources)

#### Storage Layer
**Purpose**: Document and metadata persistence

| Resource | Purpose | SKU (Dev/Prod) |
|----------|---------|----------------|
| Storage Account | Document repository | LRS / ZRS |
| Cosmos DB | Document metadata | Autoscale 400-1000 / 400-4000 RU/s |

**Dependencies**: Log Analytics (for diagnostics)

#### AI Services Layer
**Purpose**: Document intelligence and semantic capabilities

| Resource | Purpose | SKU (Dev/Prod) |
|----------|---------|----------------|
| Document Intelligence | Document analysis | F0 / S0 |
| AI Services | Embeddings & chat | F0 / S0 |
| AI Search | Vector search | Basic / Standard |

**Dependencies**: 
- Log Analytics (for diagnostics)
- Storage (for data)
- Cosmos DB (for metadata)

#### Messaging Layer
**Purpose**: Asynchronous workflow coordination

| Resource | Purpose | SKU (Dev/Prod) |
|----------|---------|----------------|
| Service Bus Namespace | Message queuing | Standard / Standard |

**Queues**:
1. `document-ingestion-queue` - New document processing
2. `classification-queue` - Document classification
3. `intelligence-processing-queue` - AI analysis
4. `embedding-queue` - Vector generation
5. `indexing-queue` - Search index updates

**Dependencies**: Log Analytics (for diagnostics)

#### Compute Layer
**Purpose**: Event-driven processing and user interface

| Resource | Purpose | SKU (Dev/Prod) |
|----------|---------|----------------|
| Function App Plan | Serverless hosting | Consumption / Premium EP1 |
| Function App | Event processors | N/A |
| Web App Plan | Web hosting | B1 / S1 |
| Web App | User interface | N/A |

**Dependencies**: 
- All previous layers (full integration)
- Application Insights (monitoring)
- Storage (function state)

### Security Architecture

#### Identity and Access Management

**Managed Identities**:
- Function App: System-assigned
- Web App: System-assigned

**RBAC Role Assignments**:

| Principal | Resource | Role | Purpose |
|-----------|----------|------|---------|
| Function App | Storage Account | Storage Blob Data Contributor | Read/write documents |
| Function App | Cosmos DB | Cosmos DB Data Contributor | Write metadata |
| Function App | Service Bus | Azure Service Bus Data Owner | Queue operations |
| Function App | Document Intelligence | Cognitive Services User | Analyze documents |
| Function App | AI Services | Cognitive Services User | Generate embeddings |
| Function App | AI Search | Search Index Data Contributor | Index management |
| Function App | Key Vault | Key Vault Secrets User | Read secrets |
| Web App | Cosmos DB | Cosmos DB Data Reader | Read metadata |
| Web App | AI Services | Cognitive Services User | Chat queries |
| Web App | AI Search | Search Index Data Reader | Search queries |
| Web App | Key Vault | Key Vault Secrets User | Read secrets |

#### Network Security

**Current Configuration**:
- Public endpoints enabled (suitable for development)
- HTTPS enforced on all web resources
- TLS 1.2 minimum
- FTPS disabled on App Services

**Production Enhancements** (not included in current template):
- Private Endpoints for Storage, Cosmos DB, Key Vault
- VNet Integration for Function Apps and Web App
- Azure Front Door or Application Gateway
- Network Security Groups (NSGs)
- Service Tags for firewall rules

#### Data Protection

**At Rest**:
- All storage encrypted with Microsoft-managed keys
- Soft delete enabled for blobs (7/30 days)
- Soft delete enabled for Key Vault (90 days)

**In Transit**:
- HTTPS/TLS 1.2+ for all connections
- Service Bus encrypted transport

## Processing Pipeline

### 1. Document Ingestion

**Trigger**: Blob created in `raw-documents` container

**Function**: Document Ingestion Function

**Actions**:
1. Validate document (size, type, format)
2. Generate unique document ID
3. Create initial metadata record in Cosmos DB
4. Queue message to `document-ingestion-queue`
5. Log event to Application Insights

**Error Handling**:
- Invalid documents → Move to error container
- Cosmos DB unavailable → Retry with exponential backoff
- Queue full → Throttle and retry

### 2. Document Classification

**Trigger**: Message from `document-ingestion-queue`

**Function**: Classification Function

**Actions**:
1. Retrieve document from blob storage
2. Call AI Services for classification
3. Update document metadata with classification
4. Route to appropriate processing pipeline
5. Queue to `intelligence-processing-queue`

**Classifications**:
- Invoice
- Receipt
- Contract
- Form
- Letter
- Other

### 3. Intelligence Extraction

**Trigger**: Message from `intelligence-processing-queue`

**Function**: Document Intelligence Processing Function

**Actions**:
1. Retrieve document from storage
2. Call Azure AI Document Intelligence
3. Extract:
   - Text content
   - Tables
   - Key-value pairs
   - Form fields
   - Layout structure
4. Store results in Cosmos DB
5. Copy processed document to `processed-documents` container
6. Queue to `embedding-queue`

**Supported Formats**:
- PDF
- Images (JPG, PNG, TIFF, BMP)
- Office documents

### 4. Embedding Generation

**Trigger**: Message from `embedding-queue`

**Function**: Embedding Function

**Actions**:
1. Retrieve extracted text from Cosmos DB
2. Chunk text (overlap strategy for continuity)
3. Generate embeddings using AI Services
4. Store embeddings with document metadata
5. Queue to `indexing-queue`

**Chunking Strategy**:
- Max chunk size: 1000 tokens
- Overlap: 100 tokens
- Preserve sentence boundaries

### 5. Index Management

**Trigger**: Message from `indexing-queue`

**Function**: Indexing Function

**Actions**:
1. Prepare search document with:
   - Document ID
   - Content text
   - Content embeddings (vector field)
   - Metadata (filterable fields)
   - Document type (facet)
2. Upsert to Azure AI Search index
3. Update indexing status in Cosmos DB
4. Complete workflow

### 6. Conversational Interface

**Trigger**: User query via Web App

**Flow**:
1. User submits question
2. Web App sends to AI Services
3. Query vectorized
4. Hybrid search (keyword + vector) in AI Search
5. Retrieve top K relevant chunks
6. Construct RAG prompt with context
7. Generate response using AI Services
8. Store conversation in Cosmos DB (`chat-history`)
9. Return response to user

**RAG Pattern**:
```
Context: [Retrieved document chunks]
Question: [User query]
Instructions: Answer based only on provided context...
```

## Durable Functions Orchestration

### Orchestrator Pattern

**Purpose**: Coordinate multi-step processing with retries and error handling

**Activities**:
1. `DocumentValidationActivity` - Validate document
2. `ClassificationActivity` - Classify document type
3. `IntelligenceExtractionActivity` - Extract structured data
4. `EmbeddingGenerationActivity` - Generate vectors
5. `IndexingActivity` - Update search index
6. `NotificationActivity` - Send completion notification

**Advantages**:
- Automatic retry logic
- Long-running workflows
- Human-in-the-loop scenarios
- Status tracking
- Exactly-once processing

### Error Handling

**Retry Strategies**:
- Transient errors: Exponential backoff (max 5 retries)
- Permanent errors: Move to dead letter queue
- Timeout: 5 minutes per activity

**Monitoring**:
- Orchestration status via Durable Functions API
- Metrics in Application Insights
- Alerts on orchestration failures

## Data Schema

### Cosmos DB Containers

#### 1. document-metadata
**Partition Key**: `/documentType`

```json
{
  "id": "doc-12345",
  "documentType": "invoice",
  "fileName": "invoice-001.pdf",
  "uploadedBy": "user@example.com",
  "uploadedAt": "2024-01-29T12:00:00Z",
  "status": "indexed",
  "classification": {
    "type": "invoice",
    "confidence": 0.95
  },
  "blobPath": "raw-documents/invoice-001.pdf",
  "processedBlobPath": "processed-documents/invoice-001.pdf",
  "contentLength": 125000,
  "chunkCount": 12
}
```

#### 2. processing-results
**Partition Key**: `/documentId`

```json
{
  "id": "result-12345",
  "documentId": "doc-12345",
  "extractedText": "Full extracted text...",
  "tables": [...],
  "keyValuePairs": {...},
  "entities": [...],
  "processedAt": "2024-01-29T12:05:00Z"
}
```

#### 3. chat-history
**Partition Key**: `/sessionId`

```json
{
  "id": "chat-67890",
  "sessionId": "session-123",
  "userId": "user@example.com",
  "timestamp": "2024-01-29T12:10:00Z",
  "query": "What is the total amount on invoice 001?",
  "response": "The total amount is $1,234.56",
  "relevantDocuments": ["doc-12345"],
  "confidence": 0.87
}
```

#### 4. user-sessions
**Partition Key**: `/userId`

```json
{
  "id": "session-123",
  "userId": "user@example.com",
  "createdAt": "2024-01-29T12:00:00Z",
  "lastActivity": "2024-01-29T12:10:00Z",
  "messageCount": 5,
  "documentAccess": ["doc-12345", "doc-12346"]
}
```

### Azure AI Search Index Schema

```json
{
  "name": "documents-index",
  "fields": [
    {
      "name": "documentId",
      "type": "Edm.String",
      "key": true
    },
    {
      "name": "content",
      "type": "Edm.String",
      "searchable": true
    },
    {
      "name": "contentVector",
      "type": "Collection(Edm.Single)",
      "searchable": true,
      "dimensions": 1536,
      "vectorSearchProfile": "my-vector-profile"
    },
    {
      "name": "documentType",
      "type": "Edm.String",
      "filterable": true,
      "facetable": true
    },
    {
      "name": "uploadedAt",
      "type": "Edm.DateTimeOffset",
      "filterable": true,
      "sortable": true
    },
    {
      "name": "chunkNumber",
      "type": "Edm.Int32"
    }
  ],
  "vectorSearch": {
    "profiles": [
      {
        "name": "my-vector-profile",
        "algorithm": "my-hnsw-algorithm"
      }
    ],
    "algorithms": [
      {
        "name": "my-hnsw-algorithm",
        "kind": "hnsw"
      }
    ]
  },
  "semantic": {
    "configurations": [
      {
        "name": "my-semantic-config",
        "prioritizedFields": {
          "titleField": {
            "fieldName": "documentId"
          },
          "prioritizedContentFields": [
            {
              "fieldName": "content"
            }
          ]
        }
      }
    ]
  }
}
```

## Monitoring and Observability

### Key Metrics

**Storage Account**:
- Blob transaction count
- Blob capacity used
- Blob availability

**Cosmos DB**:
- Request units consumed
- Request rate
- Throttled requests
- Storage used

**AI Services**:
- API call count
- Latency (P50, P95, P99)
- Error rate
- Token usage

**AI Search**:
- Query count
- Query latency
- Index size
- Document count

**Service Bus**:
- Queue depth (active messages)
- Dead letter count
- Incoming/outgoing message rate

**Function App**:
- Execution count
- Execution duration
- Failure rate
- Memory usage

**Web App**:
- Request count
- Response time
- HTTP errors (4xx, 5xx)
- CPU/Memory usage

### Alerts

**Critical Alerts**:
1. Function execution failure rate > 5%
2. Service Bus queue depth > 1000
3. Cosmos DB RU consumption > 90%
4. AI Services error rate > 10%
5. Storage account throttling detected

**Warning Alerts**:
1. Queue depth > 500
2. Function duration > 2 minutes (P95)
3. Cosmos DB RU consumption > 70%
4. Search index size > 80% of limit

### Log Queries

**Failed Function Executions**:
```kql
FunctionAppLogs
| where Level == "Error"
| where TimeGenerated > ago(1h)
| summarize count() by FunctionName, bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

**Queue Depth Monitoring**:
```kql
AzureMetrics
| where ResourceProvider == "MICROSOFT.SERVICEBUS"
| where MetricName == "ActiveMessages"
| summarize avg(Average) by Resource, bin(TimeGenerated, 5m)
```

**Document Processing Pipeline**:
```kql
traces
| where customDimensions.Category == "DocumentProcessing"
| where TimeGenerated > ago(1h)
| project TimeGenerated, DocumentId=customDimensions.DocumentId, Stage=customDimensions.Stage, Status=customDimensions.Status
| order by TimeGenerated desc
```

## Scalability Considerations

### Horizontal Scaling

| Component | Scaling Method | Limits |
|-----------|----------------|--------|
| Function App | Auto-scale (queue-based) | 200 instances (Consumption), 100 instances (Premium) |
| Web App | Manual or auto-scale | Based on plan |
| Cosmos DB | Autoscale RU/s | 400-4000 RU/s (configurable) |
| AI Search | Manual (replicas/partitions) | Tier-dependent |
| Service Bus | Partitioning | Standard: 1 partition, Premium: up to 4 partitions |

### Performance Optimization

**Cosmos DB**:
- Use point reads (ID + partition key) where possible
- Batch operations for bulk writes
- Tune indexing policy (exclude unused paths)
- Consider direct mode connection

**Blob Storage**:
- Use block blobs for documents
- Enable CDN for frequently accessed documents
- Implement lifecycle management for archival

**Function Apps**:
- Use async/await properly
- Reuse HTTP clients
- Batch Service Bus operations
- Optimize cold start (Premium plan helps)

**AI Search**:
- Use filters to reduce result set
- Implement result caching
- Tune vector search parameters
- Use semantic search for better relevance

## Cost Optimization

### Development Environment
- Cosmos DB: Serverless or low autoscale (400-1000 RU/s)
- Functions: Consumption plan
- AI Services: Free (F0) tier
- Search: Basic tier
- Storage: LRS replication
- **Estimated**: $140-200/month

### Production Environment
- Cosmos DB: Autoscale (400-4000 RU/s) with reserved capacity
- Functions: Premium EP1 plan (always-on, VNet)
- AI Services: Standard (S0) with commitment discount
- Search: Standard tier with 2 replicas
- Storage: ZRS replication with lifecycle policies
- **Estimated**: $720-1,300/month

### Cost Reduction Strategies
1. Use commitment discounts for AI Services
2. Reserved capacity for Cosmos DB
3. Lifecycle management for blob storage
4. Right-size compute resources
5. Monitor and optimize RU consumption
6. Use caching to reduce AI API calls

## Disaster Recovery

### Backup Strategy

**Cosmos DB**:
- Continuous backup enabled
- Point-in-time restore available
- Backup retention: 30 days

**Blob Storage**:
- Soft delete: 7 days (dev), 30 days (prod)
- Consider blob versioning for production
- Cross-region replication (GRS) for production

**Key Vault**:
- Soft delete: 90 days
- Purge protection for production
- Backup secrets before changes

### Recovery Procedures

**Component Failure**:
1. Identify failed component via monitoring
2. Check diagnostic logs
3. Attempt automatic recovery (restart, scale)
4. Manual intervention if needed
5. Post-mortem analysis

**Data Loss**:
1. Identify scope of loss
2. Stop ingestion if corruption detected
3. Restore from backup (Cosmos DB, Storage)
4. Replay messages from Service Bus (if retained)
5. Reprocess affected documents

**Regional Outage**:
1. Monitor Azure Service Health
2. For production: failover to secondary region (if configured)
3. For development: wait for recovery or redeploy to different region

## Security Best Practices

### Implemented
✅ Managed identities for authentication
✅ RBAC for authorization (least privilege)
✅ HTTPS/TLS encryption in transit
✅ Encryption at rest (Microsoft-managed keys)
✅ Soft delete enabled
✅ Diagnostic logging enabled
✅ No secrets in code or outputs
✅ Key Vault for secrets management

### Recommended for Production
- [ ] Private endpoints for all PaaS services
- [ ] VNet integration for compute resources
- [ ] Azure Firewall or Network Virtual Appliance
- [ ] DDoS Protection Standard
- [ ] Azure Front Door with WAF
- [ ] Customer-managed encryption keys
- [ ] Azure Security Center/Defender
- [ ] Regular security assessments
- [ ] Penetration testing
- [ ] Compliance certifications (SOC 2, HIPAA, etc.)

## References

- [Azure Architecture Center - Intelligent Applications](https://learn.microsoft.com/azure/architecture/data-guide/big-data/ai-overview)
- [Azure AI Document Intelligence Best Practices](https://learn.microsoft.com/azure/ai-services/document-intelligence/best-practices)
- [Azure AI Search Vector Search](https://learn.microsoft.com/azure/search/vector-search-overview)
- [Durable Functions Patterns](https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-overview)
- [Cosmos DB Best Practices](https://learn.microsoft.com/azure/cosmos-db/nosql/best-practice)

