CREATE TRIGGER <%= %Q("logidze_detached_on_#{full_table_name}") %>
BEFORE UPDATE OR INSERT ON <%= %Q("#{full_table_name}") %> FOR EACH ROW
WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on')
-- Parameters: history_size_limit (integer), timestamp_column (text), filtered_columns (text[]),
-- include_columns (boolean), debounce_time_ms (integer), detached_loggable_type(text)
EXECUTE PROCEDURE logidze_detached_logger(<%= logidze_detached_logger_parameters %>);
