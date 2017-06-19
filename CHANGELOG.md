# Change log

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
