CREATE TABLE [ml].[prediction]
(
	[id] BIGINT NOT NULL PRIMARY KEY IDENTITY, 
    [numeric_prediction] FLOAT NULL, 
    [string_prediction] NVARCHAR(50) NULL, 
    [features] VARCHAR(MAX) NULL, 
    [extra] VARCHAR(MAX) NULL,
    CONSTRAINT [CK_prediction_features] CHECK (ISJSON([features])=1), 
    CONSTRAINT [CK_prediction_extra] CHECK (ISJSON([extra])=1), 
)