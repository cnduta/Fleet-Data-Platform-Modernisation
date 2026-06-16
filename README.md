# Fleet Data Platform Modernisation

![Azure](https://img.shields.io/badge/Azure-Data%20Engineering-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Azure Data Factory](https://img.shields.io/badge/Azure%20Data%20Factory-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Azure Synapse Analytics](https://img.shields.io/badge/Azure%20Synapse%20Analytics-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Event Hubs](https://img.shields.io/badge/Event%20Hubs-0078D4?style=flat&logo=azure-event-hubs&logoColor=white)
![Logic Apps](https://img.shields.io/badge/Logic%20Apps-0078D4?style=flat&logo=logic-apps&logoColor=white)
![Log Analytics](https://img.shields.io/badge/Log%20Analytics-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Microsoft Purview](https://img.shields.io/badge/Microsoft%20Purview-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Bicep](https://img.shields.io/badge/Bicep-0078D4?style=flat&logo=bicep&logoColor=white)
![Status](https://img.shields.io/badge/Status-In%20Progress-%23FFBF00)

## 🏗️ Lambda Architecture & Platform Mapping

The platform implements a Lambda Architecture to handle both metadata-driven batch historical data and real-time fleet telemetry streams using the Azure Ecosystem.

```mermaid
graph LR
    %% Data Sources
    subgraph Sources [Data Sources]
        SFTP[Legacy SFTP <br/> Flat Files]
        API[Fleet REST API <br/> Real-time Telemetry]
    end

    %% Ingestion Layer
    subgraph Ingest [Ingest & Stream]
        ADF[Azure Data Factory <br/> Metadata-Driven Ingestion]
        EH[Azure Event Hubs <br/> Python Streaming Producer]
    end

    %% Storage & Processing (Medallion)
    subgraph Storage [Storage & Processing: ADLS Gen2]
        direction TB
        B[(Bronze Layer <br/> Raw Ingest)] 
        S[(Silver Layer <br/> Cleaned & Deduplicated)] 
        G[(Gold Layer <br/> Business Metrics)]
        
        B -->|Synapse PySpark| S
        S -->|Synapse PySpark| G
    end

    %% Serving & Presentation Layer
    subgraph Serve [Serve & Analyze]
        Syn[Synapse Analytics <br/> Serverless SQL Views]
        PBI[Power BI <br/> Interactive Dashboards]
    end

    %% Governance & Observability Wrapper
    subgraph Platform [Cross-Cutting Governance & Observability]
        IaC[Azure Bicep <br/> Infrastructure as Code]
        LA[Log Analytics <br/> KQL Monitoring]
        LAps[Azure Logic Apps <br/> Failure Alerts]
        Pur[Microsoft Purview <br/> Data Catalog & Lineage]
    end

    %% Pipeline Connections
    SFTP -->|Scheduled Lookup| ADF
    API -->|EventHubProducerClient| EH
    
    ADF -->|Landing Storage| B
    EH -->|Streaming Spark Capture| B
    
    G -->|Relational Mapping| Syn
    Syn -->|Direct Query/Import| PBI

    %% Monitoring Links (Invisible references to anchor the diagram flow)
    ADF -.->|Logs| LA
    EH -.->|Logs| LA
    LA -.->|Triggers| LAps
    Storage -.->|Scans| Pur

    %% Styling
    style Sources fill:#f9f9f9,stroke:#333,stroke-width:1px
    style Ingest fill:#e1f5fe,stroke:#03a9f4,stroke-width:2px
    style Storage fill:#e8f5e9,stroke:#4caf50,stroke-width:2px
    style Serve fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    style Platform fill:#f3e5f5,stroke:#9c27b0,stroke-width:1px
```

An end-to-end enterprise Azure data platform simulating a legacy fleet telematics system modernization. This project replaces brittle, manual SFTP flat-file processes with a metadata-driven ingestion framework, a real-time event streaming architecture, and robust infrastructure monitoring.



---

## 🛠️ Tech Stack & Platform Components
- **Infrastructure as Code (IaC):** Azure Bicep (Modular provisioning)
- **Data Ingestion & Streaming:** Azure Data Factory (Metadata-driven JSON), Azure Event Hubs (Python `EventHubProducerClient`)
- **Storage & Compute:** Azure Data Lake Storage Gen2, Azure Databricks (PySpark), Azure Synapse Analytics
- **Data Transformation:** Medallion Architecture (Delta Lake tables)
- **Observability & Governance:** Azure Logic Apps, Log Analytics (KQL), Microsoft Purview
- **CI/CD & Version Control:** GitHub, GitHub Actions

---

## 📈 Project Roadmap & Implementation Phases

### Phase 1: Infrastructure & Automation (Completed)
*   **Infrastructure as Code:** Developed modular Azure Bicep files to provision all platform services, security frameworks, and network components deterministically.
*   **Pipeline Automation:** Configured a GitHub Actions workflow to enable a complete CI/CD deployment pipeline for infrastructure changes.

### Phase 2: Batch Ingestion Framework (Completed)
*   **Metadata-Driven Ingestion:** Built generic, scalable ADF pipelines driven by a central JSON config sheet. Uses `Lookup` and `ForEach` activities to pull bulk telematics data via secure SFTP.
*   **Secure Credential Management:** Enforced zero hardcoded strings by backing all system parameters and credentials with Azure Key Vault secret management.

### Phase 3: Infrastructure Observability & Alerting (Completed)
*   **Enterprise Alerting:** Configured an Azure Logic App workflow that hooks into core pipelines to send instant failure metrics and tracking updates.
*   **Centralized Logging:** Consolidated platform metrics into an Azure Log Analytics workspace. Developed custom Kusto Query Language (KQL) scripts to monitor pipeline errors, throughput, and system resource allocation.

### Phase 4: Real-Time Event Streaming (In Progress)
*   **Telemetry Stream:** Engineering a continuous Python client script utilizing `EventHubProducerClient` to mimic streaming GPS coordinates and engine data.
*   **Managed Identities:** Using secure Azure RBAC and Managed Identities for script-to-cloud secure authentication, completely bypassing legacy access keys.

### Phase 5: Medallion Processing & BI Serving (Upcoming)
*   **Bronze / Silver / Gold:** Implementing data cleansing, over-speeding event calculations, and business metric calculations using PySpark notebooks in Synapse Studio.
*   **Downstream Analytics:** Generating analytical relational views in Synapse Serverless pools for direct ingestion into an interactive Power BI operational monitor.

### Phase 6: Observability, Governance & Lineage (In Progress)
*   **Centralized Logging:** Consolidated all diagnostic and metric logs from Azure Data Factory and Databricks into an Azure Log Analytics workspace.
*   **Operational Intelligence:** Wrote custom Kusto Query Language (KQL) scripts to build monitoring alerts for pipeline failures, processing latency, and ingestion bottlenecks.
*   **Data Governance:** Implemented Microsoft Purview stubs to catalog data assets, map data lineages across the Medallion layers, and enforce data privacy compliance.


