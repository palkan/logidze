[![Cult Of Martians](http://cultofmartians.com/assets/badges/badge.svg)](http://cultofmartians.com) [![Gem Version](https://badge.fury.io/rb/logidze.svg)](https://rubygems.org/gems/logidze) [![Build Status](https://travis-ci.org/palkan/logidze.svg?branch=master)](https://travis-ci.org/palkan/logidze) [![Open Source Helpers](https://www.codetriage.com/palkan/logidze/badges/users.svg)](https://www.codetriage.com/palkan/logidze)

# Logidze

Logidze provides tools for logging DB records changes. Just like [audited](https://github.com/collectiveidea/audited) and [paper_trail](https://github.com/airblade/paper_trail) do (but [faster](bench/performance)).

Logidze allows you to create a DB-level log (using triggers) and gives you an API to browse this log.
The log is stored with the record itself in JSONB column. No additional tables required.
Currently, only PostgreSQL 9.5+ is supported (for PostgreSQL 9.4 try [jsonbx](http://www.pgxn.org/dist/jsonbx/1.0.0/) extension).

[Read the story behind Logidze](https://evilmartians.com/chronicles/introducing-logidze?utm_source=logidze)

[How is Logidze pronounced?](https://github.com/palkan/logidze/issues/73)

Other requirements:
- Ruby ~> 2.1
- Rails >= 4.2 (**Rails 6 is supported**)

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Installation

Add Logidze to your application's Gemfile:

```ruby
gem "logidze"
```

Install required DB extensions and create trigger function:

```sh
rails generate logidze:install
```

This creates a migration for adding trigger function and enabling the hstore extension.

Run migrations:

```sh
rake db:migrate
```

**NOTE:** you **must** use SQL schema format since Logidze uses DB functions and triggers:

```ruby
# application.rb
config.active_record.schema_format = :sql
```

3. Add log column and triggers to the model:

```sh
rails generate logidze:model Post
rake db:migrate
```

This also adds `has_logidze` line to your model, which adds methods for working with logs.

You can provide the `limit` option to `generate` to limit the size of the log (by default it's unlimited):

```sh
rails generate logidze:model Post --limit=10
```

To backfill table data (i.e., create initial snapshots) add `backfill` option:

```sh
rails generate logidze:model Post --backfill
```

You can log only particular columns changes. There are mutually exclusive `blacklist` and `whitelist` options for this:

```sh
# track all columns, except `created_at` and `active`
rails generate logidze:model Post --blacklist=created_at active
# track only `title` and `body` columns
rails generate logidze:model Post --whitelist=title body
```

By default, Logidze tries to infer the path to the model file from the model name and may fail, for example, if you have unconventional project structure. In that case, you should specify the path explicitly:

```sh
rails generate logidze:model Post --path "app/models/custom/post.rb"
```

By default, Logidze tries to get a timestamp for a version from record's `updated_at` field whenever appropriate. If
your model does not have that column, Logidze will gracefully fall back to `statement_timestamp()`.
To change the column name or disable this feature completely, you can use the `timestamp_column` option:

```sh
# will try to get the timestamp value from `time` column
rails generate logidze:model Post --timestamp_column time
# will always set version timestamp to `statement_timestamp()`
rails generate logidze:model Post --timestamp_column nil # "null" and "false" will also work
```

If you want to update Logidze settings for the model, run migration with `--update` flag:

```sh
rails generate logidze:model Post --update --whitelist=title body rating
```

Logidze also supports associations versioning. It is an experimental feature and disabled by default. You can learn more
in the [wiki](https://github.com/palkan/logidze/wiki/Associations-versioning).

## Troubleshooting

The most common problem is `"permission denied to set parameter "logidze.xxx"` caused by `ALTER DATABASE ...` query.
Logidze requires at least database owner privileges (which is not always possible).

Here is a quick and straightforward [workaround](https://github.com/palkan/logidze/issues/11#issuecomment-260703464) by [@nobodyzzz](https://github.com/nobodyzzz).

**NOTE**: if you're using PostgreSQL >= 9.6 you need neither the workaround nor owner privileges because Logidze (>= 0.3.1) can work without `ALTER DATABASE ...`.

Nevertheless, you still need super-user privileges to enable `hstore` extension (or you can use [PostgreSQL Extension Whitelisting](https://github.com/dimitri/pgextwlist)).


## Upgrade from previous versions

We try to make an upgrade process as simple as possible. For now, the only required action is to create and run a migration:

```sh
rails generate logidze:install --update
```

This updates core `logdize_logger` DB function. No need to update tables or triggers.

## Usage

Your model now has `log_data` column, which stores changes log.

To retrieve record version at a given time use `#at` or `#at!` methods:

```ruby
post = Post.find(27)

# Show current version
post.log_version #=> 3

# Show log size (number of versions)
post.log_size #=> 3

# Get copy of a record at a given time
post.at(time: 2.days.ago)

# or revert the record itself to the previous state (without committing to DB)
post.at!(time: "2018-04-15 12:00:00")

# If no version found
post.at(time: "1945-05-09 09:00:00") #=> nil
```

You can also get revision by version number:

```ruby
post.at(version: 2)
```

It is also possible to get version for relations:

```ruby
Post.where(active: true).at(time: 1.month.ago)
```

You can also get diff from specified time:

```ruby
post.diff_from(time: 1.hour.ago)
#=> { "id" => 27, "changes" => { "title" => { "old" => "Logidze sucks!", "new" => "Logidze rulz!" } } }

# the same for relations
Post.where(created_at: Time.zone.today.all_day).diff_from(time: 1.hour.ago)
```

There are also `#undo!` and `#redo!` options (and more general `#switch_to!`):

```ruby
# Revert record to the previous state (and stores this state in DB)
post.undo!

# You can now user redo! to revert back
post.redo!

# More generally you can revert record to arbitrary version
post.switch_to!(2)
```

You can initiate reloading of `log_data` from the DB:

```ruby
post.reload_log_data # => returns the latest log data value
```

Typically, if you update record after `#undo!` or `#switch_to!` you lose all "future" versions and `#redo!` is no
longer possible. However, you can provide an `append: true` option to `#undo!` or `#switch_to!`, which will
create a new version with old data. Caveat: when switching to a newer version, `append` will have no effect.

```ruby
post = Post.create!(title: "first post") # v1
post.update!(title: "new title")         # v2
post.undo!(append: true)                 # v3 (with same attributes as v1)
```

Note that `redo!` will not work after `undo!(append: true)` because the latter will create a new version
instead of rolling back to an old one.
Alternatively, you can configure Logidze always to default to `append: true`.

```ruby
Logidze.append_on_undo = true
```

### How to not load log data by default, or dealing with large logs

By default, Active Record _selects_ all the table columns when no explicit `select` statement specified.

That could slow down queries execution if you have field values which exceed the size of the data block (typically 8KB). PostgreSQL turns on its [TOAST](https://wiki.postgresql.org/wiki/TOAST) mechanism), which requires reading from multiple physical locations for fetching the row's data.

If you do not use compaction (`generate logidze:model ... --limit N`) for `log_data`, you're likely to face this problem.

Logidze provides a way to avoid loading `log_data` by default (and load it on demand):

```ruby
class User < ActiveRecord::Base
  # Add `ignore_log_data` option to macros
  has_logidze ignore_log_data: true
end
```

If you want Logidze always to behave this way - you can set up a global configuration option:

```ruby
Rails.application.config.logidze.ignore_log_data_by_default = true
```

However, you can override it by explicitly passing `ignore_log_data: false` to the `ignore_log_data`. Also, it's possible to change it temporary inside the block:

```ruby
Logidze.with_log_data do
  Post.find(params[:id]).log_data
end
```

When `ignore_log_data` is turned on, each time you use `User.all` (or any other Relation method) `log_data` won't be loaded from the DB.

The chart below shows the difference in PG query time before and after turning `ignore_log_data` on. (Special thanks to [@aderyabin](https://github.com/aderyabin) for sharing it.)

![](./assets/pg_log_data_chart.png)

If you try to call `#log_data` on the model loaded in such way, you'll get `ActiveModel::MissingAttributeError`, but if you really need it (e.g., during the console debugging) - use **`user.reload_log_data`**, which forces loading the column from the DB.

If you need to select `log_data` during the initial load-use a special scope `User.with_log_data`.

## Track meta information

You can store any meta information you want inside your version (it could be IP address, user agent, etc.). To add it you should wrap your code with a block:

```ruby
Logidze.with_meta(ip: request.ip) do
  post.save!
end
```

Meta expects a hash to be passed so you won't need to encode and decode JSON manually.

## Track responsibility (aka _whodunnit_)

A special application of meta information is storing the author of the change, which is called _Responsible ID_. There is more likely that you would like to store the `current_user.id` that way.

To provide `responsible_id` you should wrap your code in a block:

```ruby
Logidze.with_responsible(user.id) do
  post.save!
end
```

And then to retrieve `responsible_id`:

```ruby
post.log_data.responsible_id
```

Logidze does not require `responsible_id` to be `SomeModel` ID. It can be anything. Thus Logidze does not provide methods for retrieving the corresponding object. However, you can easily write it yourself:

```ruby
class Post < ActiveRecord::Base
  has_logidze

  def whodunnit
    id = log_data.responsible_id
    User.find(id) if id.present?
  end
end
```

And in your controller:

```ruby
class ApplicationController < ActionController::Base
  around_action :use_logidze_responsible, only: %i[create update]

  def use_logidze_responsible(&block)
    Logidze.with_responsible(current_user&.id, &block)
  end
end
```

## Disable logging temporary

If you want to make update without logging (e.g., mass update), you can turn it off the following way:

```ruby
Logidze.without_logging { Post.update_all(seen: true) }

# or

Post.without_logging { Post.update_all(seen: true) }
```

## Reset log

Reset the history for a record (or records):

```ruby
# for a single record
record.reset_log_data

# for relation
User.where(active: true).reset_log_data
```

## Log format

The `log_data` column has the following format:

```js
{
  "v": 2, // current record version,
  "h": // list of changes
    [
      {
        "v": 1,  // change number
        "ts": 1460805759352, // change timestamp in milliseconds
        "c": {
            "attr": "new value",  // updated fields with new values
            "attr2": "new value"
            },
        "r": 42, // Resposibility ID (if provided), not in use since 0.7.0
        "m": {
          "_r": 42 // Resposibility ID (if provided), in use since 0.7.0
          // any other meta information provided, please see Track meta information section for the details
        }
      }
    ]
}
```

If you specify the limit in the trigger definition, then log size will not exceed the specified size. When a new change occurs, and there is no more room for it, the two oldest changes will be merged.

## Development

For development setup run `./bin/setup`. This runs `bundle install` and creates test DB.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/logidze.

## Future ideas

- Enhance update_all to support mass-logging.
- Other DB adapters.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
