# Triggers benchmarks

This benchmark uses standrad _pg_bench_ table `pgbench_accounts`.
We consider several approaches of calculating record diff: one uses _hstore_ extension and two others iterate through record fields.

# Usage

Create database:

```sh
make setup
```

You can provide database name through `DB` variable (by default "logidze_bench").

Run all benchmarks:

```sh
make
```

or separate benchmark:

```sh
make hstore

make keys

make keys2

# raw update, no triggers
make plain
```

You can specify the number of transaction through `T` variable (by default 10000):

```sh
make T=1000000
```

# Results

The benchmark shows that hstore variant is more efficient then others (running on MacPro 2013, 2.4 GHz Core i5, 4GB, SSD, 1 million transactions per test):

|Mode    | TPS  | Statement latency (ms) |
|--------|------|------------------------|
| plain  | 3538 | 0.113                  |
| hstore | 2902 | 0.168                  |
| keys   | 2636 | 0.206                  |
| keys2  | 2490 | 0.220                  |
