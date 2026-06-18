# Fleet Data Platform Modernisation
![Azure](https://img.shields.io/badge/Azure-Data%20Engineering-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Azure Data Factory](https://img.shields.io/badge/Azure%20Data%20Factory-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Azure Synapse Analytics](https://img.shields.io/badge/Azure%20Synapse%20Analytics-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Event Hubs](https://img.shields.io/badge/Event%20Hubs-0078D4?style=flat&logo=azure-event-hubs&logoColor=white)
![Logic Apps](https://img.shields.io/badge/Logic%20Apps-0078D4?style=flat&logo=logic-apps&logoColor=white)
![Log Analytics](https://img.shields.io/badge/Log%20Analytics-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Microsoft Purview](https://img.shields.io/badge/Microsoft%20Purview-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Bicep](https://img.shields.io/badge/Bicep-0078D4?style=flat&logo=bicep&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-Green)
---

End-to-end Azure data platform simulating fleet telematics modernisation — metadata-driven ADF ingestion, PySpark medallion architecture (Bronze/Silver/Gold), real-time Event Hubs streaming, Synapse SQL serving layer, and full infrastructure-as-code via Bicep. Built as a senior data engineering portfolio project.

---

## 1. Problem Statement

A fleet management company receives vehicle telemetry (speed, fuel, engine temperature, GPS location) from two sources: periodic batch files dropped to an SFTP server by on-vehicle hardware, and a real-time stream as vehicles report live status. The legacy approach to this kind of ingestion is typically a single brittle script that fails silently, has no governance layer, and gives operations teams no visibility into which vehicles are overspeeding or running low on fuel until someone manually opens a spreadsheet.

This project rebuilds that pipeline as a modern, observable, governed Azure data platform — handling both ingestion patterns (batch and streaming), enforcing data quality through a layered medallion architecture, and exposing clean, business-ready metrics through a SQL serving layer.

---

## 2. Architecture Overview

```
SFTP Source ──┐
              ├──> ADF (metadata-driven) ──> Bronze (raw) ──> Silver (cleaned) ──> Gold (aggregated) ──> Synapse Serverless SQL
Event Hubs ───┘         │                                                                                        │
   ▲                    │                                                                                        ▼
   │              Logic Apps (failure detection + alerting)                                        Power BI / Reporting
Python streaming                    │
simulator                           ▼
                              Log Analytics + Purview (governance)
```

See `docs/architecture/architecture_diagram.png` for the full visual diagram.

---

## 3. Tech Stack

| Tool | Purpose | Why this tool |
|---|---|---|
| Bicep | Infrastructure as Code | Native Azure IaC, no separate state file to manage (vs Terraform), tighter integration with ARM |
| Azure Data Factory | Batch ingestion orchestration | Metadata-driven pattern scales to new sources without pipeline redesign |
| Azure Event Hubs | Real-time ingestion | Industry-standard for high-throughput streaming telemetry |
| Azure Data Lake Storage Gen2 | Data lake storage | Hierarchical namespace required for medallion architecture performance |
| Azure Synapse Analytics (Spark) | Data processing | PySpark medallion transformations at scale |
| Azure Synapse Analytics (Serverless SQL) | Serving layer | Zero idle cost, pay-per-query, ideal for a demonstration-scale dataset |
| Azure Key Vault | Secrets management | No credentials hardcoded anywhere in pipeline code |
| Azure Logic Apps | Alerting | Automated failure detection without a dedicated monitoring service |
| Azure Log Analytics | Observability | Centralised query-able log store for pipeline diagnostics |
| Microsoft Purview | Governance (documented intent) | See `docs/runbook/governance_notes.md` for why this was scoped as design intent rather than a live resource |

---

## 4. Project Structure

```
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
```

---

## 5. How to Deploy

All infrastructure is provisioned via a single Bicep template.

```bash
az group create --name rg-fleet-platform-prod --location uksouth

az deployment group create \
  --resource-group rg-fleet-platform-prod \
  --template-file infra/main.bicep
```

This provisions: ADLS Gen2 (with bronze/silver/gold containers), Azure Data Factory, Event Hubs namespace and hub, Key Vault, Log Analytics workspace, Synapse workspace, and Logic App.

After deployment, role assignments are required for managed identities to access Key Vault, Storage, and ADF — see `docs/runbook/runbook.md` for the full sequence.

---

## 6. How to Run

1. **Batch ingestion**: Upload sample CSVs to the SFTP source, then trigger `pl_sftp_to_bronze_metadata` in ADF. The pipeline reads `adf/pipeline_config.json`-style metadata to determine which files to ingest — adding a new source file requires only a config update, not a pipeline change.
2. **Streaming ingestion**: Run `streaming/stream_fleet_telematics.py` to simulate live vehicle telemetry into Event Hubs.
3. **Medallion processing**: Run the three notebooks in `notebooks/` in sequence — `01_bronze_ingestion`, `02_silver_cleaning`, `03_gold_aggregation` — against the Synapse Spark pool.
4. **Serving layer**: Query `sql/views/vw_fleet_performance.sql` via Synapse Serverless SQL for business-ready, vehicle-level KPIs.
5. **Monitoring**: Logic App `la-fleetcn-prod` polls ADF every 15 minutes and pushes failure alerts; Log Analytics retains full pipeline/activity/trigger run history.

---

## 7. Data Model

Full data lineage and entity-relationship documentation, including the dimensional model (`dim_vehicle`, `dim_date`, `fact_fleet_performance`) is in `docs/erd/erd.md`.

---

## 8. Monitoring & Governance

See `docs/runbook/governance_notes.md` for the monitoring architecture, the Purview governance design (documented rather than deployed, with rationale), and the production alerting threshold strategy.

---

## 9. Design Decisions

- **Metadata-driven ingestion over hardcoded pipelines** — adding a new source file is a config change in `pipeline_config.json`, not a pipeline redesign. This is the standard pattern for ingestion at scale.
- **Delta Lake format throughout the medallion layers** — enables ACID transactions, schema evolution, and time travel, none of which are available with plain Parquet or CSV.
- **Managed Identity authentication everywhere** — no connection strings or credentials are hardcoded in any pipeline, notebook, or script. All cross-service authentication uses system-assigned managed identities with RBAC role assignments.
- **Serverless SQL over a dedicated SQL pool** — at this data volume, a dedicated pool's fixed cost isn't justified. Serverless's pay-per-query model is both cheaper and architecturally correct for a low-frequency reporting workload.


---

## 10. What I'd Do Next in Production

- Replace the ntfy.sh/webhook alerting pattern with Teams or PagerDuty integration and tiered severity logic

- Add a CI/CD pipeline (Azure DevOps or GitHub Actions) to deploy Bicep changes and ADF pipeline JSON automatically on merge to main
