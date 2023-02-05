CREATE OR REPLACE FUNCTION logidze_logger_after() RETURNS TRIGGER AS $body$
  -- version: 1
  DECLARE
    primary_keys text[];
    updated_record RECORD;
  BEGIN
    IF pg_trigger_depth() > 1 THEN
      RETURN NULL;
    END IF;

    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
      updated_record := logidze_generate_log_data(NEW, OLD, TG_OP, TG_ARGV);
      primary_keys := logidze_fetch_primary_keys(TG_TABLE_NAME);

      IF updated_record.log_data::text IS DISTINCT FROM NEW.log_data::text THEN
        PERFORM logidze_update_record_log_data(TG_TABLE_NAME, to_jsonb(updated_record.*), primary_keys);
      END IF;
    END IF;

    RETURN NULL;
  END;
$body$
LANGUAGE plpgsql;
