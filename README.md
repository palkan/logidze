[![Gem Version](https://badge.fury.io/rb/logidze.svg)](https://rubygems.org/gems/logidze) [![Build Status](https://travis-ci.org/palkan/logidze.svg?branch=master)](https://travis-ci.org/palkan/logidze) [![Circle CI](https://circleci.com/gh/palkan/logidze/tree/master.svg?style=svg)](https://circleci.com/gh/palkan/logidze/tree/master)
[![Dependency Status](https://dependencyci.com/github/palkan/logidze/badge)](https://dependencyci.com/github/palkan/logidze)

# Logidze

Logidze provides tools for logging DB records changes. Just like [audited](https://github.com/collectiveidea/audited) and [paper_trail](https://github.com/airblade/paper_trail) do (but [faster](bench/performance)).

Logidze allows you to create a DB-level log (using triggers) and gives you an API to browse this log.
The log is stored with the record itself in JSONB column. No additional tables required.
Currently, only PostgreSQL 9.5+ is supported (for PostgreSQL 9.4 try [jsonbx](http://www.pgxn.org/dist/jsonbx/1.0.0/) extension).

[Read the story behind Logidze](https://evilmartians.com/chronicles/introducing-logidze?utm_source=logidze)

Other requirements:
- Ruby ~> 2.1
- Rails >= 4.2

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Installation

1. Add Logidze to your application's Gemfile:

```ruby
gem 'logidze'
```

2. Install required DB extensions and create trigger function:

```ruby
rails generate logidze:install
```

This creates migration for adding trigger function and enabling hstore extension.

Run migrations:

```ruby
rake db:migrate
```

3. Add log column and triggers to the model:

```ruby
rails generate logidze:model Post
rake db:migrate
```

This also adds `has_logidze` line to your model, which adds methods for working with logs.

You can provide `limit` option to `generate` to limit the size of the log (by default it's unlimited):

```ruby
rails generate logidze:model Post --limit=10
```

To backfill table data (i.e. create initial snapshots) add `backfill` option:

```ruby
rails generate logidze:model Post --backfill
```

You can log only particular columns changes. There are mutually exclusive `blacklist` and `whitelist` options for this:

```ruby
# track all columns, except `created_at` and `active`
rails generate logidze:model Post --blacklist=created_at active
# track only `title` and `body` columns
rails generate logidze:model Post --whitelist=title body
```

By default, Logidze tries to infer the path to the model file from the model name and may fail, for example, if you have unconventional project structure. In that case you should specify the path explicitly:

```ruby
rails generate logidze:model Post --path "app/models/custom/post.rb"
```

By default, Logidze tries to get a timestamp for a version from record's `updated_at` field whenever appropriate. If
your model does not have that column, Logidze will gracefully fall back to `statement_timestamp()`.
To change the column name or disable this feature completely, you can use the `timestamp_column` option:

```ruby
# will try to get the timestamp value from `time` column
rails generate logidze:model Post --timestamp_column time
# will always set version timestamp to `statement_timestamp()`
rails generate logidze:model Post --timestamp_column nil # "null" and "false" will also work
```

If you want to update Logidze settings for the model, run migration with `--update` flag:

```ruby
rails generate logidze:model Post --update --whitelist=title body rating
```

Logidze also supports associations versioning. It is experimental feature, and disabled by default. You can learn more
in the [wiki](https://github.com/palkan/logidze/wiki/Associations-versioning).

## Troubleshooting

The most common problem is `"permission denied to set parameter "logidze.xxx"` caused by `ALTER DATABASE ...` query.
Logidze requires at least database owner privileges (which is not always possible).

Here is a quick and straightforward [workaround](https://github.com/palkan/logidze/issues/11#issuecomment-260703464) by [@nobodyzzz](https://github.com/nobodyzzz).

**NOTE**: if you're using PostgreSQL >= 9.6 you need neither the workaround nor owner privileges because Logidze (>= 0.3.1) can work without `ALTER DATABASE ...`.

Nevertheless, you still need super-user privileges to enable `hstore` extension (or you can use [PostgreSQL Extension Whitelisting](https://github.com/dimitri/pgextwlist)).


## Upgrade from previous versions

We try to make upgrade process as simple as possible. For now, the only required action is to create and run a migration:

```ruby
rails generate logidze:install --update
```

This updates core `logdize_logger` DB function. No need to update tables or triggers.

## Usage

Your model now has `log_data` column which stores changes log.

To retrieve record version at a given time use `#at` or `#at!` methods:

```ruby
post = Post.find(27)

# Show current version
post.log_version #=> 3

# Show log size (number of versions)
post.log_size #=> 3

# Get copy of a record at a given time
old_post = post.at(time: 2.days.ago)

# or revert the record itself to the previous state (without committing to DB)
post.at!(time: '201-04-15 12:00:00')

# If no version found
post.at(time: '1945-05-09 09:00:00') #=> nil
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

Normally, if you update record after `#undo!` or `#switch_to!` you lose all "future" versions and `#redo!` is no
longer possible. However, you can provide an `append: true` option to `#undo!` or `#switch_to!`, which will
create a new version with old data. Caveat: when switching to a newer version, `append` will have no effect.

```ruby
post = Post.create!(title: 'first post') # v1
post.update!(title: 'new title')         # v2
post.undo!(append: true)                 # v3 (with same attributes as v1)
```

Note that `redo!` will not work after `undo!(append: true)` because the latter will create a new version
instead of rolling back to an old one.
Alternatively, you can configure Logidze to always default to `append: true`.

```ruby
Logidze.append_on_undo = true
```


## Track responsibility (aka _whodunnit_)

You can store additional information in the version object, which is called _Responsible ID_. There is more likely that you would like to store the `current_user.id` that way.

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

Logidze does not require `responsible_id` to be `SomeModel` ID. It can be anything. Thus Logidze does not provide methods for retrieving the corresponding object. However, you can easy write it yourself:

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
  around_action :set_logidze_responsible, only: [:create, :update]

  def set_logidze_responsible(&block)
    Logidze.with_responsible(current_user&.id, &block)
  end
end
```

## Disable logging temporary

If you want to make update without logging (e.g. mass update), you can turn it off the following way:

```ruby
Logidze.without_logging { Post.update_all(seen: true) }

# or

Post.without_logging { Post.update_all(seen: true) }
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
        "r": 42 // Resposibility ID (if provided)
      }
    ]
}
```

If you specify the limit in the trigger definition then log size will not exceed the specified size. When a new change occurs, and there is no more room for it, the two oldest changes will be merged.

## Development

For development setup run `./bin/setup`. This runs `bundle install` and creates test DB.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/logidze.


## TODO

- Enhance update_all to support mass-logging.
- Other DB adapters.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
