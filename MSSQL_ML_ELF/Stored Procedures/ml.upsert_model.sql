CREATE PROCEDURE [ml].[upsert_model]
  @name  NVARCHAR(50) 
, @model VARBINARY(max) 
, @training_n INT = NULL
, @test_n INT = NULL
, @key_metric VARCHAR(50) = NULL
, @key_metric_val DECIMAL(10,10) = NULL
, @metrics VARCHAR(MAX) = NULL
, @info VARCHAR(MAX) = NULL

AS
WITH MySource as (
    SELECT
	  @name           AS [name] 
	, @model          AS [model]
	, @training_n     AS [training_observations]
	, @test_n         AS [test_observations]
	, @key_metric     AS [key_metric]
	, @key_metric_val AS [key_metric_value]
	, @metrics        as [metrics]
	, @info           AS [info]
)
MERGE [ml].[model] AS MyTarget
USING MySource
     ON MySource.[name] = MyTarget.[name]
WHEN MATCHED THEN UPDATE SET 
      [model]                 = MySource.[model]
	, [training_observations] = MySource.[training_observations]
	, [test_observations]	  = MySource.[test_observations]
	, [key_metric]			  = MySource.[key_metric]
	, [key_metric_value]	  = MySource.[key_metric_value]
	, [metrics]				  = MySource.[metrics]
	, [info]				  = MySource.[info]
WHEN NOT MATCHED THEN INSERT
    (
	  [name] 
	, [model]
	, [training_observations]
	, [test_observations]
	, [key_metric]
	, [key_metric_value]
	, [metrics]
	, [info]
    )
    VALUES (
	  MySource.[name] 
	, MySource.[model]
	, MySource.[training_observations]
	, MySource.[test_observations]
	, MySource.[key_metric]
	, MySource.[key_metric_value]
	, MySource.[metrics]
	, MySource.[info]
    );