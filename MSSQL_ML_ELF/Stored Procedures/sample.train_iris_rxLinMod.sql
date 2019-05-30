CREATE PROCEDURE [sample].[train_iris_rxLinMod]
 @ml_name VARCHAR(50) = 'train_iris_rxLindMod'
AS
	-- Variables output by training process
	DECLARE 
		 @fe_model VARBINARY(MAX)
	   , @ml_model VARBINARY(MAX)
	   , @n_train INT
	   , @n_test int
	   , @key_metric VARCHAR(50)
	   , @key_metric_val FLOAT
	   , @metrics VARCHAR(MAX)
	   , @info VARCHAR(MAX)

    -- Training process
	EXECUTE sp_execute_external_script
	@language = N'R'
	, @script = N'
		# Load R packages for use
		library("dplyr")
		library("rsample")
		library("jsonlite")
		library("sessioninfo")
		# Sample data
		sm_iris = initial_split(iris)
		train   = training(sm_iris)
		test    = testing(iris)
		# Assign our volumes to our output params
		ntrain = nrow(train)
		ntest  = nrow(test)
		# Build model
		linm = rxLinMod(Sepal.Length~Petal.Length, train)
		# Predict on test data & Generate output
		OutputDataSet = cbind(test, rxPredict(linm, test))
		# Prepare quality measures
		keymetric = "r.squared"
		keymetricval = linm$r.squared
		# Info
		inf = toJSON(package_info())
		# Convert models for output
		mlmodel = rxSerializeModel(linm)
	'
	, @input_data_1 = N'SELECT 1'
    , @params = N'
		 @mlmodel VARBINARY(MAX) OUTPUT
	   , @ntrain int OUTPUT
	   , @ntest int OUTPUT
	   , @keymetric VARCHAR(50) OUTPUT
	   , @keymetricval FLOAT OUTPUT
	   , @inf VARCHAR(MAX)  OUTPUT'
	, @mlmodel = @ml_model OUTPUT
    , @ntrain = @n_train OUTPUT
	, @ntest = @n_test OUTPUT
	, @keymetric = @key_metric OUTPUT
	, @keymetricval = @key_metric_val OUTPUT
	, @inf = @info OUTPUT 

	-- Save ML model for use
	EXEC [ml].[upsert_model]   @name = @ml_name
		, @model = @ml_model
		, @training_n = @n_train
		, @test_n = @n_test
		, @key_metric = @key_metric
		, @key_metric_val = @key_metric_val
		, @metrics = @metrics
		, @info = @info


RETURN 0
