# Triggers benchmarks

This benchmark uses standard _pg\_bench_ table `pgbench_accounts`.
We consider several approaches for calculating records diff: one uses _hstore_ extension, two uses jsonb functions and two others iterate through record fields.

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

make jsonb

make jsonb2

make keys

make keys2

# raw update, no triggers
make plain
```

You can specify the number of transactions by `T` variable (defaults to 10000):

```sh
make T=1000000
```

# Results

The benchmark shows that hstore and jsonb variants are of the same efficiency (running on MacPro 2013, 2.4 GHz Core i5, 4GB, SSD, 1 million transactions per test):

|Mode    | TPS  | Statement latency (ms) |
|--------|------|------------------------|
| plain  | 3805 | 0.106                  |
| hstore | 3061 | 0.165                  |
| jsonb  | 3079 | 0.165                  |
| jsonb2 | 3057 | 0.166                  |
| keys   | 2606 | 0.209                  |
| keys2  | 2610 | 0.216                  |

_Logidze_ uses jsonb variant.
