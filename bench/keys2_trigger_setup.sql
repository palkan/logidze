CREATE OR REPLACE FUNCTION keys_logger() RETURNS TRIGGER AS $body$
  DECLARE
    size integer;
    old_j jsonb;
    changes_j jsonb;
    item record;
  BEGIN
    size := jsonb_array_length(NEW.log);
    old_j := to_jsonb(OLD);
    changes_j := to_jsonb(NEW);

    FOR item in SELECT key as k, value as v FROM jsonb_each(old_j)
    LOOP
      IF changes_j->item.k = item.v THEN
        changes_j := changes_j - item.k;
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
        changes_j
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
