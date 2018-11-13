CREATE PROCEDURE [sample].[score_iris]
	@sql NVARCHAR(MAX) = 'SELECT 1'
AS

	DECLARE @fe_model varbinary(max) = (
	  SELECT [model]
	  FROM [ml].[model]
	  WHERE [name] = 'iris_FE');

	DECLARE @ml_model varbinary(max) = (
	  SELECT [model]
	  FROM [ml].[model]
	  WHERE [name] = 'iris_Clustering');

	DECLARE @modelid int = (
	  SELECT [id]
	  FROM [ml].[model]
	  WHERE [name] = 'iris_Clustering');

	DECLARE @logid BIGINT 

	EXECUTE @logid = [ml].begin_prediction_log
	@model_id = @modelid
	, @destination_table = '[ml].[prediction]';

	DECLARE @IDList TABLE(ID INT); 

	BEGIN TRY 

	CREATE TABLE #tmp ([numeric_prediction] FLOAT, [features] VARCHAR(MAX))
    
	INSERT INTO #tmp
	EXECUTE sp_execute_external_script
	@language = N'R'
	, @script = N'
		library(purrr)
		library(recipes)
		library(jsonlite)

		# handle inputs
		fe_model = unserialize(as.raw(femodel))
		ml_model = unserialize(as.raw(mlmodel))

		# Use some in-situ data if we dont send any data
		if(nrow(InputDataSet) == 0 ) InputDataSet <- iris

		df = InputDataSet
		df_clean = bake(fe_model, df)

		OutputDataSet = cbind(
		  numeric_prediction=kmeans(df_clean, 
							 centers = ml_model$centers)$clusters,
		  features=map(pmap(df_clean, list), toJSON)
		)
	'
	, @input_data_1 = @sql
    , @params = N'
		 @femodel VARBINARY(MAX)
	   , @mlmodel VARBINARY(MAX)'
    , @femodel = @fe_model
	, @mlmodel = @ml_model
	
	INSERT INTO [ml].[prediction] (
	[numeric_prediction], 
	[features])
	OUTPUT INSERTED.id INTO @IDList(ID)
	SELECT * FROM #tmp

	DECLARE @smallest bigint = (SELECT min(ID) from @IDList);
	DECLARE @largest  bigint = (SELECT MAX(ID) from @IDList);

	EXECUTE [ml].[end_prediction_log]
	@log_id = @logid
	, @earliest_destination_id = @smallest
	, @latest_destination_id = @largest

	END TRY
	BEGIN CATCH
	DECLARE @error VARCHAR(MAX) = (SELECT CONCAT(
				ERROR_NUMBER(), '-|-'
				,ERROR_MESSAGE(), '-|-'	
				))

	EXECUTE [ml].[end_prediction_log]
	@log_id = @logid
	, @errors = @error
	END CATCH

	SELECT p.* 
	FROM [ml].[prediction] p
	INNER JOIN @IDList i ON p.id=i.ID

RETURN 0
