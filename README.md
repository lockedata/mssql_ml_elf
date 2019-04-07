# mssql_ml_elf
Execution and Logging Framework (ELF) for ML models in SQL Server.

This functionality is bundled up in an SSDT database project so that it can be deployed anywhere. 

## Compatibility
As this is intended to surround the ML Services components, you can only deploy to 2016 and beyond.  
Current compatibility is full for Windows, in preview in Azure SQL (with R only), and coming in Linux 2019.

## Key components
- `[model]` is where models for feature engineering and scoring live.
   + Insert or update a model with the `upsert_model` stored procedure and add measures of fit for monitoring
   + Use [TEMPORAL TABLE SQL queries](https://www.mssqltips.com/sqlservertip/5436/options-to-retrieve-sql-server-temporal-table-and-history-data/) to gain insight into model changes over time
- `[prediction]` is a generic prediction table where you might store things for historical review and monitoring
- `[prediction_log]` is a logging table execution information can be written to help understand speeds and errors
   + Use the `begin_prediction_log` and `end_prediction_log` stored procedures in prediction routines to work with the logging table

## Samples
The `[samples]` schema shows how the base `[ml]` components can be used in a realistic scenario.
