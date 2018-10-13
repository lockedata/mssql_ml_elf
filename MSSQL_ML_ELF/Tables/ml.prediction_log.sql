CREATE TABLE [ml].[prediction_log]
(
	[id] BIGINT NOT NULL PRIMARY KEY, 
	[model_id] INT,
    [destination_table] NVARCHAR(126) NULL, 
    [earliest_destination_id] BIGINT NULL, 
    [latest_destination_id] BIGINT NULL, 
    [start] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), 
    [end] DATETIME2 NULL, 
    [errors] VARCHAR(MAX) NULL, 
    CONSTRAINT [FK_prediction_log_model] FOREIGN KEY ([model_id]) REFERENCES [ml].[model]([id])
)
