-- version: 1
CREATE OR REPLACE FUNCTION logidze_version(v bigint, data jsonb, ts timestamp with time zone) RETURNS jsonb AS $body$
  DECLARE
    buf jsonb;
  BEGIN
    buf := jsonb_build_object(
              'ts',
              (extract(epoch from ts) * 1000)::bigint,
              'v',
              v,
              'c',
              data
              );
    IF coalesce(current_setting('logidze.meta', true), '') <> '' THEN
      buf := jsonb_insert(buf, '{m}', current_setting('logidze.meta')::jsonb);
    END IF;
    RETURN buf;
  END;
$body$
LANGUAGE plpgsql;
