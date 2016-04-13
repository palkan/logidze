CREATE OR REPLACE FUNCTION keys_logger() RETURNS TRIGGER AS $body$
  DECLARE
    changes_h jsonb;
    size integer;
    old_j jsonb;
    new_j jsonb;
    item record;
  BEGIN
    size := jsonb_array_length(NEW.log);
    old_j := to_jsonb(OLD);
    new_j := to_jsonb(NEW);
    changes_h := '{}'::jsonb;

    FOR item in SELECT key as k, value as v FROM jsonb_each(new_j)
    LOOP
      IF item.v <> jsonb_extract_path(old_j, item.k) THEN
        changes_h := jsonb_set(
          changes_h,
          ARRAY[item.k],
          item.v
        );
      END IF;
    END LOOP;

    NEW.log := jsonb_set(
      NEW.log,
      ARRAY[size::text],
      jsonb_build_object(
        'ts',
        extract(epoch from now())::int,
        'i',
        (NEW.log#>>ARRAY[(size - 1)::text, 'i'])::int + 1,
        'd',
        changes_h
      ),
      true
    );
    return NEW;
  END;
  $body$
  LANGUAGE plpgsql;


ALTER TABLE pgbench_accounts ADD COLUMN log jsonb DEFAULT '[]' NOT NULL;

UPDATE pgbench_accounts SET log = to_jsonb(ARRAY[json_build_object('i', 0)])::jsonb;

CREATE TRIGGER keys_log_accounts
BEFORE UPDATE ON pgbench_accounts FOR EACH ROW
EXECUTE PROCEDURE keys_logger();
