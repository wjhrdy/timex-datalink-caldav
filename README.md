# TimexDatalinkCaldav

TimexDatalinkCaldav is a simple Ruby gem designed to sync events from a CalDAV server to a Timex Datalink watch. It can also be used as a standalone command-line interface (CLI) tool.

## Installation

To install the TimexDatalinkCaldav gem, simply run:

```sh
gem install timex_datalink_caldav
```

Or add this line to your application's Gemfile:

```ruby
source "https://rubygems.pkg.github.com/wjhrdy" do
  gem "timex_datalink_caldav"
end
```

And then execute:

```sh
bundle install
```

## Usage

### As a Gem

Here's an example of how to use the tool in your Ruby code:

```ruby
require 'timex_datalink_caldav'

client = TimexDatalinkCaldav::Client.new(your_username, your_password, your_server_uri, your_device)
client.sync_to_watch
```

### As a CLI Tool

After installing the gem, you can use it as a CLI tool:

```sh
timex_datalink_caldav -u https://caldavendpoint.com -n your_username -p your_password -d your_device
```

Please replace `your_username`, `your_password`, and `your_device` with your actual CalDAV server username, password, and device respectively. In this example, we're using Apple's iCloud CalDAV server. You'll need to replace this with the URI of your own CalDAV server if you're not using iCloud.

## Note

Ensure you have the necessary dependencies installed on your system and you have the correct permissions to access the specified device. 

The tool currently works with events that have attendees and converts event times to Eastern Standard Time (EST). Events are sorted by time before syncing to the watch.

## Resources

If you want to use this I highly recommend pairing it with the Raspberry Pi Pico and [this project](https://github.com/famiclone6502/DIY_Datalink_Adapter).