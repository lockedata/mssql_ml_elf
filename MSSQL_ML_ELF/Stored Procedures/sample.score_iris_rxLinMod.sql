CREATE PROCEDURE [sample].[score_iris_rxLinMod]
 @ml_name VARCHAR(50) = 'iris_rxLinMod'
AS

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

	CREATE TABLE #tmp ([numeric_prediction] FLOAT)
	CREATE TABLE #iris ([Petal.Length] FLOAT, [Sepal.Length] FLOAT)
    PRINT 'Temp table created';

	INSERT INTO #iris
    SELECT 1.1 as [Petal.Length], 4.4 as [Sepal.Length]

    INSERT INTO #tmp
    SELECT p.*
    FROM PREDICT(MODEL = @ml_model, DATA = #iris as i)
    WITH("Sepal.Length_Pred" float) as p;
	

	DECLARE @tmprowcount VARCHAR(20) = (SELECT CAST(COUNT(*)  AS VARCHAR(20)) FROM #tmp);
	PRINT 'Rows generated is '+ @tmprowcount;
	
	INSERT INTO [ml].[prediction] (
	[numeric_prediction])
	OUTPUT INSERTED.id INTO @IDList(ID)
	SELECT [numeric_prediction] FROM #tmp

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
