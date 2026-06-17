│ PK report_date │
│ year │
│ month │
│ week │
│ day_name │
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
 
