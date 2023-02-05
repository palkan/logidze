CREATE OR REPLACE FUNCTION logidze_fetch_primary_keys(table_name text) RETURNS text[] AS $body$
  -- version: 1
  DECLARE
     res text[];
  BEGIN
    SELECT array_agg(a.attname)
    INTO res
    FROM   pg_index i
    JOIN   pg_attribute a ON a.attrelid = i.indrelid
                         AND a.attnum = ANY(i.indkey)
    WHERE  i.indrelid = table_name::regclass
    AND    i.indisprimary;

    RETURN res;
  END;
$body$
LANGUAGE plpgsql;
