CREATE OR REPLACE FUNCTION logidze_logger_after() RETURNS TRIGGER AS $body$
  -- version: 4
<%= generate_logidze_logger_after %>
