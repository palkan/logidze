-- version: 1
CREATE OR REPLACE FUNCTION logidze_filter_keys(obj jsonb, keys text[], include_columns boolean DEFAULT false) RETURNS jsonb AS $body$
  DECLARE
    res jsonb;
    key text;
  BEGIN
    IF include_columns THEN
      res := '{}';
      FOREACH key IN ARRAY keys
      LOOP
        res := jsonb_insert(res, ARRAY[key], obj->key);
      END LOOP;
    ELSE
      res := obj;
      FOREACH key IN ARRAY keys
      LOOP
        res := res - key;
      END LOOP;
    END IF;

    RETURN res;
  END;
$body$
LANGUAGE plpgsql;
