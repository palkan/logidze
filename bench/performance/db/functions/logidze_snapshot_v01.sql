-- version: 1
CREATE OR REPLACE FUNCTION logidze_snapshot(item jsonb, ts_column text DEFAULT NULL, columns text[] DEFAULT NULL, include_columns boolean DEFAULT false) RETURNS jsonb AS $body$
  DECLARE
    ts timestamp with time zone;
  BEGIN
    IF ts_column IS NULL THEN
      ts := statement_timestamp();
    ELSE
      ts := coalesce((item->>ts_column)::timestamp with time zone, statement_timestamp());
    END IF;

    IF columns IS NOT NULL THEN
      item := logidze_filter_keys(item, columns, include_columns);
    END IF;

    return json_build_object(
      'v', 1,
      'h', jsonb_build_array(
              logidze_version(1, item, ts)
            )
      );
  END;
$body$
LANGUAGE plpgsql;
