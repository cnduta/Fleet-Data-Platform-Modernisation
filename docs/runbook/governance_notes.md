# Governance & Monitoring Notes

## Log Analytics — Pipeline Monitoring

ADF (`adf-fleetcn-prod`) is connected to `law-fleetcn-prod` via diagnostic settings,
streaming three categories of operational telemetry:

- **PipelineRuns** — overall pipeline execution status and duration
- **ActivityRuns** — individual activity-level detail (Lookup, ForEach, Copy)
- **TriggerRuns** — trigger firing history (manual and scheduled)

This gives full observability into the ingestion layer without needing to check
ADF Monitor manually. In production, this would be the foundation for:

- Automated alerting thresholds (e.g. alert if failure rate > 5% over 1 hour)
- SLA tracking and reporting (e.g. 99% of daily loads complete by 6 AM)
- Root cause analysis when a downstream consumer (Power BI, Synapse) reports stale data

### Saved Query — Failed Pipeline Runs

```kql
ADFPipelineRun
| where Status_s == "Failed"
| project TimeGenerated, PipelineName_s, RunId_g, Status_s, Message_s
| order by TimeGenerated desc
```

This query is saved in Log Analytics as `failed_pipeline_runs` and is the first
diagnostic step in the operational runbook when the Logic App alert fires.

---

## Microsoft Purview — Governance Intent (Documented, Not Deployed)

A live Purview account was deliberately **not provisioned** for this portfolio
project. Purview has a non-trivial minimum running cost (~$0.40/hour) which is
not justified for a demonstration-scale dataset of 10 vehicles and ~200 events.

In a production deployment, Purview would be configured to:

1. **Register the ADLS Gen2 account** (`stfleetcndatalakeprod`) as a data source,
   with separate scans configured per container (bronze, silver, gold)
2. **Classify sensitive columns automatically** — e.g. `latitude`/`longitude`
   would be flagged as location data, relevant under UK GDPR for any system
   tracking individuals (in this case, vehicle location which may be linked to
   driver identity)
3. **Build a data catalog** so that analysts and other engineering teams can
   discover the `fact_fleet_performance` table without needing direct access
   to the engineering team, while still tracking who accessed what and when
4. **Establish lineage tracking** from SFTP source through to the Gold layer,
   automatically — rather than relying on this manually written documentation
5. **Enforce access policies** at the data asset level, separate from the
   Azure RBAC roles already in place on the storage account

### Why this matters for this architecture specifically

Fleet telemetry data has a clear data sensitivity gradient as it moves through
the medallion layers:

- **Bronze** — raw data, closest to source, least governed, access restricted
  to the data engineering team only
- **Silver** — cleaned but still granular (per-event, per-vehicle, GPS-level),
  access should be restricted to analytics engineers and data scientists
- **Gold** — aggregated to vehicle level, no individual event/location detail,
  safe for broader business consumption (operations managers, finance)

Purview's classification and access policy layer is what would enforce this
gradient automatically, rather than relying on container-level RBAC alone,
which currently treats all data in a container the same regardless of
sensitivity within it.

---

## Alerting Strategy (Production Threshold Recommendation)

The current Logic App alerts on **any** pipeline failure within a 15-minute
recurrence window. This is appropriate for a low-volume demonstration pipeline
but would be noisy in production. A production threshold strategy would be:

| Severity | Condition | Action |
|---|---|---|
| Low | Single transient failure, auto-retry succeeds | Log only, no alert |
| Medium | Failure persists after 1 retry | Notify on-call engineer (Teams/email) |
| High | Failure persists after 2 retries, or affects > 1 pipeline | Page on-call (PagerDuty/Teams urgent) |
| Critical | Failure affects the Gold layer refresh feeding an executive dashboard | Immediate page + incident ticket auto-created |

This project implements the "Medium" tier behaviour as a demonstration of the
pattern; the full tiered system would require additional Logic App branching
logic and integration with an incident management tool.
