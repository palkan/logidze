CREATE TRIGGER "logidze_detached_on_logidze_detached_users"
BEFORE UPDATE OR INSERT ON "logidze_detached_users" FOR EACH ROW
WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on')
-- Parameters: history_size_limit (integer), timestamp_column (text), filtered_columns (text[]),
-- include_columns (boolean), debounce_time_ms (integer), detached_loggable_type(text)
EXECUTE PROCEDURE logidze_detached_logger(null, 'updated_at', null, null, null, 'LogidzeDetachedUser');
