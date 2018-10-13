CREATE PROCEDURE upsert_model
@name  varchar(50) , 
@model varbinary(max) 
AS
WITH MySource as (
    select @name as [name], @model as [model]
)
MERGE [model] AS MyTarget
USING MySource
     ON MySource.[name] = MyTarget.[name]
WHEN MATCHED THEN UPDATE SET 
    [model] = MySource.[model]
WHEN NOT MATCHED THEN INSERT
    (
        [name], 
        [model]
    )
    VALUES (
        MySource.[name], 
        MySource.[model]
    );