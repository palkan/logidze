# Database name
ifndef DB
	DB = logidze_bench
endif

# Transactions count
ifndef T
	T = 10000
endif

all: plain hstore keys keys2

setup:
	createdb $(DB) -w
	psql -q -d $(DB) -c 'CREATE EXTENSION IF NOT EXISTS hstore;'

plain:
	$(info )
	$(info ======  [START] Update without triggers ======)
	pgbench -i -q $(DB)
	pgbench -f bench.sql -t $(T) -r $(DB)

hstore:
	$(info )
	$(info ======  [START] Update with hstore-based triggers ======)
	pgbench -i -q $(DB)
	psql -q -d $(DB) -f hstore_trigger_setup.sql 
	pgbench -f bench.sql -t $(T) -r $(DB)

keys:
	$(info )
	$(info ======  [START] Update with loop thru keys triggers (v1) ======)
	pgbench -i -q $(DB)
	psql -q -d $(DB) -f keys_trigger_setup.sql
	pgbench -f bench.sql -t $(T) -r $(DB) 

keys2:
	$(info )
	$(info ======  [START] Update with loop thru keys triggers (v2) ======)
	pgbench -i -q $(DB)
	psql -q -d $(DB) -f keys2_trigger_setup.sql
	pgbench -f bench.sql -t $(T) -r $(DB)  
