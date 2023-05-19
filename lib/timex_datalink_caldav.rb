require 'optparse'
require 'yaml'
require 'open-uri'
require_relative "timex_datalink_caldav/client"

module TimexDatalinkCaldav
  class CLI
    def initialize(arguments)
      @options = parse_options(arguments)
    end

    def execute
      all_appointments = []
      all_anniversaries = []
      
      @options[:endpoints].each do |endpoint|
        client = TimexDatalinkCaldav::Client.new(endpoint[:user], endpoint[:password], endpoint[:uri], @options[:device], @options[:api], @options[:days_forward])
        appointments, anniversaries = client.parse_events
        all_appointments.concat(appointments) if appointments.any?
        all_anniversaries.concat(anniversaries) if anniversaries.any?
      end
    
      if all_appointments.any? || all_anniversaries.any?
        client = TimexDatalinkCaldav::Client.new(
          @options[:endpoints][0][:user],
          @options[:endpoints][0][:password],
          @options[:endpoints][0][:uri],
          @options[:device],
          @options[:api],
          @options[:days_forward]
        )
        client.write_to_watch(all_appointments, all_anniversaries)
      end
    end

    private

    def parse_options(arguments)
      options = { days_forward: 1 }
      cli_endpoint = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: timex_datalink_caldav [options]"

        opts.on("-c", "--config FILE", "Configuration file") do |v|
          raise ArgumentError, "Both CLI options and configuration file provided. Please provide only one." if cli_endpoint.any?
          parsed_config = YAML.load_file(v)
          options[:endpoints] = parsed_config['endpoints'].map do |endpoint|
            endpoint.each_with_object({}) { |(k, v), result| result[k.to_sym] = v }
          end
        end

        opts.on("-u", "--uri URI", "CalDAV server URI") do |v|
          cli_endpoint[:uri] = v
        end

        opts.on("-n", "--user USERNAME", "Username for CalDAV server") do |v|
          cli_endpoint[:user] = v
        end

        opts.on("-p", "--password PASSWORD", "Password for CalDAV server") do |v|
          cli_endpoint[:password] = v
        end

        opts.on("-d", "--device DEVICE", "Serial device for Timex Datalink watch") do |v|
          options[:device] = v
        end

        opts.on("-a", "--api PROTOCOL_VERSION", "Protocol Version") do |v|
          options[:api] = v
        end

        opts.on("-f", "--forward DAYS", Integer, "Number of days to look forward for events") do |v|
          options[:days_forward] = v
        end
      end.parse!(arguments)
      
      options[:endpoints] = [cli_endpoint] if cli_endpoint.any? and options[:endpoints].nil?
      options
    end
  end
end