class CreatePartitionedPosts < ActiveRecord::Migration[6.1]
  def up
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
        updated_at timestamp(6) without time zone NOT NULL,
        PRIMARY KEY (id, logdate)
      ) PARTITION BY RANGE (logdate);
      
      CREATE TABLE partitioned_posts_y2023m01 PARTITION OF partitioned_posts
        FOR VALUES FROM ('2023-01-01') TO ('2023-02-01');

      CREATE TABLE partitioned_posts_y2023m02 PARTITION OF partitioned_posts
        FOR VALUES FROM ('2023-02-01') TO ('2023-03-01');
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE partitioned_posts_y2023m02;
      DROP TABLE partitioned_posts_y2023m01;
      DROP TABLE partitioned_posts;
    SQL
  end
end
