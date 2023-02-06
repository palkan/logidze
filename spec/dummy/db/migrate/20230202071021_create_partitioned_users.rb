# frozen_string_literal: true

class CreatePartitionedUsers < ActiveRecord::Migration[5.0]
  def up
    pg_version = select_value("SELECT current_setting('server_version_num')::int;")
    return if pg_version < 12_00_00

    execute <<~SQL
      CREATE TABLE partitioned_users (
        id         serial,
        name       varchar,
        age        integer,
        active     boolean,
        extra      jsonb,
        settings   character varying[],
        created_at timestamp not null,
        updated_at timestamp not null
      ) PARTITION BY RANGE (age);
        
      CREATE TABLE partitioned_users_minor   PARTITION OF partitioned_users FOR VALUES FROM (0) TO (18);
      CREATE TABLE partitioned_users_default PARTITION OF partitioned_users DEFAULT;
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS partitioned_users CASCADE;
    SQL
  end
end
