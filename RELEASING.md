# How to release a gem

This document describes a process of releasing a new version of a gem.

1. Bump version.

```sh
git commit -m "Bump 1.<x>.<y>"
```

We're (kinda) using semantic versioning:

- Bugfixes should be released as fast as possible as patch versions.
- New features could be combined and released as minor or patch version upgrades (depending on the _size of the feature_—it's up to maintainers to decide).
- Breaking API changes should be avoided in minor and patch releases.
- Breaking dependencies changes (e.g., dropping older Ruby support) could be released in minor versions.

How to bump a version:

- Change the version number in `lib/logidze/version.rb` file.
- Update the changelog (add new heading with the version name and date).
- Update the installation documentation if necessary (e.g., during minor and major updates).

2. Push code to GitHub and make sure CI passes.

```sh
git push
```

3. Release a gem.

```sh
gem release -t
git push --tags
```

We use [gem-release](https://github.com/svenfuchs/gem-release) for publishing gems with a single command:

```sh
gem release -t
```

Don't forget to push tags and write release notes on GitHub (if necessary).
