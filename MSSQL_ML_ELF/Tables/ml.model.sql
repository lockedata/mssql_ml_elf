CREATE TABLE [ml].[model]
(
	[id] INT NOT NULL PRIMARY KEY IDENTITY,
    [name] NVARCHAR(50) NOT NULL,
    [model] varbinary(max) NOT NULL,
	[training_observations] INT,
	[test_observations] INT,
	[key_metric] VARCHAR(50),
	[key_metric_value] DECIMAL(10,10),
	[metrics] VARCHAR(MAX),
	[info] VARCHAR(MAX),
	[SysStart] DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
	[SysEnd] DATETIME2 (7) GENERATED ALWAYS AS ROW END NOT NULL, 
    CONSTRAINT [CK_model_name] UNIQUE ([name]), 
    CONSTRAINT [CK_model_metrics] CHECK (ISJSON([metrics])=1), 
    CONSTRAINT [CK_model_info] CHECK (ISJSON([info])=1), 
	PERIOD FOR SYSTEM_TIME ([SysStart], [SysEnd])
)
WITH (SYSTEM_VERSIONING = ON(HISTORY_TABLE=[ml].[model_HISTORY], DATA_CONSISTENCY_CHECK=ON))
