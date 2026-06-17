# Fleet Data Platform Modernisation

![Azure](https://img.shields.io/badge/Azure-Data%20Engineering-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Azure Data Factory](https://img.shields.io/badge/Azure%20Data%20Factory-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Azure Synapse Analytics](https://img.shields.io/badge/Azure%20Synapse%20Analytics-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Event Hubs](https://img.shields.io/badge/Event%20Hubs-0078D4?style=flat&logo=azure-event-hubs&logoColor=white)
![Logic Apps](https://img.shields.io/badge/Logic%20Apps-0078D4?style=flat&logo=logic-apps&logoColor=white)
![Log Analytics](https://img.shields.io/badge/Log%20Analytics-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Microsoft Purview](https://img.shields.io/badge/Microsoft%20Purview-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Bicep](https://img.shields.io/badge/Bicep-0078D4?style=flat&logo=bicep&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-Green)## Problem Statement
---
## Problem Statement

A fleet management company receives vehicle telemetry (speed, fuel, engine temperature, GPS location) from two sources: periodic batch files dropped to an SFTP server by on-vehicle hardware, and a real-time stream as vehicles report live status. The legacy approach to this kind of ingestion is typically a single brittle script that fails silently, has no governance layer, and gives operations teams no visibility into which vehicles are overspeeding or running low on fuel until someone manually opens a spreadsheet.
This project rebuilds that pipeline as a modern, observable, governed Azure data platform — handling both ingestion patterns (batch and streaming), enforcing data quality through a layered medallion architecture, and exposing clean, business-ready metrics through a SQL serving layer.
---
## 🏗️ Architecture Overview 
SFTP Source ──┐
              ├──> ADF (metadata-driven) ──> Bronze (raw) ──> Silver (cleaned) ──> Gold (aggregated) ──> Synapse Serverless SQL
Event Hubs ───┘         │                                                                                        │
   ▲                    │                                                                                        ▼
   │              Logic Apps (failure detection + alerting)                                        Power BI / Reporting
Python streaming                    │
simulator                           ▼
                              Log Analytics + Purview (governance)


---

## 🛠️ Tech Stack & Platform Components
- **Infrastructure as Code (IaC):** Azure Bicep (Modular provisioning)
- **Data Ingestion & Streaming:** Azure Data Factory (Metadata-driven JSON), Azure Event Hubs (Python `EventHubProducerClient`)
- **Storage & Compute:** Azure Data Lake Storage Gen2, Azure Databricks (PySpark), Azure Synapse Analytics
- **Data Transformation:** Medallion Architecture (Delta Lake tables)
- **Observability & Governance:** Azure Logic Apps, Log Analytics (KQL), Microsoft Purview
- **CI/CD & Version Control:** 
---
## Project Overview 
fleet-data-platform-modernisation/
├── infra/                   Bicep IaC templates
├── adf/                     ADF pipeline, linked service, and dataset JSON exports
├── notebooks/                PySpark medallion notebooks (Bronze/Silver/Gold)
├── streaming/                Python batch generator and real-time Event Hubs simulator
├── sql/                      Synapse Serverless SQL views
├── docs/
│   ├── architecture/         Architecture diagram
│   ├── erd/                  Data model and entity relationship documentation
│   └── runbook/               Operational runbook and governance notes
├── requirements.txt
└── README.md
---
## How to deploy
How to Deploy
All infrastructure is provisioned via a single Bicep template.
```bash
az group create --name rg-fleet-platform-prod --location uksouth

az deployment group create \
  --resource-group rg-fleet-platform-prod \
  --template-file infra/main.bicep```
This provisions: ADLS Gen2 (with bronze/silver/gold containers), Azure Data Factory, Event Hubs namespace and hub, Key Vault, Log Analytics workspace, Synapse workspace, and Logic App.
After deployment, role assignments are required for managed identities to access Key Vault, Storage, and ADF — see docs/runbook/runbook.md for the full sequence.
---
## 📈 Project Roadmap & Implementation Phases

### Phase 1: Infrastructure & Automation 
*   **Infrastructure as Code:** Developed modular Azure Bicep files to provision all platform services, security frameworks, and network components deterministically.
*   **Pipeline Automation:** Configured a GitHub Actions workflow to enable a complete CI/CD deployment pipeline for infrastructure changes.

### Phase 2: Batch Ingestion Framework 
*   **Metadata-Driven Ingestion:** Built generic, scalable ADF pipelines driven by a central JSON config sheet. Uses `Lookup` and `ForEach` activities to pull bulk telematics data via secure SFTP.
*   **Secure Credential Management:** Enforced zero hardcoded strings by backing all system parameters and credentials with Azure Key Vault secret management.

### Phase 3: Infrastructure Observability & Alerting 
*   **Enterprise Alerting:** Configured an Azure Logic App workflow that hooks into core pipelines to send instant failure metrics and tracking updates.
*   **Centralized Logging:** Consolidated platform metrics into an Azure Log Analytics workspace. Developed custom Kusto Query Language (KQL) scripts to monitor pipeline errors, throughput, and system resource allocation.

### Phase 4: Real-Time Event Streaming 
*   **Telemetry Stream:** Engineering a continuous Python client script utilizing `EventHubProducerClient` to mimic streaming GPS coordinates and engine data.
*   **Managed Identities:** Using secure Azure RBAC and Mana
### Phase 5: Medallion Processing & BI Serving 
*   **Bronze / Silver / Gold:** Implementing data cleansing, over-speeding event calculations, and business metric calculations using PySpark notebooks in Synapse Studio.
*   **Downstream Analytics:** Generating analytical relational views in Synapse Serverless pools for direct ingestion into an interactive Power BI operational monitor.

### Phase 6: Observability, Governance & Lineage 
*   **Centralized Logging:** Consolidated all diagnostic and metric logs from Azure Data Factory and Databricks into an Azure Log Analytics workspace.
*   **Operational Intelligence:** Wrote custom Kusto Query Language (KQL) scripts to build monitoring alerts for pipeline failures, processing latency, and ingestion bottlenecks.
*   **Data Governance:** Implemented Microsoft Purview stubs to catalog data assets, map data lineages across the Medallion layers, and enforce data privacy compliance.

----
## Design Decisions
Metadata-driven ingestion over hardcoded pipelines — adding a new source file is a config change in pipeline_config.json, not a pipeline redesign. This is the standard pattern for ingestion at scale.
Delta Lake format throughout the medallion layers — enables ACID transactions, schema evolution, and time travel, none of which are available with plain Parquet or CSV.
Managed Identity authentication everywhere — no connection strings or credentials are hardcoded in any pipeline, notebook, or script. All cross-service authentication uses system-assigned managed identities with RBAC role assignments.
Serverless SQL over a dedicated SQL pool — at this data volume, a dedicated pool's fixed cost isn't justified. Serverless's pay-per-query model is both cheaper and architecturally correct for a
