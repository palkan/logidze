class CreatePartitionedPosts < ActiveRecord::Migration[6.1]
  PG_MINIMUM_VERSION = 11

  def up
    current_pg_version =
      ActiveRecord::Base
        .connection
        .execute("SELECT (substr(current_setting('server_version'), 1, 2)::smallint);")
        .values.first&.first

    unless pg_version_11_and_upper?(current_pg_version)
      return false
    end

    execute <<-SQL
      CREATE TABLE partitioned_posts (
        id         SERIAL,
        title      varchar,
        logdate    date not null,
        data       json,
        meta       jsonb,
        active     boolean,
        rating     int,
        created_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      ) PARTITION BY RANGE (logdate);
      
      ALTER TABLE partitioned_posts
        ADD CONSTRAINT partitioned_posts_pkey PRIMARY KEY (id, logdate);

      CREATE TABLE partitioned_posts_y2023m01 PARTITION OF partitioned_posts
        FOR VALUES FROM ('2023-01-01') TO ('2023-02-01');

      CREATE TABLE partitioned_posts_y2023m02 PARTITION OF partitioned_posts
        FOR VALUES FROM ('2023-02-01') TO ('2023-03-01');
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS partitioned_posts_y2023m02;
      DROP TABLE IF EXISTS partitioned_posts_y2023m01;
      DROP TABLE IF EXISTS partitioned_posts;
    SQL
  end

  private

  def pg_version_11_and_upper?(current_version)
    current_version >= PG_MINIMUM_VERSION
  end
end
