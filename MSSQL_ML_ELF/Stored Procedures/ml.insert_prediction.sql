CREATE PROCEDURE [ml].[insert_prediction]
	@numeric_prediction float = NULL,
	@string_prediction NVARCHAR(50) = NULL,
	@features VARCHAR(MAX) = NULL,
	@extra VARCHAR(MAX) = NULL
AS
	INSERT INTO [ml].[prediction] (
	  numeric_prediction
	, string_prediction
	, features
	, extra)
	VALUES (
	  @numeric_prediction
	, @string_prediction
	, @features
	, @extra)

RETURN SCOPE_IDENTITY()
