# Operational Runbook — Fleet Data Platform Modernisation

This runbook documents standard operating procedures for the platform's day-to-day operation and incident response.

---

## 1. Deployment Sequence (First-Time Setup)

1. Create resource group: `az group create --name rg-fleet-platform-prod --location uksouth`
2. Deploy Bicep template: `az deployment group create --resource-group rg-fleet-platform-prod --template-file infra/main.bicep`
3. Create ADLS containers: `bronze`, `silver`, `gold`
4. Assign role assignments (required — managed identities have no access by default):
   - ADF → Storage Blob Data Contributor on the storage account
   - ADF → Key Vault Secrets User on the Key Vault
   - Synapse workspace → Storage Blob Data Contributor on the storage account
   - Logic App → Data Factory Contributor on the Data Factory
   - Your own user account → Storage Blob Data Contributor and Key Vault Secrets Officer (for CLI/portal operations)
5. Add secrets to Key Vault: SFTP password, storage connection string, Event Hubs connection string
6. Build ADF linked services (Key Vault, SFTP, ADLS Gen2), datasets, and the metadata-driven pipeline
7. Upload `pipeline_config.json` to `bronze/config/`
8. Build and publish the Logic App alerting workflow
9. Create the Synapse Spark pool (small, autoscale disabled, auto-pause at 15 minutes)

---

## 2. What to Do When the ADF Pipeline Fails

1. Check the Logic App alert (ntfy.sh notification in this project; production would use Teams/email/PagerDuty)
2. Go to ADF Studio → Monitor → Pipeline runs → click the failed run
3. Expand the failing activity (usually Copy inside the ForEach) and read the error message
4. Common failure causes in this pipeline:
   - **SFTP authentication failure** — check that the Key Vault secret `sftp-password` is current and that the SFTP linked service test connection still succeeds
   - **Wildcard path misconfiguration** — verify the Copy activity's source wildcard file name uses `@item().sourceFile` and the folder path field is empty (not the reverse)
   - **Sink path collision** — verify the sink dataset's folder path includes the dynamic `targetFolder` parameter so concurrent ForEach iterations don't overwrite each other
5. Fix the root cause, then re-trigger manually via **Add trigger → Trigger now**
6. Confirm success in Monitor before considering the incident closed

---

## 3. How to Reprocess a Failed Batch

1. Identify the affected date/batch from the failed pipeline run's parameters
2. If files were partially written to Bronze, delete the affected path before reprocessing:
   ```bash
   az storage fs file delete --account-name stfleetcndatalakeprod --file-system bronze --path <path> --auth-mode login --yes
   ```
3. Re-trigger the ADF pipeline for that specific batch
4. Once Bronze is confirmed correct (check row counts against source), rerun the Silver and Gold notebooks in sequence — both depend on a clean upstream layer
5. Validate the Gold output via the Synapse SQL view before notifying downstream consumers that data is refreshed

---

## 4. How to Check Event Hubs Lag

1. Portal → Event Hubs namespace → `eh-fleet-events` → Metrics
2. Check **Incoming Messages** vs **Outgoing Messages** — a growing gap indicates a consumer-side processing lag
3. For this project's scale (50-event test batches), lag should never be visible; in production with continuous streaming, this metric would feed an alert threshold

---

## 5. How to Query Log Analytics for Errors

Use the saved query `failed_pipeline_runs` in `law-fleetcn-prod` → Logs:

```kql
ADFPipelineRun
| where Status_s == "Failed"
| project TimeGenerated, PipelineName_s, RunId_g, Status_s, Message_s
| order by TimeGenerated desc
```

For activity-level detail on a specific failed run, filter `ADFActivityRun` by the `RunId_g` from the pipeline-level query above.

---

## 6. Cost Control Checklist

This project was built under a self-imposed low-cost constraint (sub-$5/month). Operational habits that kept it there:

- **Spark pool sessions were explicitly stopped** after each notebook run (Monitor → Apache Spark applications → Cancel), not left to auto-pause — an open notebook with an attached kernel keeps cores allocated and continues billing even when idle.
- **Synapse Serverless SQL** was used for the serving layer instead of a dedicated SQL pool — zero idle cost, pay-per-query only.
- **Purview was not deployed live** — documented as architectural intent instead, avoiding its ~$0.40/hour minimum cost (see `governance_notes.md`).
- **Event Hubs Basic tier** and **Log Analytics pay-as-you-go (first 5GB free)** were used rather than higher tiers not needed at this data volume.
- A **$5 spending alert** was kept active on the subscription throughout the build as a safety net.

Before any extended work session: confirm no Spark pool shows active vCores allocated (Manage → Apache Spark pools → check "Allocated vCores" reads 0 when nothing should be running).
