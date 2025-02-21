CREATE OR REPLACE FUNCTION logidze_logger_after() RETURNS TRIGGER AS $body$
  -- version: 5
<%= generate_logidze_logger_after %>
