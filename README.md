# timex_datalink_caldav

This gem provides a way to sync your CalDAV calendar events to your Timex Datalink watch. It fetches the next 15 non-all-day events from a specified CalDAV server and writes them to the watch as appointments.

## Installation

Replace `timex_datalink_caldav` with the name of your gem when it is released to RubyGems.org. 

Install the gem and add it to your application's Gemfile by executing:

    $ bundle add timex_datalink_caldav

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install timex_datalink_caldav

## Usage

First, initialize a `timex_datalink_caldav::Client` with your CalDAV server URL, username, password, and serial device path:

```ruby
client = timex_datalink_caldav::Client.new('user', 'password', 'http://yourserver.com:8008/calendars/users/user1/calendar/', '/dev/ttyACM0')
```

Then, call `write_to_watch` to fetch the events and write them to the watch:

```ruby
client.write_to_watch
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/timex_datalink_caldav. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/timex_datalink_caldav/blob/master/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the timex_datalink_caldav project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/timex_datalink_caldav/blob/master/CODE_OF_CONDUCT.md).