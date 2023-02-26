# frozen_string_literal: true

class CreatePartitionedUsers < ActiveRecord::Migration[5.0]
  def up
    pg_version = execute("SELECT current_setting('server_version_num')::int;").values.first.first
    return if pg_version < 11_00_00

    table_name_prefix = ActiveRecord::Base.table_name_prefix
    table_name_suffix = ActiveRecord::Base.table_name_suffix

    base_table_name = "#{table_name_prefix}partitioned_users#{table_name_suffix}"

    execute <<~SQL
      CREATE TABLE "#{base_table_name}" (
        id         serial,
        name       varchar,
        age        integer,
        active     boolean,
        extra      jsonb,
        settings   character varying[],
        created_at timestamp not null,
        updated_at timestamp not null
      ) PARTITION BY RANGE (age);

      CREATE TABLE "#{base_table_name}_minor"   PARTITION OF "#{base_table_name}" FOR VALUES FROM (0) TO (18);
      CREATE TABLE "#{base_table_name}_default" PARTITION OF "#{base_table_name}" DEFAULT;
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS partitioned_users CASCADE;
    SQL
  end
end
