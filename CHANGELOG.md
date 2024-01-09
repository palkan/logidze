# Change log

## master (unreleased)

## 1.3.0 (2024-01-09)

- Add retrieving list of versions support. ([@tagirahmad][])

```ruby
post.versions # => Enumerator
post.versions.find do
  _1.title == "old title"
end
```

- Add `--after-trigger` option to generate _after_ triggers for partitioned tables in older PostgreSQL versions. ([@SparLaimor][], [@prog-supdex][], [@palkan][])

- **Breaking**. Ruby 2.7, Rails 6.0, PostgreSQL 10.0+ are required.

## 1.2.3 (2023-01-03)

- [Fixes [#217](https://github.com/palkan/logidze/issues/217)] Fix switch_to with `append: true` when there are changes on JSONB columns. ([@miharekar][])

## 1.2.2 (2022-07-13)

- [Fixes [#209](https://github.com/palkan/logidze/issues/209)] Fix tracking JSONB column changes. ([@baygeldin][])

## 1.2.1 (2022-01-13)

- [Fixes [#207](https://github.com/palkan/logidze/issues/207)] Add support for the use of `table_name_prefix` or `table_name_suffix`. ([@cavi21][])

- [Fixes [#205](https://github.com/palkan/logidze/issues/205)] Allow `rails destroy logidze:model SomeModel` to delete the migration file. ([@danielmklein][])

## 1.2.0 (2021-06-11)

- Add user-defined exception handling ([@skryukov][])

By default, Logidze raises an exception which causes the entire transaction to fail.
To change this behavior, it's now possible to override `logidze_capture_exception(error_data jsonb)` function.

- [Fixes [#69](https://github.com/palkan/logidze/issues/69)] Fallback on NUMERIC_VALUE_OUT_OF_RANGE exception ([@skryukov][])

- [Fixes [#192](https://github.com/palkan/logidze/issues/192)] Skip `log_data` column during `apply_column_diff` ([@skryukov][])

## 1.1.0 (2021-03-31)

- Add pending upgrade checks [Experimental]. ([@skryukov][])

Now Logidze can check for a pending upgrade. Use `Logidze.pending_upgrade = :warn` to be notified by warning, or `Logidze.pending_upgrade = :error` if you want Logidze to raise an error.

- [Fixes [#171](https://github.com/palkan/logidze/issues/171)] Stringify jsonb column values within snapshots. ([@skryukov][])

- [Fixes [#175](https://github.com/palkan/logidze/issues/175)] Set dynamic ActiveRecord version for migrations. ([@skryukov][])

- [Fixes [#184](https://github.com/palkan/logidze/issues/184)] Remove Rails meta-gem dependency ([@bf4][])

## 1.0.0 (2020-11-09)

- Add `--name` option to model generator to specify the migration name. ([@palkan][])

When you update Logidze installation for a model multiple times, you might hit the `DuplicateMigrationNameError` (see [#167](https://github.com/palkan/logidze/issues/167)).

- Add `.with_full_snapshot` to add full snapshots to the log instead of diffs. ([@palkan][])

Useful in combination with `.without_logging`: first, you perform multiple updates without logging, then
you do something like `with_full_snapshot { record.touch }` to create a log entry with the current state.

- Add `#create_logidze_snapshot!` and `.create_logidze_snapshot` methods. ([@palkan][])

- Add integration with `fx` gem. ([@palkan][])

Now it's possible to use Logidze with `schema.rb`. Add `fx` gem to the project, and new migrations will be
using Fx `create_function` / `create_trigger` functions.

- Refactored columns filtering. ([@palkan][])

Renamed `--whitelist/--blacklist` to `--only/--except` correspondingly.

The _only_-logic has been changed: previously we collected the list of columns to ignore at the migration generation time,
now we filter the columns within the trigger function (thus, schema changes do not affect the columns being tracked).

- **Dropped support for Rails 4.2, Ruby 2.4 and PostgreSQL 9.5**. ([@palkan][])

## 0.12.0 (2020-01-02)

- PR [#143](https://github.com/palkan/logidze/pull/143) Add `:transactional` option to `#with_meta` and `#with_responsible` ([@oleg-kiviljov][])

Now it's possible to set meta and responsible without wrapping the block into a DB transaction. For backward compatibility `:transactional` option by default is set to `true`.

Usage:

```ruby
Logidze.with_meta({ip: request.ip}, transactional: false) do
  post.save!
end
```

or

```ruby
Logidze.with_responsible(user.id, transactional: false) do
  post.save!
end
```

## 0.11.0 (2019-08-15)

- **Breaking** Return `nil` when `log_data` is not loaded instead of raising an exception. ([@palkan][])

We cannot distinguish between not loaded `log_data` and not-yet-created (i.e. for new records).
The latter could be used in frameworks/gems ([example](https://github.com/palkan/logidze/issues/127#issuecomment-518798640)).

- **Breaking** Only allow specifying `ignore_log_data` at boot time without runtime modifications. ([@palkan][])

Playing with ActiveRecord default scopes wasn't a good idea. We fallback to a more explicit way of _telling_ AR
when to load or ignore the `log_data` column.

This change removes `Logidze.with_log_data` method.

## 0.10.0 (2019-05-15)

- **Ruby >= 2.4 is required**

- PR [#111](https://github.com/palkan/logidze/pull/111) Global configuration for `:ignore_log_data` option ([@dmitrytsepelev][])

Now it's possible to avoid loading `log_data` from the DB by default with

```ruby
Logidze.ignore_log_data_by_default = true
```

In cases when `ignore_log_data: false` is explicitly passed to the `ignore_log_data` the default setting is being overriden. Also, it's possible to change it inside the block:

```ruby
Logidze.with_log_data do
  Post.find(params[:id]).log_data
end
```

- PR [#110](https://github.com/palkan/logidze/pull/110) Add `reset_log_data` API to nullify log_data column ([@Arkweid][])

Usage:

Reset the history for a record (or records):

```ruby
# for single record
record.reset_log_data

# for relation
User.where(active: true).reset_log_data
```

## 0.9.0 (2018-11-28)

- PR [#98](https://github.com/palkan/logidze/pull/98) Add `:ignore_log_data` option to `#has_logidze` ([@dmitrytsepelev][])

Usage:

```ruby
class User < ActiveRecord::Base
  has_logidze ignore_log_data: true
end

User.all #=> SELECT id, name FROM users

User.with_log_data #=> SELECT id, name, log_data FROM users

user = User.find(params[:id])
user.log_data #=> ActiveModel::MissingAttributeError
user.reload_log_data #=> Logidze::History
```

## 0.8.1 (2018-10-22)

- [PR #93](https://github.com/palkan/logidze/pull/93)] Return 0 for log size when log_data is nil ([@duderman][])

## 0.8.0 (2018-10-01)

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

The concept is similar to [https://underscorejs.org/#debounce](https://underscorejs.org/#debounce).

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

- [Fixes [#75](https://github.com/palkan/logidze/issues/70)] Fix association versioning with an optional belongs to ([@amalagaura][])

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

- _(Fix)_ Drop _all_ created functions upon rolling back ([commit](https://github.com/palkan/logidze/commit/b8e150cc18b3316a8cf0c78f7117339481fb49c6)). ([@vassilevsky][])

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
[@amalagaura]: https://github.com/amalagaura
[@dmitrytsepelev]: https://github.com/DmitryTsepelev
[@zocoi]: https://github.com/zocoi
[@duderman]: https://github.com/duderman
[@oleg-kiviljov]: https://github.com/oleg-kiviljov
[@skryukov]: https://github.com/skryukov
[@bf4]: https://github.com/bf4
[@cavi21]: https://github.com/cavi21
[@danielmklein]: https://github.com/danielmklein
[@baygeldin]: https://github.com/baygeldin
[@miharekar]: https://github.com/miharekar
[@prog-supdex]: https://github.com/prog-supdex
[@SparLaimor]: https://github.com/SparLaimor
[@tagirahmad]: https://github.com/tagirahmad
