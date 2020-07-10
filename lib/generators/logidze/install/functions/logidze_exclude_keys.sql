CREATE OR REPLACE FUNCTION logidze_exclude_keys(obj jsonb, VARIADIC keys text[]) RETURNS jsonb AS $body$
  DECLARE
    res jsonb;
    key text;
  BEGIN
    res := obj;
    FOREACH key IN ARRAY keys
    LOOP
      res := res - key;
    END LOOP;
    RETURN res;
  END;
$body$
LANGUAGE plpgsql;
