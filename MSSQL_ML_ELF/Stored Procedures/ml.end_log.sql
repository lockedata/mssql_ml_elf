CREATE PROCEDURE [ml].[end_log]
	@log_id int,
	@destination_id INT = NULL,
	@errors VARCHAR(MAX) = NULL
AS
	UPDATE [ml].prediction_log

	SET 
	  destination_id = @destination_id
	, [end] = SYSUTCDATETIME()
	, errors = @errors

	WHERE
	id = @log_id

RETURN 0
