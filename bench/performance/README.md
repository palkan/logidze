# Performance benchmarks: PaperTail vs. Logidze

We want to compare Logidze with the most popular versioning library for Rails – PaperTrail.

To run this benchmarks, you need to first provision the example Rails app:

```sh
bundle install
bundle exec rails db:migrate
```

To run a benchmark, run the corresponding script:

```sh
bundle exec ruby benchmarks/insert_bench.rb
```

## Insert ([source](benchmarks/insert_bench.rb))

```sh
Comparison:
        Plain INSERT:      535.5 i/s
      Logidze INSERT:      498.2 i/s - same-ish: difference falls within error
   PaperTrail INSERT:      276.5 i/s - 1.94x  (± 0.00) slower
```

## Update ([source](benchmarks/update_bench.rb))

When changeset has 2 fields:

```sh
Comparison:
     Plain UPDATE #1:      775.2 i/s
   Logidze UPDATE #1:      518.6 i/s - 1.49x  (± 0.00) slower
        PT UPDATE #1:      471.4 i/s - 1.64x  (± 0.00) slower
```

When changeset has 5 fields:

```sh
Comparison:
     Plain UPDATE #2:      726.8 i/s
   Logidze UPDATE #2:      468.0 i/s - 1.55x  (± 0.00) slower
        PT UPDATE #2:      431.2 i/s - 1.69x  (± 0.00) slower
```

## Getting diff ([source](benchmarks/diff_bench.rb))

PaperTrail doesn't have built-in method to calculate diff between not adjacent versions.
We added `#diff_from(ts)` and `#diff_from_joined(ts)` (which uses SQL JOIN) methods to calculate diff from specified version using changesets.

When each record has 10 versions:

```sh
Comparison:
        Logidze DIFF:      129.2 i/s
      PT (join) DIFF:        4.5 i/s - 28.57x  (± 0.00) slower
             PT DIFF:        3.9 i/s - 32.83x  (± 0.00) slower
```

When each record has 100 versions:

```sh
Comparison:
        Logidze DIFF:       32.8 i/s
      PT (join) DIFF:        0.5 i/s - 69.48x  (± 0.00) slower
             PT DIFF:        0.4 i/s - 88.81x  (± 0.00) slower
```

## Getting version at the specified time ([source](benchmarks/version_at_bench.rb))

Measuring the time to get the _middle_ version using the corresponding timestamp.

When each record has 10 versions:

```sh
Comparison:
   Logidze AT single:      882.1 i/s
        PT AT single:      336.7 i/s - 2.62x  (± 0.00) slower

Comparison:
     Logidze AT many:      265.0 i/s
          PT AT many:       43.9 i/s - 6.04x  (± 0.00) slower
```

When each record has 100 versions:

```sh
Comparison:
   Logidze AT single:      543.0 i/s
        PT AT single:      337.8 i/s - 1.61x  (± 0.00) slower

Comparison:
     Logidze AT many:       92.0 i/s
          PT AT many:       45.3 i/s - 2.03x  (± 0.00) slower
```

**NOTE:** PaperTrail has N+1 problem when loading multiple records at the specified time (due to the usage of the `versions.subsequent` method).

## Select memory usage ([source](benchmarks/memory_profile.rb))

Logidze stores logs in-place. But at what cost?

When each record has 10 versions:

```sh
Plain records
Total Allocated:                                15.24 KB
Total Retained:                                 9.68 KB
Retained_memsize memory (per record):           1.12 KB

PT with versions
Total Allocated:                                124.38 KB
Total Retained:                                 95.52 KB
Retained_memsize memory (per record):           81.82 KB

Logidze records
Total Allocated:                                38.68 KB
Total Retained:                                 32.12 KB
Retained_memsize memory (per record):           3.54 KB
```

When each record has 100 versions:

```sh
Plain records
Total Allocated:                                15.22 KB
Total Retained:                                 9.66 KB
Retained_memsize memory (per record):           1.11 KB

PT with versions
Total Allocated:                                998.71 KB
Total Retained:                                 864.26 KB
Retained_memsize memory (per record):           850.6 KB

Logidze records
Total Allocated:                                140.16 KB
Total Retained:                                 133.6 KB
Retained_memsize memory (per record):           13.91 KB
```
