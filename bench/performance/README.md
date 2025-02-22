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
          Plain INSERT:      438.4 i/s
        Logidze INSERT:      399.6 i/s - same-ish: difference falls within error
LogidzeDetached INSERT:      393.0 i/s - same-ish: difference falls within error
     PaperTrail INSERT:      145.7 i/s - 3.01x  slower
```

## Update ([source](benchmarks/update_bench.rb))

When changeset has 2 fields:

```sh
Comparison:
          Plain UPDATE #1:      257.5 i/s
LogidzeDetached UPDATE #1:      186.5 i/s - same-ish: difference falls within error
        Logidze UPDATE #1:      173.5 i/s - same-ish: difference falls within error
             PT UPDATE #1:      111.0 i/s - 2.32x  slower
```

When changeset has 5 fields:

```sh
Comparison:
           Plain UPDATE #2:      214.4 i/s
Logidze Detached UPDATE #2:      107.3 i/s - same-ish: difference falls within error
         Logidze UPDATE #2:      105.6 i/s - same-ish: difference falls within error
              PT UPDATE #2:       53.8 i/s - 3.99x  slower
```

## Getting diff ([source](benchmarks/diff_bench.rb))

PaperTrail doesn't have built-in method to calculate diff between not adjacent versions.
We added `#diff_from(ts)` and `#diff_from_joined(ts)` (which uses SQL JOIN) methods to calculate diff from specified version using changesets.

When each record has 10 versions:

```sh
Comparison:
        Logidze DIFF:      185.2 i/s
LogidzeDetached DIFF:      129.0 i/s - 1.44x  slower
      PT (join) DIFF:        4.8 i/s - 38.18x  slower
             PT DIFF:        3.3 i/s - 55.56x  slower
```

When each record has 100 versions:

```sh
Comparison:
        Logidze DIFF:       77.8 i/s
LogidzeDetached DIFF:       71.8 i/s - 1.08x  slower
             PT DIFF:        0.4 i/s - 205.70x  slower
      PT (join) DIFF:        0.3 i/s - 293.59x  slower
```

## Getting version at the specified time ([source](benchmarks/version_at_bench.rb))

Measuring the time to get the _middle_ version using the corresponding timestamp.

When each record has 10 versions:

```sh
Comparison:
        Logidze AT single:      427.1 i/s
LogidzeDetached AT single:      264.0 i/s - same-ish: difference falls within error
             PT AT single:      161.9 i/s - 2.64x  slower

Comparison:
        Logidze AT many:      293.2 i/s
LogidzeDetached AT many:      195.2 i/s - 1.50x  slower
             PT AT many:       26.0 i/s - 11.28x  slower
```

When each record has 100 versions:

```sh
Comparison:
LogidzeDetached AT single:      411.8 i/s
        Logidze AT single:      321.4 i/s - same-ish: difference falls within error
             PT AT single:      134.6 i/s - 3.06x  slower

Comparison:
        Logidze AT many:      168.1 i/s
LogidzeDetached AT many:      128.2 i/s - 1.31x  slower
             PT AT many:       24.7 i/s - 6.81x  slower
```

**NOTE:** PaperTrail has N+1 problem when loading multiple records at the specified time (due to the usage of the `versions.subsequent` method).

## Select memory usage ([source](benchmarks/memory_profile.rb))

Logidze stores logs in-place. But at what cost?

When each record has 10 versions:

```sh
Plain records
Total Allocated:				44.46 KB
Total Retained:					22.55 KB
Retained_memsize memory (per record):		2.27 KB

PT with versions
Total Allocated:				390.16 KB
Total Retained:					225.06 KB
Retained_memsize memory (per record):		204.38 KB

Logidze records
Total Allocated:				76.5 KB
Total Retained:					38.53 KB
Retained_memsize memory (per record):		3.82 KB

LogidzeDetached records
Total Allocated:				54.23 KB
Total Retained:					24.3 KB
Retained_memsize memory (per record):		-1488 B
```

When each record has 100 versions:

```sh
Plain records
Total Allocated:				43.99 KB
Total Retained:					22.32 KB
Retained_memsize memory (per record):		2.27 KB

PT with versions
Total Allocated:				3.32 MB
Total Retained:					1.99 MB
Retained_memsize memory (per record):		1.97 MB

Logidze records
Total Allocated:				283.5 KB
Total Retained:					142.03 KB
Retained_memsize memory (per record):		14.46 KB

LogidzeDetached records
Total Allocated:				53.61 KB
Total Retained:					23.98 KB
Retained_memsize memory (per record):		-1968 B
```
