CREATE OR REPLACE FUNCTION logidze_logger() RETURNS TRIGGER AS $body$
  -- version: 3
  DECLARE
    updated_record RECORD;
  BEGIN

    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
      updated_record := logidze_generate_log_data(NEW, OLD, TG_OP, TG_ARGV);

      IF updated_record.log_data::text IS DISTINCT FROM NEW.log_data::text THEN
        NEW.log_data := updated_record.log_data;
      END if;
    END IF;

    RETURN NEW;
  END;
$body$
LANGUAGE plpgsql;
