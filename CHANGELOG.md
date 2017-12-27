# Change log

## master

## 0.6.0 (2017-12-27)

- [Fixes [#33](https://github.com/palkan/logidze/issues/33)] Support attributes types. ([@palkan][])

  Added deserialization of complex types (such as `jsonb`, arrays, whatever).

- Use positional arguments in `at`/`diff_from` methods and allow passing version. ([@palkan][])

  Now you can write `post.diff_from(time: ts)`, `post.diff_from(version: x)`, Post.at(time: 1.day.ago)`, etc.

  NOTE: the previous behaviour is still supported (but gonna be deprecated),
  i.e. you still can use `post.diff_from(ts)` if you don't mind the deprecation warning.

## 0.5.3 (2017-08-22)

- Add `--update` flag to model migration. ([@palkan][])

## 0.5.2 (2017-06-19)

- Use versioned migrations in Rails 5+. ([@palkan][])

## 0.5.1 (2017-06-15)

- _(Fix)_ Drop *all* created functions upon rolling back (https://github.com/palkan/logidze/commit/b8e150cc18b3316a8cf0c78f7117339481fb49c6). ([@vassilevsky][])

## 0.5.0 (2017-03-28)

- Add an option to preserve future versions. ([@akxcv][])

- Add `--timestamp_column` option to model migration generator. ([@akxcv][])

- Default version timestamp to timestamp column. ([@akxcv][])

- Associations versioning. ([@charlie-wasp][])

## 0.4.1 (2017-02-06)

- Add `--path` option to model migration generator. ([@palkan][])

## 0.4.0 (2017-01-14)

- Add `--blacklist` and `--whitelist` options to model migration generator. ([@charlie-wasp][])

## 0.3.0

- Add `--update` option to install migration generator. ([@palkan][])

- Add `--only-trigger` option to model migration generator. ([@palkan][])

- Add [Responsibility](https://github.com/palkan/logidze/issues/4) feature. ([@palkan][])

## 0.2.3

- Support Ruby >= 2.1. ([@palkan][])

## 0.2.2

- Add `--backfill` option to model migration. ([@palkan][])

- Handle legacy data (that doesn't have log data). ([@palkan][])

## 0.2.1

- Support both Rails 4 and 5. ([@palkan][])

## 0.2.0 (**Incompatible with 0.1.0**)

- Rails 5 support. ([@palkan][])

[@palkan]: https://github.com/palkan
[@charlie-wasp]: https://github.com/charlie-wasp
[@akxcv]: https://github.com/akxcv
[@vassilevsky]: https://github.com/vassilevsky
