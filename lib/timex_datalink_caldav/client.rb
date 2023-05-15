require 'calendav'
require 'icalendar/recurrence'
require 'timex_datalink_client'
require 'active_support/time'

module TimexDatalinkCaldav
  class Client
    def initialize(user, password, server_url, serial_device)
      @user = user
      @password = password
      @server_url = server_url
      @serial_device = serial_device
    end

    def get_events
      credentials = Calendav::Credentials::Standard.new(
        host: @server_url,
        username: @user,
        password: @password,
        authentication: :basic_auth
      )

      # Create a new client with the credentials
      client = Calendav.client(credentials)

      # Get events from the calendar for the next day
      client.events.list(@server_url, from: Time.now, to: Time.now + 24*60*60)
    end

    def sync_to_watch
      events = get_events

      appointments = []
      appointment_map = {} # Used to avoid duplicate appointments

      events.each do |event|
        ical_events = Icalendar::Event.parse(event.calendar_data)
        if ical_events.any?
          ical_event = ical_events.first
          if ical_event.attendee&.any? # Exclude events without attendees
            next_occurrence = ical_event.occurrences_between(Time.now, Time.now + 24*60*60).first
            if next_occurrence
              est_time = next_occurrence.start_time.in_time_zone('Eastern Time (US & Canada)')
              key = "#{est_time}_#{ical_event.summary.to_s}"
              unless appointment_map[key] # Check if the event is already in the map
                puts "Adding appointment: #{ical_event.summary.to_s} at time #{est_time}"
                appointment = TimexDatalinkClient::Protocol1::Eeprom::Appointment.new(
                  time: est_time,
                  message: ical_event.summary.to_s
                )
                appointments << appointment
                appointment_map[key] = true
              end
            end
          end
        end
      end
      
      # Sort the appointments by time
      appointments.sort_by! { |appointment| appointment.time }
      write_to_watch(appointments)
    end

    def write_to_watch(appointments)
      time1 = Time.now

      models = [
        TimexDatalinkClient::Protocol1::Sync.new,
        TimexDatalinkClient::Protocol1::Start.new,
        TimexDatalinkClient::Protocol1::Time.new(
          zone: 1,
          time: time1,
          is_24h: false
        ),
        TimexDatalinkClient::Protocol1::TimeName.new(
          zone: 1,
          name: time1.zone
        ),
        TimexDatalinkClient::Protocol1::Eeprom.new(
          appointments: appointments,
          appointment_notification_minutes: 5
        ),
        TimexDatalinkClient::Protocol1::End.new
      ]

      timex_datalink_client = TimexDatalinkClient.new(
        serial_device: @serial_device,
        models: models,
        byte_sleep: 0.008,
        packet_sleep: 0.06,
        verbose: true
      )

      timex_datalink_client.write
    end
  end
end