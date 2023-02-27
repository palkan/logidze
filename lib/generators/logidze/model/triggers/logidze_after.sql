CREATE TRIGGER <%= %Q("logidze_on_#{full_table_name}") %>
AFTER UPDATE OR INSERT ON <%= %Q("#{full_table_name}") %> FOR EACH ROW
WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on' AND pg_trigger_depth() < 1)
-- Parameters: history_size_limit (integer), timestamp_column (text), filtered_columns (text[]),
-- include_columns (boolean), debounce_time_ms (integer)
EXECUTE PROCEDURE logidze_logger_after(<%= logidze_logger_parameters %>);
