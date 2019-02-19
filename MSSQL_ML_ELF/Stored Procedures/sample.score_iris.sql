CREATE PROCEDURE [sample].[score_iris]
	@sql NVARCHAR(MAX) = 'SELECT 1'
	,@fe_name VARCHAR(50) = 'iris_FE'
   , @ml_name VARCHAR(50) = 'iris_Cluster'
AS

	DECLARE @fe_model varbinary(max) = (
	  SELECT [model]
	  FROM [ml].[model]
	  WHERE [name] = @fe_name);

	  PRINT 'FE Model '+@fe_name+' found';

	DECLARE @ml_model varbinary(max) = (
	  SELECT [model]
	  FROM [ml].[model]
	  WHERE [name] = @ml_name);

	  PRINT 'ML Model '+@ml_name+' found';

	DECLARE @modelid varchar(250) = (
	  SELECT [id]
	  FROM [ml].[model]
	  WHERE [name] = @ml_name);

	  PRINT 'ML Model ID is '+@modelid;

	DECLARE @logid BIGINT 

	EXECUTE @logid = [ml].begin_prediction_log
	@model_id = @modelid
	, @destination_table = '[ml].[prediction]';

	PRINT 'Log ID is '+@modelid;

	DECLARE @IDList TABLE(ID INT); 

	BEGIN TRY 

	CREATE TABLE #tmp ([numeric_prediction] FLOAT, [features] VARCHAR(MAX))
    PRINT 'Temp table created';

	INSERT INTO #tmp
	EXECUTE sp_execute_external_script
	@language = N'R'
	, @script = N'
		suppressMessages(library(purrr))
		suppressMessages(library(recipes))
		suppressMessages(library(jsonlite))

		# handle inputs
		fe_model = unserialize(femodel)
		# Use some in-situ data if we dont send any data
		if(nrow(InputDataSet) == 0 ) InputDataSet <- iris

		df = InputDataSet
		df_clean = bake(fe_model, df)
		ml_model = unserialize(mlmodel)$centers
        pred=kmeans(df_clean, centers = ml_model)$cluster
        features=map_chr(pmap(df_clean, list), toJSON)
    
		OutputDataSet = data.frame(
		  numeric_prediction =pred,
		  features=features
		)
	'
	, @input_data_1 = @sql
    , @params = N'
		 @femodel VARBINARY(MAX)
	   , @mlmodel VARBINARY(MAX)'
    , @femodel = @fe_model
	, @mlmodel = @ml_model;

	DECLARE @tmprowcount VARCHAR(20) = (SELECT CAST(COUNT(*)  AS VARCHAR(20)) FROM #tmp);
	PRINT 'Rows generated is '+ @tmprowcount;
	
	INSERT INTO [ml].[prediction] (
	[numeric_prediction], 
	[features])
	OUTPUT INSERTED.id INTO @IDList(ID)
	SELECT * FROM #tmp

	DECLARE @idlistrowcount VARCHAR(20) = (SELECT CAST(COUNT(*) AS VARCHAR(20)) FROM @IDList)
	PRINT 'Rows added to predictions are '+ @idlistrowcount;

	DECLARE @smallest VARCHAR(20) = (SELECT CAST(min(ID) AS VARCHAR(20)) from @IDList);
	DECLARE @largest  VARCHAR(20) = (SELECT CAST(MAX(ID) AS VARCHAR(20)) from @IDList);

	PRINT 'ID range is '+ @smallest + 'to ' + @largest;

	EXECUTE [ml].[end_prediction_log]
	@log_id = @logid
	, @earliest_destination_id = @smallest
	, @latest_destination_id = @largest

	PRINT 'Log ended'
	END TRY
	BEGIN CATCH
	DECLARE @error VARCHAR(MAX) = (SELECT CONCAT(
				ERROR_NUMBER(), '-|-'
				,ERROR_MESSAGE(), '-|-'	
				))

	EXECUTE [ml].[end_prediction_log]
	@log_id = @logid
	, @errors = @error

	PRINT 'Error logged'

	END CATCH

	PRINT 'Execution finished'

	SELECT p.* 
	FROM [ml].[prediction] p
	INNER JOIN @IDList i ON p.id=i.ID

RETURN 0
