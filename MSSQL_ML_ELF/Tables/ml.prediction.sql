/*
The database must have a MEMORY_OPTIMIZED_DATA filegroup
before the memory optimized object can be created.

The bucket count should be set to about two times the 
maximum expected number of distinct values in the 
index key, rounded up to the nearest power of two.
*/

CREATE TABLE [ml].[prediction]
(
	[id] BIGINT NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 131072), 
    [numeric_prediction] FLOAT NULL, 
    [string_prediction] NVARCHAR(50) NULL, 
    [features] VARCHAR(MAX) NULL, 
    [extra] VARCHAR(MAX) NULL,
    CONSTRAINT [CK_prediction_features] CHECK (ISJSON([features])=1), 
    CONSTRAINT [CK_prediction_extra] CHECK (ISJSON([extra])=1), 
) WITH (MEMORY_OPTIMIZED = ON)