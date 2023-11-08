# frozen_string_literal: true

Sequel.migration do
  up do
    # TODO: Add.
    # pg_version = run("SELECT current_setting('server_version_num')::int;").values.first.first
    # return if pg_version < 11_00_00

    run <<~SQL
      CREATE TABLE "partitioned_users" (
        id         serial,
        name       varchar,
        age        integer,
        active     boolean,
        extra      jsonb,
        settings   character varying[],
        created_at timestamp not null,
        updated_at timestamp not null
      ) PARTITION BY RANGE (age);

      CREATE TABLE "partitioned_users_minor"   PARTITION OF "partitioned_users" FOR VALUES FROM (0) TO (18);
      CREATE TABLE "partitioned_users_default" PARTITION OF "partitioned_users" DEFAULT;
    SQL
  end

  down do
    execute <<~SQL
      DROP TABLE IF EXISTS partitioned_users CASCADE;
    SQL
  end
end
