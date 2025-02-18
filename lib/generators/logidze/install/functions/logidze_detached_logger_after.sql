CREATE OR REPLACE FUNCTION logidze_detached_logger_after() RETURNS TRIGGER AS $body$
  -- version: 1
<%= generate_logidze_detached_logger_after %>
