CREATE TRIGGER logidze_on_<%= table_name %>
BEFORE UPDATE OR INSERT ON <%= table_name %> FOR EACH ROW
WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on')
-- Parameters: history_size_limit (integer), timestamp_column (text), filtered_columns (text[]),
-- include_columns (boolean), debounce_time_ms (integer)
EXECUTE PROCEDURE logidze_logger(<%= logidze_logger_parameters %>);
