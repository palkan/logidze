# Change log

## master

- [PR [#87](https://github.com/palkan/logidze/pull/87)] Adding debounce time to avoid spamming changelog creation ([@zocoi][])

Usage:

```shell
# 5000ms
rails generate logidze:model story --debounce_time=5000
```

You see the following in generated migration

```sql
CREATE TRIGGER logidze_on_stories
      BEFORE UPDATE OR INSERT ON stories FOR EACH ROW
      WHEN (coalesce(#{current_setting('logidze.disabled')}, '') <> 'on')
      EXECUTE PROCEDURE logidze_logger(null, 'updated_at', null, 5000);
```

How to upgrade.

Please run `rails generate logidze:install --update` to regenerate stored functions.

This feature checks if several logs came in within a debounce time period then only keep the latest one
by merging the latest in previous others.

The concept is similar to https://underscorejs.org/#debounce

without `debounce_time`

```js
{
    "h": [
        {
            "c": {
                "content": "Content 1"
            },
            "v": 1,
            "ts": 0
        },
        {
            "c": {
                "content": "content 2",
                "active": true
            },
            "v": 2,
            "ts": 100
        },
        {
            "c": {
                "content": "content 3",
            },
            "v": 3,
            "ts": 101
        }
    ],
    "v": 3
}
```

with `debounce_time` of `10ms`

```js
{
    "h": [
        {
            "c": {
                "content": "Content 1"
            },
            "v": 1,
            "ts": 0
        },
        {
            "c": {
                "content": "content 3",
                "active": true
            },
            "v": 2,
            "ts": 101
        }
    ],
    "v": 3
}
```

## 0.7.0 (2018-08-29)

- [Fixes [#75](https://github.com/palkan/logidze/issues/70)] Fix association versioning with an optional belongs to ([@ankursethi-uscis][])

- [PR [#79](https://github.com/palkan/logidze/pull/13)] Allow adding meta information to versions using `with_meta` (addressed [Issue [#60]](https://github.com/palkan/logidze/issues/60)). ([@DmitryTsepelev][])

Usage:

```ruby
Logidze.with_meta(ip: request.ip) { post.save }
puts post.meta # => { 'ip' => '95.66.157.226' }
```

How to upgrade.

Please run `rails generate logidze:install --update` to regenerate stored functions.

This feature replaces the implementation of `with_responsible`, now `responsible_id` is stored inside of the meta hash with the key `_r`.

There is fallback to the old data structure (`{ 'r' => 42 }` opposed to `{ 'm' => { '_r' => 42 } }` in the current implementation), so `responsible_id` should work as usual for the existing data.

If you've accessed the value manually (e.g. `post.log_data.current_version.data['r']`), you'll have to add the fallback too.

## 0.6.5 (2018-08-08)

- Make compatible with Rails 5.2.1 ([@palkan][])

## 0.6.4 (2018-04-30)

- [Fixes [#70](https://github.com/palkan/logidze/issues/70)] Ignore missing (e.g. removed) columns in diffs and past versions. ([@palkan][])

This is a quick fix for a more general problem (see [#59](https://github.com/palkan/logidze/issues/59)).

## 0.6.3 (2018-01-17)

- [Fixes [#57](https://github.com/palkan/logidze/issues/57)] Support associations versioning for `at(version:)`. ([@palkan][])

- Add [`rubocop-md`](https://github.com/palkan/rubocop-md)

## 0.6.2 (2018-01-11)

- [Fixes [#53](https://github.com/palkan/logidze/issues/53)] Fix storing empty log entries with blacklisting. ([@charlie-wasp][])

## 0.6.1 (2018-01-06)

- [Fixes [#54](https://github.com/palkan/logidze/issues/54)] Fix loading of `ActiveModel::Type::Value` for Rails 5.2. ([@palkan][])

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

- _(Fix)_ Drop _all_ created functions upon rolling back (https://github.com/palkan/logidze/commit/b8e150cc18b3316a8cf0c78f7117339481fb49c6). ([@vassilevsky][])

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
[@ankursethi-uscis]: https://github.com/ankursethi-uscis
[@dmitrytsepelev]: https://github.com/DmitryTsepelev
[@zocoi]: https://github.com/zocoi
