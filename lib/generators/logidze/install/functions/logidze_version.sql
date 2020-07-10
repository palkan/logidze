CREATE OR REPLACE FUNCTION logidze_version(v bigint, data jsonb, ts timestamp with time zone, blacklist text[] DEFAULT '{}') RETURNS jsonb AS $body$
  DECLARE
    buf jsonb;
  BEGIN
    buf := jsonb_build_object(
              'ts',
              (extract(epoch from ts) * 1000)::bigint,
              'v',
              v,
              'c',
              logidze_exclude_keys(data, VARIADIC array_append(blacklist, 'log_data'))
              );
    IF coalesce(current_setting('logidze.meta', true), '') <> '' THEN
      buf := jsonb_insert(buf, '{m}', current_setting('logidze.meta')::jsonb);
    END IF;
    RETURN buf;
  END;
$body$
LANGUAGE plpgsql;
