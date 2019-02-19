CREATE PROCEDURE [sample].[train_iris]
     @fe_name VARCHAR(50) = 'iris_FE'
   , @ml_name VARCHAR(50) = 'iris_Cluster'
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
		library("recipes")
		library("rsample")
		library("broom")
		library("jsonlite")
		library("sessioninfo")

		# Sample data
		sm_iris = initial_split(iris)
		train   = training(sm_iris)
		test    = testing(iris)

		# Assign our volumes to our output params
		ntrain = nrow(train)
		ntest  = nrow(test)

		# Feature engineering
		transform = recipe(train, ~.)

		transform %>% 
		  step_rm("Species") %>% 
		  step_scale(all_numeric()) ->
		  transform

		transform = prep(transform)

		# Prepare our data for modelling
		train_clean = bake(transform, train)
		test_clean = bake(transform, test)

		# Build model
		km = kmeans(train_clean, centers = 3)

		# Predict on test data
		test_scored = kmeans(test_clean, centers = km$centers)

		# Generate output
		OutputDataSet = cbind(test_clean, test_scored$cluster)

		# Prepare quality measures
		keymetric = "tot.withinss"
		keymetricval = test_scored$tot.withinss
		metric = toJSON(glance(test_scored))

		# Info
		inf = toJSON(package_info())

		# Convert models for output
		femodel = paste0(serialize(transform, NULL), collapse = "")
		mlmodel = paste0(serialize(km, NULL), collapse = "")

	'
	, @input_data_1 = N'SELECT 1'
    , @params = N'
		 @femodel VARBINARY(MAX) OUTPUT
	   , @mlmodel VARBINARY(MAX) OUTPUT
	   , @ntrain int OUTPUT
	   , @ntest int OUTPUT
	   , @keymetric VARCHAR(50) OUTPUT
	   , @keymetricval FLOAT OUTPUT
	   , @metric VARCHAR(MAX) OUTPUT
	   , @inf VARCHAR(MAX)  OUTPUT'
    , @femodel = @fe_model OUTPUT
	, @mlmodel = @ml_model OUTPUT
    , @ntrain = @n_train OUTPUT
	, @ntest = @n_test OUTPUT
	, @keymetric = @key_metric OUTPUT
	, @keymetricval = @key_metric_val OUTPUT
	, @metric =  @metrics OUTPUT
	, @inf = @info OUTPUT 

	-- Save data transformations for reuse
	EXEC [ml].[upsert_model]   @name = @fe_name
		, @model = @fe_model
		, @training_n = @n_train
		, @test_n = @n_test
		, @info = @info

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
