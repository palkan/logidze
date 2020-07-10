CREATE TRIGGER logidze_on_<%= table_name %>
BEFORE UPDATE OR INSERT ON <%= table_name %> FOR EACH ROW
WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on')
EXECUTE PROCEDURE logidze_logger(<%= logidze_logger_parameters %>);
