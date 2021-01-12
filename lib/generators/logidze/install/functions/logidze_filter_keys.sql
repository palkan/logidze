CREATE OR REPLACE FUNCTION logidze_filter_keys(obj jsonb, keys text[], include_columns boolean DEFAULT false) RETURNS jsonb AS $body$
  -- version: 1
  DECLARE
    res jsonb;
    key text;
  BEGIN
    res := '{}';

    IF include_columns THEN
      FOREACH key IN ARRAY keys
      LOOP
        IF obj ? key THEN
          res = jsonb_insert(res, ARRAY[key], obj->key);
        END IF;
      END LOOP;
    ELSE
      res = obj;
      FOREACH key IN ARRAY keys
      LOOP
        res = res - key;
      END LOOP;
    END IF;

    RETURN res;
  END;
$body$
LANGUAGE plpgsql;
