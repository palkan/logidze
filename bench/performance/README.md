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
          Plain INSERT:      253.1 i/s
        Logidze INSERT:      129.2 i/s - same-ish: difference falls within error
LogidzeDetached INSERT:      118.9 i/s - same-ish: difference falls within error
     PaperTrail INSERT:       94.5 i/s - same-ish: difference falls within error
```

## Update ([source](benchmarks/update_bench.rb))

When changeset has 2 fields:

```sh
Comparison:
          Plain UPDATE #1:      121.1 i/s
LogidzeDetached UPDATE #1:      120.7 i/s - same-ish: difference falls within error
        Logidze UPDATE #1:      111.6 i/s - same-ish: difference falls within error
             PT UPDATE #1:       99.1 i/s - same-ish: difference falls within error
```

When changeset has 5 fields:

```sh
Comparison:
           Plain UPDATE #2:       68.4 i/s
Logidze Detached UPDATE #2:       65.7 i/s - same-ish: difference falls within error
         Logidze UPDATE #2:       54.9 i/s - same-ish: difference falls within error
              PT UPDATE #2:       48.7 i/s - same-ish: difference falls within error
```

## Getting diff ([source](benchmarks/diff_bench.rb))

PaperTrail doesn't have built-in method to calculate diff between not adjacent versions.
We added `#diff_from(ts)` and `#diff_from_joined(ts)` (which uses SQL JOIN) methods to calculate diff from specified version using changesets.

When each record has 10 versions:

```sh
Comparison:
        Logidze DIFF:      152.8 i/s
LogidzeDetached DIFF:        9.8 i/s - 15.54x  slower
      PT (join) DIFF:        3.8 i/s - 40.06x  slower
             PT DIFF:        3.1 i/s - 49.45x  slower
```

When each record has 100 versions:

```sh
Comparison:
        Logidze DIFF:       62.8 i/s
LogidzeDetached DIFF:        7.1 i/s - 8.80x  slower
      PT (join) DIFF:        0.3 i/s - 183.38x  slower
             PT DIFF:        0.3 i/s - 240.52x  slower
```

## Getting version at the specified time ([source](benchmarks/version_at_bench.rb))

Measuring the time to get the _middle_ version using the corresponding timestamp.

When each record has 10 versions:

```sh
Comparison:
        Logidze AT single:      316.1 i/s
LogidzeDetached AT single:      189.8 i/s - same-ish: difference falls within error
             PT AT single:      151.0 i/s - 2.09x  slower

Comparison:
        Logidze AT many:      210.8 i/s
LogidzeDetached AT many:       40.3 i/s - 5.24x  slower
             PT AT many:       24.1 i/s - 8.73x  slower
```

When each record has 100 versions:

```sh
Comparison:
        Logidze AT single:      260.3 i/s
LogidzeDetached AT single:      163.7 i/s - same-ish: difference falls within error
             PT AT single:      115.7 i/s - 2.25x  slower

Comparison:
        Logidze AT many:      135.3 i/s
LogidzeDetached AT many:       32.2 i/s - 4.20x  slower
             PT AT many:       17.1 i/s - 7.92x  slower
```

**NOTE:** PaperTrail has N+1 problem when loading multiple records at the specified time (due to the usage of the `versions.subsequent` method).

## Select memory usage ([source](benchmarks/memory_profile.rb))

Logidze stores logs in-place. But at what cost?

When each record has 10 versions:

```sh
Plain records
Total Allocated:				            44.46 KB
Total Retained:					            22.55 KB
Retained_memsize memory (per record):		2.39 KB

PT with versions
Total Allocated:				            393.6 KB
Total Retained:					            226.78 KB
Retained_memsize memory (per record):		206.05 KB

Logidze records
Total Allocated:				            77.39 KB
Total Retained:					            38.97 KB
Retained_memsize memory (per record):		3.8 KB

LogidzeDetached records
Total Allocated:				            53.84 KB
Total Retained:					            24.1 KB
Retained_memsize memory (per record):		-2288 B
```

When each record has 100 versions:

```sh
Plain records
Total Allocated:				            43.21 KB
Total Retained:					            21.93 KB
Retained_memsize memory (per record):		2.27 KB

PT with versions
Total Allocated:				            3.23 MB
Total Retained:					            1.95 MB
Retained_memsize memory (per record):		1.93 MB

Logidze records
Total Allocated:				            279.76 KB
Total Retained:					            140.16 KB
Retained_memsize memory (per record):		14.14 KB

LogidzeDetached records
Total Allocated:				            53.22 KB
Total Retained:					            23.79 KB
Retained_memsize memory (per record):		-1928 B
```
