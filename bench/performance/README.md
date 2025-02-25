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
          Plain INSERT:      450.9 i/s
        Logidze INSERT:      408.2 i/s - same-ish: difference falls within error
LogidzeDetached INSERT:      359.8 i/s - same-ish: difference falls within error
     PaperTrail INSERT:      183.9 i/s - same-ish: difference falls within error
```

## Update ([source](benchmarks/update_bench.rb))

When changeset has 2 fields:

```sh
Comparison:
          Plain UPDATE #1:      204.8 i/s
LogidzeDetached UPDATE #1:      188.4 i/s - same-ish: difference falls within error
        Logidze UPDATE #1:      175.7 i/s - same-ish: difference falls within error
             PT UPDATE #1:      114.2 i/s - same-ish: difference falls within error
```

When changeset has 5 fields:

```sh
Comparison:
           Plain UPDATE #2:      117.8 i/s
Logidze Detached UPDATE #2:      116.1 i/s - same-ish: difference falls within error
         Logidze UPDATE #2:      115.4 i/s - same-ish: difference falls within error
              PT UPDATE #2:       57.6 i/s - 2.04x  slower
```

## Getting diff ([source](benchmarks/diff_bench.rb))

PaperTrail doesn't have built-in method to calculate diff between not adjacent versions.
We added `#diff_from(ts)` and `#diff_from_joined(ts)` (which uses SQL JOIN) methods to calculate diff from specified version using changesets.

When each record has 10 versions:

```sh
Comparison:
        Logidze DIFF:      189.2 i/s
LogidzeDetached DIFF:      124.0 i/s - 1.52x  slower
      PT (join) DIFF:        4.4 i/s - 42.82x  slower
             PT DIFF:        3.1 i/s - 60.69x  slower
```

When each record has 100 versions:

```sh

Comparison:
        Logidze DIFF:       78.5 i/s
LogidzeDetached DIFF:       69.8 i/s - 1.13x  slower
             PT DIFF:        0.4 i/s - 200.20x  slower
      PT (join) DIFF:        0.3 i/s - 227.26x  slower
```

## Getting version at the specified time ([source](benchmarks/version_at_bench.rb))

Measuring the time to get the _middle_ version using the corresponding timestamp.

When each record has 10 versions:

```sh
Comparison:
        Logidze AT single:      468.3 i/s
LogidzeDetached AT single:      262.3 i/s - same-ish: difference falls within error
             PT AT single:      169.6 i/s - 2.76x  slower

Comparison:
        Logidze AT many:      283.7 i/s
LogidzeDetached AT many:      199.3 i/s - 1.42x  slower
             PT AT many:       27.0 i/s - 10.52x  slower
```

When each record has 100 versions:

```sh
Comparison:
        Logidze AT single:      339.2 i/s
LogidzeDetached AT single:      219.6 i/s - same-ish: difference falls within error
             PT AT single:      150.3 i/s - 2.26x  slower

Comparison:
        Logidze AT many:      167.9 i/s
LogidzeDetached AT many:      130.2 i/s - 1.29x  slower
             PT AT many:       24.2 i/s - 6.94x  slower
```

**NOTE:** PaperTrail has N+1 problem when loading multiple records at the specified time (due to the usage of the `versions.subsequent` method).

## Select memory usage ([source](benchmarks/memory_profile.rb))

Logidze stores logs in-place. But at what cost?

When each record has 10 versions:

```sh
Plain records
Total Allocated:				44.38 KB
Total Retained:					22.52 KB
Retained_memsize memory (per record):		2.35 KB

PT with versions
Total Allocated:				387.58 KB
Total Retained:					223.77 KB
Retained_memsize memory (per record):		203.13 KB

Logidze records
Total Allocated:				76.37 KB
Total Retained:					38.46 KB
Retained_memsize memory (per record):		3.72 KB

LogidzeDetached records
Total Allocated:				53.84 KB
Total Retained:					24.1 KB
Retained_memsize memory (per record):		-1768 B
```

When each record has 100 versions:

```sh
Plain records
Total Allocated:				44.3 KB
Total Retained:					22.48 KB
Retained_memsize memory (per record):		2.23 KB

PT with versions
Total Allocated:				3.32 MB
Total Retained:					1.99 MB
Retained_memsize memory (per record):		1.97 MB

Logidze records
Total Allocated:				281.22 KB
Total Retained:					140.89 KB
Retained_memsize memory (per record):		14.16 KB

LogidzeDetached records
Total Allocated:				53.29 KB
Total Retained:					23.83 KB
Retained_memsize memory (per record):		-1608 B
```
