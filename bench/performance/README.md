# Performance benchmarks: PaperTail vs. Logidze

We want to compare Logidze with the most popular versioning library for Rails – PaperTrail.


## Insert ([source](insert_bench.rb))

```
PaperTrail INSERT    213.148  (± 8.9%) i/s -      1.060k in   5.018504s
   Logidze INSERT    613.387  (±16.3%) i/s -      2.970k in   5.036127s
```


## Update ([source](update_bench.rb))

When changeset has 2 fields:

```
PaperTrail UPDATE #1    256.651  (±26.5%) i/s -      1.206k in   5.002300s
   Logidze UPDATE #1    356.932  (±12.6%) i/s -      1.764k in   5.030560s
```

When changeset has 5 fields:

```
PaperTrail UPDATE #2    246.281  (±24.0%) i/s -      1.168k in   5.008234s
   Logidze UPDATE #2    331.942  (±16.6%) i/s -      1.593k in   5.028135s
```

## Getting diff ([source](diff_bench.rb))

PaperTrail doesn't have built-in method to calculate diff between not adjacent versions.
We add `diff_from(ts)` and `diff_from_joined(ts)` (which uses SQL JOIN) methods to calculate diff from specified version using changesets.

When each record has 10 versions:

```
       PT DIFF     20.874  (± 4.8%) i/s -    106.000  in   5.091402s
PT (join) DIFF     20.619  (± 4.8%) i/s -    104.000  in   5.070160s
  Logidze DIFF    109.482  (±24.7%) i/s -    500.000  in   5.103534s
```

When each record has 100 versions:

```
       PT DIFF      2.998  (± 0.0%) i/s -     15.000  in   5.019494s
PT (join) DIFF      3.193  (± 0.0%) i/s -     16.000  in   5.030155s
  Logidze DIFF     19.627  (±25.5%) i/s -     88.000  in   5.035555s
```

And, finally, when each record has 1000 versions:

```
       PT DIFF      0.270  (± 0.0%) i/s -     17.000  in  63.038374s
PT (join) DIFF      0.235  (± 0.0%) i/s -     14.000  in  60.350886s
  Logidze DIFF      2.022  (± 0.0%) i/s -    120.000  in  60.142965s
```

## Select memory usage ([source](memory_profile.rb))

Logidze loads more data (because it stores log in-place). But how much more?
We consider two cases for PaperTrail: when we want to calculate diff (and thus loading versions) and when we don't need any history related data.

When each record has 10 versions:

```
PT records
Total Allocated:                 27.8 KB
Total Retained:                  16.59 KB
Retained memory (per record):    2.14 KB

PT with versions
Total Allocated:                 228.01 KB
Total Retained:                  170.78 KB
Retained memory (per record):    143.13 KB

Logidze records
Total Allocated:                 46.45 KB
Total Retained:                  34.73 KB
Retained memory (per record):    4.11 KB
```

When each record has 100 versions:

```
PT with versions
Total Allocated:                 1.92 MB
Total Retained:                  1.56 MB
Retained memory (per record):    1.53 MB

Logidze records
Total Allocated:                 162.48 KB
Total Retained:                  150.76 KB
Retained memory (per record):    15.4 KB
```

When each record has 1000 versions:

```
PT with versions
Total Allocated:                 18.23 MB
Total Retained:                  14.86 MB
Retained memory (per record):    14.83 MB

Logidze records
Total Allocated:                 1.32 MB
Total Retained:                  1.31 MB
Retained memory (per record):    131.59 KB
```
