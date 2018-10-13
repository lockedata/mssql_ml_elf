CREATE PROCEDURE [ml].[end_prediction_log]
	@log_id int,
	@earliest_destination_id BIGINT = NULL,
	@latest_destination_id BIGINT = NULL,
	@errors VARCHAR(MAX) = NULL
AS
	UPDATE [ml].prediction_log

	SET 
	  earliest_destination_id = @earliest_destination_id
	, latest_destination_id = @latest_destination_id
	, [end] = SYSUTCDATETIME()
	, errors = @errors

	WHERE
	id = @log_id

RETURN 0
