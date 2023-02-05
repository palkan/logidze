DO $$ DECLARE
  PG_VERSION_11 smallint := 11;
  PG_VERSION_12 smallint := 12;
  current_pg_version smallint := (substr(current_setting('server_version'), 1, 2)::smallint);
  is_partionared_table boolean := EXISTS(SELECT 1 FROM pg_catalog.pg_inherits WHERE inhparent = <%= %Q('#{full_table_name}') %>::regclass);
  BEGIN
    IF (current_pg_version BETWEEN PG_VERSION_11 AND PG_VERSION_12) AND is_partionared_table = TRUE THEN
      CREATE TRIGGER <%= %Q("logidze_on_#{full_table_name}") %>
      AFTER UPDATE OR INSERT ON <%= %Q("#{full_table_name}") %> FOR EACH ROW
      WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on')
      -- Parameters: history_size_limit (integer), timestamp_column (text), filtered_columns (text[]),
      -- include_columns (boolean), debounce_time_ms (integer)
      EXECUTE PROCEDURE logidze_logger_after(<%= logidze_logger_parameters %>);
    ELSE
      CREATE TRIGGER <%= %Q("logidze_on_#{full_table_name}") %>
      BEFORE UPDATE OR INSERT ON <%= %Q("#{full_table_name}") %> FOR EACH ROW
      WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on')
      -- Parameters: history_size_limit (integer), timestamp_column (text), filtered_columns (text[]),
      -- include_columns (boolean), debounce_time_ms (integer)
      EXECUTE PROCEDURE logidze_logger(<%= logidze_logger_parameters %>);
    END IF;
END $$;
