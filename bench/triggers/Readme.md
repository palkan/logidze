# Triggers benchmarks

This benchmark uses standard _pg\_bench_ table `pgbench_accounts`.
We consider several approaches for calculating records diff: one uses _hstore_ extension, two uses jsonb functions and two others iterate through record fields.

# Usage

Create database (required only if not using Dip):

```sh
make setup
```

You can provide database name by `DB` variable (defaults to "logidze_bench").

Run all benchmarks:

```sh
make
```

or separate benchmark:

```sh
make hstore

make jsonb

make jsonb2

make keys

make keys2

# Raw update, no triggers
make plain
```

You can specify the number of transactions by `T` variable (defaults to 10000):

```sh
make T=1000000
```

# Results

The benchmark shows that hstore variant is the most efficient (running on MacPro 2013, 2.4 GHz Core i5, 4GB, SSD, 1 million transactions per test):

|Mode    | TPS  | Statement latency (ms) |
|--------|------|------------------------|
| plain  | 3628 | 0.113                  |
| hstore | 3015 | 0.168                  |
| jsonb  | 1647 | 0.363                  |
| jsonb2 | 1674 | 0.354                  |
| keys   | 2355 | 0.219                  |
| keys2  | 2542 | 0.210                  |

_Logidze_ uses hstore variant.
