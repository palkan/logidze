# Database name
ifndef DB
	DB = logidze_bench
endif

# Transactions count
ifndef T
	T = 10000
endif

DIP := $(shell command -v dip 2> /dev/null)

COMMAND_PREFIX :=
FILE_PREFIX :=

ifdef DIP
	COMMAND_PREFIX = dip
	FILE_PREFIX = bench/triggers/
endif

all: plain hstore jsonb jsonb2 keys keys2

setup:
	createdb $(DB) -w
	psql -q -d $(DB) -c 'CREATE EXTENSION IF NOT EXISTS hstore;'

plain:
	$(info )
	$(info ======  [START] Update without triggers ======)
	$(COMMAND_PREFIX) pgbench -i -q $(DB)
	$(COMMAND_PREFIX) pgbench -f $(FILE_PREFIX)bench.sql -t $(T) -r $(DB)

hstore:
	$(info )
	$(info ======  [START] Update with hstore-based triggers ======)
	$(COMMAND_PREFIX) pgbench -i -q $(DB)
	$(COMMAND_PREFIX) psql -q -d $(DB) -f $(FILE_PREFIX)hstore_trigger_setup.sql
	$(COMMAND_PREFIX) pgbench -f $(FILE_PREFIX)bench.sql -t $(T) -r $(DB)

jsonb:
	$(info )
	$(info ======  [START] Update with jsonb-minus triggers ======)
	$(COMMAND_PREFIX) pgbench -i -q $(DB)
	$(COMMAND_PREFIX) psql -q -d $(DB) -f $(FILE_PREFIX)jsonb_minus_setup.sql
	$(COMMAND_PREFIX) pgbench -f $(FILE_PREFIX)bench.sql -t $(T) -r $(DB)

jsonb2:
	$(info )
	$(info ======  [START] Update with jsonb-minus triggers ======)
	$(COMMAND_PREFIX) pgbench -i -q $(DB)
	$(COMMAND_PREFIX) psql -q -d $(DB) -f $(FILE_PREFIX)jsonb_minus_2_setup.sql
	$(COMMAND_PREFIX) pgbench -f $(FILE_PREFIX)bench.sql -t $(T) -r $(DB)

keys:
	$(info )
	$(info ======  [START] Update with loop thru keys triggers (v1) ======)
	$(COMMAND_PREFIX) pgbench -i -q $(DB)
	$(COMMAND_PREFIX) psql -q -d $(DB) -f $(FILE_PREFIX)keys_trigger_setup.sql
	$(COMMAND_PREFIX) pgbench -f $(FILE_PREFIX)bench.sql -t $(T) -r $(DB)

keys2:
	$(info )
	$(info ======  [START] Update with loop thru keys triggers (v2) ======)
	$(COMMAND_PREFIX) pgbench -i -q $(DB)
	$(COMMAND_PREFIX) psql -q -d $(DB) -f $(FILE_PREFIX)keys2_trigger_setup.sql
	$(COMMAND_PREFIX) pgbench -f $(FILE_PREFIX)bench.sql -t $(T) -r $(DB)
