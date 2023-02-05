CREATE OR REPLACE FUNCTION logidze_update_record_log_data(table_name text, obj jsonb, primary_keys text[]) RETURNS void AS $body$
  -- version: 1
  DECLARE
    condition text;
    res text[];
    key text;
  BEGIN
    res := '{}';

    FOREACH key IN ARRAY primary_keys
    LOOP
      IF obj ? key THEN
        res := array_append(res, quote_ident(key) || ' = ' || quote_literal(obj->key));
      END IF;
    END LOOP;

    condition := array_to_string(res, ' AND ');

    EXECUTE format('UPDATE %I SET "log_data" = $1 WHERE ' || condition, table_name) USING obj->'log_data';
  END;
$body$
LANGUAGE plpgsql;
