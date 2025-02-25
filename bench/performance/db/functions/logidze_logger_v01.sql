-- version: 1
CREATE OR REPLACE FUNCTION logidze_logger() RETURNS TRIGGER AS $body$
  DECLARE
    changes jsonb;
    version jsonb;
    full_snapshot boolean;
    log_data jsonb;
    new_v integer;
    size integer;
    history_limit integer;
    debounce_time integer;
    current_version integer;
    k text;
    iterator integer;
    item record;
    columns text[];
    include_columns boolean;
    detached_log_data jsonb;
    -- We use `detached_loggable_type` for:
    -- 1. Checking if current implementation is `--detached` (`log_data` is stored in a separated table)
    -- 2. If implementation is `--detached` then we use detached_loggable_type to determine
    --    to which table current `log_data` record belongs
    detached_loggable_type text;
    log_data_table_name text;
    log_data_is_empty boolean;
    log_data_ts_key_data text;
    ts timestamp with time zone;
    ts_column text;
    err_sqlstate text;
    err_message text;
    err_detail text;
    err_hint text;
    err_context text;
    err_table_name text;
    err_schema_name text;
    err_jsonb jsonb;
    err_captured boolean;
  BEGIN
    ts_column := NULLIF(TG_ARGV[1], 'null');
    columns := NULLIF(TG_ARGV[2], 'null');
    include_columns := NULLIF(TG_ARGV[3], 'null');
    detached_loggable_type := NULLIF(TG_ARGV[5], 'null');
    log_data_table_name := NULLIF(TG_ARGV[6], 'null');

    -- getting previous log_data if it exists for detached `log_data` storage variant
    IF detached_loggable_type IS NOT NULL
    THEN
      EXECUTE format(
        'SELECT ldtn.log_data ' ||
        'FROM %I ldtn ' ||
        'WHERE ldtn.loggable_type = $1 ' ||
          'AND ldtn.loggable_id = $2 '  ||
        'LIMIT 1',
        log_data_table_name
      ) USING detached_loggable_type, NEW.id INTO detached_log_data;
    END IF;

    IF detached_loggable_type IS NULL
    THEN
        log_data_is_empty = NEW.log_data is NULL OR NEW.log_data = '{}'::jsonb;
    ELSE
        log_data_is_empty = detached_log_data IS NULL OR detached_log_data = '{}'::jsonb;
    END IF;

    IF log_data_is_empty
    THEN
      IF columns IS NOT NULL THEN
        log_data = logidze_snapshot(to_jsonb(NEW.*), ts_column, columns, include_columns);
      ELSE
        log_data = logidze_snapshot(to_jsonb(NEW.*), ts_column);
      END IF;

      IF log_data#>>'{h, -1, c}' != '{}' THEN
        IF detached_loggable_type IS NULL
        THEN
          NEW.log_data := log_data;
        ELSE
          EXECUTE format(
            'INSERT INTO %I(log_data, loggable_type, loggable_id) ' ||
            'VALUES ($1, $2, $3);',
            log_data_table_name
          ) USING log_data, detached_loggable_type, NEW.id;
        END IF;
      END IF;

    ELSE

      IF TG_OP = 'UPDATE' AND (to_jsonb(NEW.*) = to_jsonb(OLD.*)) THEN
        RETURN NEW; -- pass
      END IF;

      history_limit := NULLIF(TG_ARGV[0], 'null');
      debounce_time := NULLIF(TG_ARGV[4], 'null');

      IF detached_loggable_type IS NULL
      THEN
          log_data := NEW.log_data;
      ELSE
          log_data := detached_log_data;
      END IF;

      current_version := (log_data->>'v')::int;

      IF ts_column IS NULL THEN
        ts := statement_timestamp();
      ELSEIF TG_OP = 'UPDATE' THEN
        ts := (to_jsonb(NEW.*) ->> ts_column)::timestamp with time zone;
        IF ts IS NULL OR ts = (to_jsonb(OLD.*) ->> ts_column)::timestamp with time zone THEN
          ts := statement_timestamp();
        END IF;
      ELSEIF TG_OP = 'INSERT' THEN
        ts := (to_jsonb(NEW.*) ->> ts_column)::timestamp with time zone;

        IF detached_loggable_type IS NULL
        THEN
          log_data_ts_key_data = NEW.log_data #>> '{h,-1,ts}';
        ELSE
          log_data_ts_key_data = detached_log_data #>> '{h,-1,ts}';
        END IF;

        IF ts IS NULL OR (extract(epoch from ts) * 1000)::bigint = log_data_ts_key_data::bigint THEN
            ts := statement_timestamp();
        END IF;
      END IF;

      full_snapshot := (coalesce(current_setting('logidze.full_snapshot', true), '') = 'on') OR (TG_OP = 'INSERT');

      IF current_version < (log_data#>>'{h,-1,v}')::int THEN
        iterator := 0;
        FOR item in SELECT * FROM jsonb_array_elements(log_data->'h')
        LOOP
          IF (item.value->>'v')::int > current_version THEN
            log_data := jsonb_set(
              log_data,
              '{h}',
              (log_data->'h') - iterator
            );
          END IF;
          iterator := iterator + 1;
        END LOOP;
      END IF;

      changes := '{}';

      IF full_snapshot THEN
        BEGIN
          changes = hstore_to_jsonb_loose(hstore(NEW.*));
        EXCEPTION
          WHEN NUMERIC_VALUE_OUT_OF_RANGE THEN
            changes = row_to_json(NEW.*)::jsonb;
            FOR k IN (SELECT key FROM jsonb_each(changes))
            LOOP
              IF jsonb_typeof(changes->k) = 'object' THEN
                changes = jsonb_set(changes, ARRAY[k], to_jsonb(changes->>k));
              END IF;
            END LOOP;
        END;
      ELSE
        BEGIN
          changes = hstore_to_jsonb_loose(
                hstore(NEW.*) - hstore(OLD.*)
            );
        EXCEPTION
          WHEN NUMERIC_VALUE_OUT_OF_RANGE THEN
            changes = (SELECT
              COALESCE(json_object_agg(key, value), '{}')::jsonb
              FROM
              jsonb_each(row_to_json(NEW.*)::jsonb)
              WHERE NOT jsonb_build_object(key, value) <@ row_to_json(OLD.*)::jsonb);
            FOR k IN (SELECT key FROM jsonb_each(changes))
            LOOP
              IF jsonb_typeof(changes->k) = 'object' THEN
                changes = jsonb_set(changes, ARRAY[k], to_jsonb(changes->>k));
              END IF;
            END LOOP;
        END;
      END IF;

      -- We store `log_data` in a separate table for the `detached` mode
      -- So we remove `log_data` only when we store historic data in the record's origin table
      IF detached_loggable_type IS NULL
      THEN
          changes = changes - 'log_data';
      END IF;

      IF columns IS NOT NULL THEN
        changes = logidze_filter_keys(changes, columns, include_columns);
      END IF;

      IF changes = '{}' THEN
        RETURN NEW; -- pass
      END IF;

      new_v := (log_data#>>'{h,-1,v}')::int + 1;

      size := jsonb_array_length(log_data->'h');
      version := logidze_version(new_v, changes, ts);

      IF (
        debounce_time IS NOT NULL AND
        (version->>'ts')::bigint - (log_data#>'{h,-1,ts}')::text::bigint <= debounce_time
      ) THEN
        -- merge new version with the previous one
        new_v := (log_data#>>'{h,-1,v}')::int;
        version := logidze_version(new_v, (log_data#>'{h,-1,c}')::jsonb || changes, ts);
        -- remove the previous version from log
        log_data := jsonb_set(
          log_data,
          '{h}',
          (log_data->'h') - (size - 1)
        );
      END IF;

      log_data := jsonb_set(
        log_data,
        ARRAY['h', size::text],
        version,
        true
      );

      log_data := jsonb_set(
        log_data,
        '{v}',
        to_jsonb(new_v)
      );

      IF history_limit IS NOT NULL AND history_limit <= size THEN
        log_data := logidze_compact_history(log_data, size - history_limit + 1);
      END IF;

      IF detached_loggable_type IS NULL
      THEN
        NEW.log_data := log_data;
      ELSE
        detached_log_data = log_data;
        EXECUTE format(
          'UPDATE %I ' ||
          'SET log_data = $1 ' ||
          'WHERE %I.loggable_type = $2 ' ||
          'AND %I.loggable_id = $3',
          log_data_table_name,
          log_data_table_name,
          log_data_table_name
        ) USING detached_log_data, detached_loggable_type, NEW.id;
      END IF;
    END IF;

    RETURN NEW; -- result
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS err_sqlstate = RETURNED_SQLSTATE,
                              err_message = MESSAGE_TEXT,
                              err_detail = PG_EXCEPTION_DETAIL,
                              err_hint = PG_EXCEPTION_HINT,
                              err_context = PG_EXCEPTION_CONTEXT,
                              err_schema_name = SCHEMA_NAME,
                              err_table_name = TABLE_NAME;
      err_jsonb := jsonb_build_object(
        'returned_sqlstate', err_sqlstate,
        'message_text', err_message,
        'pg_exception_detail', err_detail,
        'pg_exception_hint', err_hint,
        'pg_exception_context', err_context,
        'schema_name', err_schema_name,
        'table_name', err_table_name
      );
      err_captured = logidze_capture_exception(err_jsonb);
      IF err_captured THEN
        return NEW;
      ELSE
        RAISE;
      END IF;
  END;
$body$
LANGUAGE plpgsql;
