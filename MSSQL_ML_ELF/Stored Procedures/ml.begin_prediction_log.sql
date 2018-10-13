CREATE PROCEDURE [ml].[begin_prediction_log]
	@model_id int,
	@destination_table INT = "[ml].[prediction]"
AS
	INSERT INTO [ml].prediction_log (model_id, destination_table)
	VALUES(@model_id, @destination_table)

RETURN SCOPE_IDENTITY()
