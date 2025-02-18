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
          Plain INSERT:      143.6 i/s
LogidzeDetached INSERT:      120.7 i/s - same-ish: difference falls within error
        Logidze INSERT:      118.5 i/s - same-ish: difference falls within error
     PaperTrail INSERT:       96.1 i/s - 1.49x  slower
```

## Update ([source](benchmarks/update_bench.rb))

When changeset has 2 fields:

```sh
Comparison:
        Logidze UPDATE #1:      121.0 i/s
          Plain UPDATE #1:      108.2 i/s - same-ish: difference falls within error
LogidzeDetached UPDATE #1:       96.7 i/s - same-ish: difference falls within error
             PT UPDATE #1:       67.6 i/s - same-ish: difference falls within error
```

When changeset has 5 fields:

```sh
Comparison:
           Plain UPDATE #2:       61.3 i/s
         Logidze UPDATE #2:       55.7 i/s - same-ish: difference falls within error
Logidze Detached UPDATE #2:       47.8 i/s - same-ish: difference falls within error
              PT UPDATE #2:       30.4 i/s - same-ish: difference falls within error
```

## Getting diff ([source](benchmarks/diff_bench.rb))

PaperTrail doesn't have built-in method to calculate diff between not adjacent versions.
We added `#diff_from(ts)` and `#diff_from_joined(ts)` (which uses SQL JOIN) methods to calculate diff from specified version using changesets.

When each record has 10 versions:

```sh
Comparison:
        Logidze DIFF:      112.5 i/s
LogidzeDetached DIFF:       13.7 i/s - 8.19x  slower
      PT (join) DIFF:        3.7 i/s - 30.26x  slower
             PT DIFF:        1.7 i/s - 64.99x  slower
```

When each record has 100 versions:

```sh
Comparison:
        Logidze DIFF:       63.1 i/s
LogidzeDetached DIFF:       11.0 i/s - 5.75x  slower
      PT (join) DIFF:        0.3 i/s - 200.58x  slower
             PT DIFF:        0.3 i/s - 248.20x  slower
```

## Getting version at the specified time ([source](benchmarks/version_at_bench.rb))

Measuring the time to get the _middle_ version using the corresponding timestamp.

When each record has 10 versions:

```sh
Comparison:
        Logidze AT single:      321.7 i/s
LogidzeDetached AT single:      167.2 i/s - 1.92x  slower
             PT AT single:       99.9 i/s - 3.22x  slower

Comparison:
        Logidze AT many:      155.1 i/s
LogidzeDetached AT many:       32.1 i/s - 4.83x  slower
             PT AT many:       20.3 i/s - 7.66x  slower
```

When each record has 100 versions:

```sh
Comparison:
        Logidze AT single:      288.2 i/s
LogidzeDetached AT single:      156.7 i/s - 1.84x  slower
             PT AT single:      138.7 i/s - 2.08x  slower

Comparison:
        Logidze AT many:      140.4 i/s
LogidzeDetached AT many:       42.8 i/s - 3.28x  slower
             PT AT many:       21.4 i/s - 6.57x  slower
```

**NOTE:** PaperTrail has N+1 problem when loading multiple records at the specified time (due to the usage of the `versions.subsequent` method).

## Select memory usage ([source](benchmarks/memory_profile.rb))

Logidze stores logs in-place. But at what cost?

When each record has 10 versions:

```sh
Plain records
Total Allocated:				            43.6 KB
Total Retained:					            22.13 KB
Retained_memsize memory (per record):		2.23 KB

PT with versions
Total Allocated:				            385.0 KB
Total Retained:					            222.48 KB
Retained_memsize memory (per record):		202.07 KB

Logidze records
Total Allocated:				            75.97 KB
Total Retained:					            38.27 KB
Retained_memsize memory (per record):		3.7 KB

LogidzeDetached records
Total Allocated:				            8.75 MB
Total Retained:					            5.28 MB
Retained_memsize memory (per record):		5.25 MB
```

When each record has 100 versions:

```sh
Plain records
Total Allocated:				            43.6 KB
Total Retained:					            22.13 KB
Retained_memsize memory (per record):		2.27 KB

PT with versions
Total Allocated:				            3.22 MB
Total Retained:					            1.95 MB
Retained_memsize memory (per record):		1.93 MB

Logidze records
Total Allocated:				           278.64 KB
Total Retained:					            139.6 KB
Retained_memsize memory (per record):		13.95 KB

LogidzeDetached records
Total Allocated:				            8.75 MB
Total Retained:					            5.28 MB
Retained_memsize memory (per record):		5.25 MB
```
