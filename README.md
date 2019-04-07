# Execution and Logging Framework (ELF)
This project can be used as the basis for an operational ML training and prediction capability in SQL Server and Azure SQL.
This functionality is bundled up in a database project so that it can be deployed against different targets and managed under source control. 

*As everyone has their own set of requirements this can be used as-is or as a starting point for discussion as to what your requirements are and what the resulting data model should look like.*

## Example use
The `[samples]` schema shows how the base `[ml]` components can be used in a realistic scenario to train a feature engineering model and a predictive model, store these and then use them in a predictive model scenario.

- the [`train_iris`](MSSQL_ML_ELF/Stored%20Procedures/sample.train_iris.sql) stored prcedure takes a bulk of data, partitions into training and testing data, performs feature engineering, generates a model, applies the feature engineering model to the test data, predicts for the test data, and then writes all the results to the `[model]` table. This stored procedure could be run on a scheduled basis or inside an SSIS workload to regularly retrain based on the latest data.
- the [`score_iris`](MSSQL_ML_ELF/Stored%20Procedures/sample.score_iris.sql) stored procedure takes 1 or more rows of data, applies the feature engineering transformation model, and then uses the prediction model to score the row(s). Whilst it's doing this it logs to the database and outputs all the scores and associated information to the database so that the application requesting the predictions gets them back as the result of the stored procedure but we have a record in the databse for monitoring our solution

## Key components

### `[model]`
**Store any reusable object like a predictive model along with information about how the object was created**

The [`[model]`](MSSQL_ML_ELF/Tables/ml.model.sql) table is a temporal table that contains some sort of model and information aout how that model was developed.

A *temporal table* is a SQL Server 2016+ feature that maintains a queryable record of changes to values stored in the table. This means we can have a model like `churn_likelihood` that we update on a regular basis. The older versions of the model object and the measures of fit associated with it will be retrievable for performing what-if analysis, tracking model or feature drift, or providing a record with how automated decisions (see Note 1) were made at a given point in time. Use [TEMPORAL TABLE SQL queries](https://www.mssqltips.com/sqlservertip/5436/options-to-retrieve-sql-server-temporal-table-and-history-data/) to gain insight into model changes over time.

The table contains columns for storing:
- A unique user friendly model name
- A varbinary representation of an object e.g. `serialize(lm())` which is the serialized storable version of a linear regression model that will typically sit in-memory
- Observation volumes for train and test to provide a high-level overview of the data sizes involved with developing a model
- Key metric type and value to enable monitoring of the key metric over time. The key measure by which you evaluate the model should be the one that aligns most to the business requirement so it could be overall accuracy, false negative rate, AUC, etc.
- Other metrics should also be considered for ensuring a robust evaluation and these can be stored here in a JSON format.
- Information on the R or Python version, of packages used, of seeds, and more should also be stored in a JSON for audit, debugging, and reproducibility purposes

To help people publish models from different capabilities (see Note 2), there is an [`upsert_model`](MSSQL_ML_ELF/Stored%20Procedures/ml.upsert_model.sql) stored procedure that takes the relevant information required as inputs and will handle inserting the model if a new name is provided or updating the model if the name already exists.

### `[prediction]`
**Store the results of any prediction request here with information about how the result was derived**

The [`[prediction]`](MSSQL_ML_ELF/Tables/ml.prediction.sql) table is designed as a flexible log store for results of prediction workloads. You can directly add predictions etc to other tables instead of or as well as this table. 

The table contains columns for storing:
- A numeric and/or string prediction value
- A JSON representation of all the features and their associated values used in deriving the prediction. This is important as not all the features may be sent to the prediction stored procedure and wiull be generated inside the process. (see Note 1)
- A JSON representation of any extra information you think prudent to include like time to make a prediction, any warning outputs, session information 

To make it easier to implement prediction logging, there is an [`insert_prediction`](MSSQL_ML_ELF/Stored%20Procedures/ml.insert_prediction.sql) stored procedure to facilitate stored procedure development.

### `[prediction_log]`
**Track prediction requests**

The [`[prediction_log]`](MSSQL_ML_ELF/Tables/ml.prediction_log.sql) table is for storing prediction requests and associating them with any errors or batch of inserted predictions.

The table contains columns for storing:
- The ID of the model used to fulfil a prediction request
- Where the predictions were written to
- What the first and last IDs were for the predicted values, enabling you to retrieve values in that range. (see Note 3)
- When the prediction process was first kicked off
- If the prediction process finished successfully or errored gracefully when the process ended
- The error message(s) that were encountered during the prediction process

This log table should be useful for assessing prediction workload patterns, tying back predictions to requests, and tracking problems with the the request process. 

To facilitate use of the log table, two stored procedures have been created to ease prediction stored procedure development and reduce code duplication. The [`begin_prediction_log`](MSSQL_ML_ELF/Stored%20Procedures/ml.begin_prediction_log.sql) and [`end_prediction_log`](MSSQL_ML_ELF/Stored%20Procedures/ml.end_prediction_log.sql) can top and tail prediction processes.
   

## General
### Compatibility
As this is intended to surround the ML Services components, you can only deploy to 2016 and beyond but due to the merging nature of the feature set in SQL Server, the version you have determines the variety of workloads and languages you will be able to deploy. 

- SQL Server 2016
    + R model training and predictions
- SQL Server 2017
    + Windows: R and Python model training and predictions
    + Linux: Microsoft rx* models in R and Python can be stored and used for predictions
- SQL Server 2019
    + Windows: R, Python, and Spark model training and predictions
     + Windows: R, Python, and Spark model training and predictions
- Azure SQL DB
    + R model training and predictions

### Notes
1. GDPR requires us to be able to tell people how we arrived at a decision so we need to be able to retrieve models and values from different points in time.
2. From experience, we recommend using the ODBC drivers for interacting with SQL Server from R rather than the Windows native `SQL Server` driver as varbinary representations of models can have problems being transported to the DB using this driver.
3. I have structured things to work on the basis that either single predictions or batches of predictions will be made with consecutive IDs. This means if you do batches of say a 1000 customers at a time, that I'm expecting IDs 1-1000 first, then 1001-2000 and so on rather some other selection mechanism for batching customers.
