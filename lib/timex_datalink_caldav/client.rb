require 'twisted-caldav'
require 'timex_datalink_client'
require 'active_support/time'

module timex_datalink_caldav
  class Client
    def initialize(user, password, server_url, serial_device)
      @user = user
      @password = password
      @server_url = server_url
      @serial_device = serial_device

      Time.zone = "Eastern Time (US & Canada)"  # set the time zone to EST
    end

    def write_to_watch
      # Initialize the API
      cal = TwistedCaldav::Client.new(uri: @server_url, 
                                      user: @user, 
                                      password: @password)

      # Fetch the next 15 non-all-day events for the user
      events = cal.find_events(start: Time.now.strftime('%Y-%m-%d'), 
                               end: (Time.now + 30.days).strftime('%Y-%m-%d')).first(15)

      puts "Upcoming events:"
      puts "No upcoming events found" if events.empty?

      appointments = events.map do |event|
        start = event.start
        start = start.new_offset(Rational(Time.zone.utc_offset, 24*60))  # convert the time to EST
        TimexDatalinkClient::Protocol1::Eeprom::Appointment.new(
          time: Time.new(start.year, start.month, start.day, start.hour, start.minute),
          message: event.summary
        )
      end

      # replace the existing appointments with the ones from the CalDAV server
      eeprom_model = models.find { |model| model.is_a?(TimexDatalinkClient::Protocol1::Eeprom) }
      eeprom_model.appointments = appointments
      eeprom_model.appointment_notification_minutes = 15  # set the notification time to 15 minutes

      timex_datalink_client = TimexDatalinkClient.new(
        serial_device: @serial_device,
        models: models,
        verbose: true
      )

      timex_datalink_client.write
    end
  end
end