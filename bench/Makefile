# Database name
ifndef DB
	DB = logidze_bench
endif

# Transactions count
ifndef T
	T = 10000
endif

all:
	make plain
	make hstore
	make keys

setup:
	pgbench -i -q $(DB)

plain: setup
	pgbench -f bench.sql -t $(T) -r $(DB)

hstore: setup
	psql -q -d $(DB) -f hstore_trigger_setup.sql 
	pgbench -f bench.sql -t $(T) -r $(DB)     

keys: setup
	psql -q -d $(DB) -f keys_trigger_setup.sql
	pgbench -f bench.sql -t $(T) -r $(DB)  
