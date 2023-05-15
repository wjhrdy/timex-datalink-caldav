# frozen_string_literal: true
require 'optparse'

require_relative "timex_datalink_caldav/client"

module TimexDatalinkCaldav
  class CLI
    def initialize(arguments)
      @options = parse_options(arguments)
    end

    def execute
      client = TimexDatalinkCaldav::Client.new(@options.fetch(:user), @options.fetch(:password), @options.fetch(:uri), @options.fetch(:device))
      client.sync_to_watch
    end

    private

    def parse_options(arguments)
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: timex_datalink_caldav [options]"

        opts.on("-u", "--uri URI", "CalDAV server URI") do |v|
          options[:uri] = v
        end

        opts.on("-n", "--user USERNAME", "Username for CalDAV server") do |v|
          options[:user] = v
        end

        opts.on("-p", "--password PASSWORD", "Password for CalDAV server") do |v|
          options[:password] = v
        end

        opts.on("-d", "--device DEVICE", "Serial device for Timex Datalink watch") do |v|
          options[:device] = v
        end
      end.parse!(arguments)
      options
    end
  end
end
