# Fleet Data Platform — Data Model & ERD

This document contains two diagrams that answer two different questions:

1. **Data Lineage Diagram** — how data flows and transforms across the medallion architecture (Bronze → Silver → Gold)
2. **Entity Relationship Diagram (ERD)** — how the modeled entities in the Gold/serving layer relate to each other

---

## 1. Data Lineage Diagram (Medallion Flow)

```
┌──────────────────────────┐
│      BRONZE (Raw)         │
│   bronze/sftp_ingestion/  │
│----------------------------│
│  event_id      (string)   │
│  vehicle_id    (string)   │
│  timestamp     (string)   │
│  speed_mph     (string)   │
│  fuel_level_pct(string)   │
│  engine_temp_c (string)   │
│  latitude      (string)   │
│  longitude     (string)   │
│  ingestion_timestamp      │
│  source_file               │
└─────────────┬─────────────┘
              │  cast types, parse timestamps,
              │  dedupe on event_id, drop nulls,
              │  flag is_overspeeding
              ▼
┌──────────────────────────┐
│      SILVER (Cleaned)     │
│  silver/fleet_telematics/ │
│----------------------------│
│  event_id      (string,PK)│
│  vehicle_id    (string,FK)│
│  timestamp     (timestamp)│
│  speed_mph     (double)   │
│  fuel_level_pct(double)   │
│  engine_temp_c (double)   │
│  latitude      (double)   │
│  longitude     (double)   │
│  is_overspeeding (bool)   │
│  ingestion_audit_timestamp│
└─────────────┬─────────────┘
              │  group by vehicle_id,
              │  aggregate speed/fuel/violations
              ▼
┌──────────────────────────┐
│   GOLD (Business Fact)    │
│ gold/fact_fleet_performance│
│----------------------------│
│  vehicle_id (PK)           │
│  maximum_logged_speed      │
│  average_operational_speed │
│  mean_fuel_capacity        │
│  total_overspeeding_violations│
│  total_events_recorded     │
│  last_modified_date        │
└─────────────┬─────────────┘
              │  exposed via
              ▼
┌──────────────────────────┐
│   Synapse Serverless SQL  │
│   vw_fleet_performance    │
└──────────────────────────┘
```

**Purpose:** shows transformation logic and data quality rules applied at each stage. This is a pipeline/lineage view, not an entity-relationship view — there are no cross-entity relationships at this stage because each layer is the same conceptual entity (a telemetry reading) at increasing levels of refinement.

---

## 2. Entity Relationship Diagram (Dimensional Model)

This is the ERD in the traditional sense — entities, primary/foreign keys, and cardinality between them. It describes the **serving layer** (what Power BI / analysts query), built on top of the Gold fact table.

```
┌───────────────────────────┐
│        dim_vehicle          │
│──────────────────────────────│
│ PK  vehicle_id               │
│     make                     │
│     model                    │
│     depot_location           │
└───────────────┬───────────────┘
                │
                │ 1
                │
                │ *
┌───────────────┴───────────────────┐
│       fact_fleet_performance        │
│────────────────────────────────────│
│ PK/FK vehicle_id                    │
│       report_date (FK, conceptual)  │
│       maximum_logged_speed          │
│       average_operational_speed     │
│       mean_fuel_capacity            │
│       total_overspeeding_violations │
│       total_events_recorded         │
│       last_modified_date            │
└───────────────┬─────────────────────┘
                │
                │ *
                │
                │ 1
┌───────────────┴───────────────┐
│           dim_date              │
│──────────────────────────────────│
│ PK  report_date                  │
│     year                         │
│     month                        │
│     week                         │
│     day_name                     │
└─────────────────────────────────┘
```

### Cardinality
- **dim_vehicle → fact_fleet_performance**: One-to-Many (1:*) — one vehicle has many performance records over time
- **dim_date → fact_fleet_performance**: One-to-Many (1:*) — one calendar date applies to many vehicle records

### Entity Definitions

**dim_vehicle** (Dimension)
| Column | Type | Key | Description |
|---|---|---|---|
| vehicle_id | string | PK | Natural key, vehicle identifier |
| make | string | | Vehicle manufacturer |
| model | string | | Vehicle model |
| depot_location | string | | Assigned depot |

**dim_date** (Dimension)
| Column | Type | Key | Description |
|---|---|---|---|
| report_date | date | PK | Calendar date |
| year | int | | Year number |
| month | int | | Month number |
| week | int | | ISO week number |
| day_name | string | | Day of week name |

**fact_fleet_performance** (Fact)
| Column | Type | Key | Description |
|---|---|---|---|
| vehicle_id | string | FK → dim_vehicle | Vehicle reference |
| maximum_logged_speed | double | | Highest recorded speed |
| average_operational_speed | double | | Mean speed across events |
| mean_fuel_capacity | double | | Average fuel level |
| total_overspeeding_violations | int | | Count of overspeeding events |
| total_events_recorded | int | | Total telemetry events |
| last_modified_date | timestamp | FK → dim_date (conceptual) | Processing timestamp |

---

## Design Notes & Production Considerations

- **dim_vehicle is currently static/seeded** (10 vehicles, hardcoded via SQL VALUES) since there is no real fleet master data source in this portfolio project. In production this would be sourced from a fleet management system (e.g. via ADF copy from SQL Server/Oracle) and managed as a **Type 2 Slowly Changing Dimension** if depot reassignment or vehicle decommissioning needs historical tracking.
- **dim_date is derived directly from the fact table's timestamp** rather than a pre-built calendar table. In production this would be a standalone, pre-populated date dimension spanning several years, independent of fact data.
- **fact_fleet_performance grain is currently "one row per vehicle, all-time"**. In production this would be re-grained to **one row per vehicle per day** (composite key: vehicle_id + report_date) to support trend analysis over time rather than a single cumulative snapshot.
- **No bridge or junction tables are needed** at this scale — fleet vehicles do not have many-to-many relationships with depots in this model (one vehicle, one current depot).
