CREATE OR REPLACE FUNCTION logidze_compact_history(log_data jsonb) RETURNS jsonb AS $body$
  DECLARE
    merged jsonb;
  BEGIN
    merged := jsonb_build_object(
      'ts',
      log_data#>'{h,1,ts}',
      'v',
      log_data#>'{h,1,v}',
      'c',
      (log_data#>'{h,0,c}') || (log_data#>'{h,1,c}')
    );

    IF (log_data#>'{h,1}' ? 'm') THEN
      merged := jsonb_set(merged, ARRAY['m'], log_data#>'{h,1,m}');
    END IF;

    return jsonb_set(
      log_data,
      '{h}',
      jsonb_set(
        log_data->'h',
        '{1}',
        merged
      ) - 0
    );
  END;
$body$
LANGUAGE plpgsql;
