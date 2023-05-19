# TimexDatalinkCaldav

TimexDatalinkCaldav is a simple Ruby gem designed to sync events from a CalDAV server or an ical formatted ics file to a Timex Datalink watch. It can also be used as a standalone command-line interface (CLI) tool.

## Pre-requisites

If you need to install Ruby, follow the Ruby installation instructions [here](https://www.ruby-lang.org/en/documentation/installation/).

## Installation

To install the TimexDatalinkCaldav gem, simply run:

```sh
gem install timex_datalink_caldav
```

Or add this line to your application's Gemfile:

```ruby
gem "timex_datalink_caldav"
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

client = TimexDatalinkCaldav::Client.new(your_username, your_password, your_server_uri, your_device, your_protocol_version, days_forward)

client.parse_events
client.write_to_watch
```

### As a CLI Tool

After installing the gem, you can use it as a CLI tool. You can specify the CalDAV server details directly on the command line:

```sh
timex_datalink_caldav -u https://caldavendpoint.com -n your_username -p your_password -d your_device -a your_protocol_version -f days_forward
```

Please replace `https://caldavendpoint.com`, `your_username`, `your_password`, `your_device`, `your_protocol_version`, and `days_forward` with your actual CalDAV server URI, username, password, serial device, protocol version, and number of days to look forward for events, respectively.

Or you can provide these details in a configuration file:

```sh
timex_datalink_caldav -c config.yml -a 1 -d /dev/tty.usbmodem0000000000001 -f 7
```

The configuration file should be a YAML file in the following format:

```yaml
endpoints:
  - uri: https://www.google.com/calendar/dav/email@gmail.com/events
    user: email@gmail.com
    password: app_password
  - uri: https://caldavendpoint2.com
    user: your_username2
    password: your_password2
  - uri: https://icalendpoint.com/example.ics
```

The device is a serial device that flashes an led when it receives data. On Linux, this is usually `/dev/tty*`. On macOS, this is usually `$(ls /dev/tty.usbmodem* | head -n 1)`. On Windows, this is usually `COM1`.

If you want to use this, I highly recommend pairing it with the Raspberry Pi Pico and [this project](https://github.com/famiclone6502/DIY_Datalink_Adapter). It is the cheapest and easiest way to get a serial device that works with the Timex Datalink watch.

## Notes

- This gem is not affiliated with Timex, nor is it affiliated with any CalDAV server. It is simply a tool that I wrote to sync my events from my CalDAV server to my Timex Datalink watch.

- This gem uses the anniversary feature for full day events, and the appointments feature for events with a start and end time.
