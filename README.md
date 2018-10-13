# mssql_ml_elf
Execution and Logging Framework (ELF) for ML models in SQL Server

## Key components
- `[model]` is where models for feature engineering and scoring live.
   + Insert or update a model with `upsert_model` and add measures of fit for monitoring
- `[prediction]` is a generic prediction table where you might store things for historical review and monitoring
- `[prediction_log]` is a logging table execution information can be written to help understand speeds and errors

## Samples
The `[samples]` schema shows how the base `[ml]` components can be used in a realistic scenario.
