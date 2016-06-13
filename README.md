[![Gem Version](https://badge.fury.io/rb/logidze.svg)](https://rubygems.org/gems/logidze) [![Build Status](https://travis-ci.org/palkan/logidze.svg?branch=master)](https://travis-ci.org/palkan/logidze) [![Circle CI](https://circleci.com/gh/palkan/logidze/tree/master.svg?style=svg)](https://circleci.com/gh/palkan/logidze/tree/master)

# Logidze

Logidze provides tools for logging DB records changes.
**This is not [audited](https://github.com/collectiveidea/audited) or [paper_trail](https://github.com/airblade/paper_trail) alternative!**

Logidze allows you to create a DB-level log (using triggers) and gives you an API to browse this log.
The log is stored with the record itself in JSONB column. No additional tables required.
Currently, only PostgreSQL 9.5+ is supported.

Other requirements:
- Ruby ~> 2.3;
- Rails ~> 4.2;

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

You can provide `limit` option to `generate` to limit the size of the log (by default it's unlimited):

```ruby
rails generate logidze:model Post --limit=10
```

This also adds `has_logidze` line to your model, which adds methods for working with logs.

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
old_post = post.at(2.days.ago)

# or revert the record itself to the previous state (without committing to DB)
post.at!('201-04-15 12:00:00')

# If no version found
post.at('1945-05-09 09:00:00') #=> nil
```

You can also get revision by version number:

```ruby
post.at_version(2)
```

It is also possible to get version for relations:

```ruby
Post.where(active: true).at(1.month.ago)
```

You can also get diff from specified time:

```ruby
post.diff_from(1.hour.ago)
#=> { "id" => 27, "changes" => { "title" => { "old" => "Logidze sucks!", "new" => "Logidze rulz!" } } }

# the same for relations
Post.where(created_at: Time.zone.today.all_day).diff_from(1.hour.ago)
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

If you update record after `#undo!` or `#switch_to!` you lose all "future" versions and `#redo!` is no longer possible.

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
            }
        }
    ]
}
```

If you specify the limit in you trigger definition then log size will not exceed the specified size. When a new change occurs, and there is no more room for it, the two oldest changes will be merged.

## Development

For development setup run `./bin/setup`. This runs `bundle install` and creates test DB.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/logidze.


## TODO

- Exclude columns from log
- Enhance `update_all` to support mass-logging
- Other DB adapters

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
