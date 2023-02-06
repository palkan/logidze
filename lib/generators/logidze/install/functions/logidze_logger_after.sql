CREATE OR REPLACE FUNCTION logidze_logger_after() RETURNS TRIGGER AS $body$
  -- version: 1
  DECLARE
    primary_keys text[];
    updated_record record;
  BEGIN
    IF pg_trigger_depth() > 1 THEN
      RETURN NULL;
    END IF;

    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
      updated_record := logidze_generate_log_data(NEW, OLD, TG_OP, TG_ARGV);

      IF updated_record.log_data::text IS DISTINCT FROM NEW.log_data::text THEN
        EXECUTE format('UPDATE %I SET "log_data" = $1 WHERE ctid = %L', TG_TABLE_NAME, NEW.CTID) USING updated_record.log_data;
      END IF;
    END IF;

    RETURN NULL;
  END;
$body$
LANGUAGE plpgsql;
