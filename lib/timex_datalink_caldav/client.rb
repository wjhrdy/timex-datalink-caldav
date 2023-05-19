require 'calendav'
require 'icalendar'
require 'icalendar/recurrence'
require 'timex_datalink_client'
require 'active_support/time'
require 'tzinfo'

module TimexDatalinkCaldav
  class Client
    def initialize(user, password, server_url, serial_device, protocol_version, days_forward = 1)
      @user = user
      @password = password
      @server_url = server_url
      @serial_device = serial_device
      @days_forward = days_forward
      @protocol_version = protocol_version.to_i
      @protocol_class = case @protocol_version
                        when 1 then TimexDatalinkClient::Protocol1
                        when 3 then TimexDatalinkClient::Protocol3
                        when 4 then TimexDatalinkClient::Protocol4
                        else
                          raise ArgumentError, "Invalid protocol version: #{@protocol_version}"
                        end
                      end

    def get_localzone
      TZInfo::Timezone.get(TZInfo::Timezone.all_country_zones.detect {|z| z.period_for_local(Time.now).utc_total_offset == Time.now.utc_offset}.identifier)
    end

    def get_events
      credentials = Calendav::Credentials::Standard.new(
        host: @server_url,
        username: @user,
        password: @password,
        authentication: :basic_auth
      )

      if @user && @password
        # Create a new client with the credentials
        client = Calendav.client(credentials)

        # Get events from the calendar for the next day
        caldav_events = client.events.list(@server_url, from: Time.now, to: Time.now + @days_forward*24*60*60)
        events = caldav_events.map { |event| Icalendar::Event.parse(event.calendar_data).first }
      else
        cal_file = URI.open(@server_url)
        cals = Icalendar::Calendar.parse(cal_file)
        cal = cals.first
        events = cal.events
      end

      events
    end

    def parse_events
      events = get_events
    
      appointments = []
      anniversaries = []
      appointment_map = {} # Used to avoid duplicate appointments
      anniversary_map = {} # Used to avoid duplicate anniversaries
      
      events.each do |event|
        next unless event

        if event.dtstart && event.dtend && (event.dtend.to_date - event.dtstart.to_date == 1) && event.dtstart.to_datetime.hour == 0 && event.dtstart.to_datetime.min == 0 && event.dtend.to_datetime.hour == 0 && event.dtend.to_datetime.min == 0 # Checking if it is an all day event
          occurrences = event.occurrences_between(Time.now, Time.now + @days_forward*24*60*60)
          occurrences.each do |occurrence|
            est_time = occurrence.start_time.in_time_zone(get_localzone)
            key = "#{est_time}_#{event.summary.to_s}"
            puts key
            unless anniversary_map[key] # Check if the event is already in the map
              puts "Adding anniversary: #{event.summary.to_s} at date #{event.dtstart.to_s}"
              anniversary = @protocol_class::Eeprom::Anniversary.new(
                time: event.dtstart.to_time,
                anniversary: event.summary.to_s
              )
              anniversaries << anniversary
              anniversary_map[key] = true
            end
          end
        elsif event.dtstart && event.dtend
          occurrences = event.occurrences_between(Time.now, Time.now + @days_forward*24*60*60)
          occurrences.each do |occurrence|
            est_time = occurrence.start_time.in_time_zone(get_localzone)
            key = "#{est_time}_#{event.summary.to_s}"
            unless appointment_map[key] # Check if the event is already in the map
              puts "Adding appointment: #{event.summary.to_s} at time #{est_time}"
              appointment = @protocol_class::Eeprom::Appointment.new(
                time: est_time,
                message: event.summary.to_s
              )
              appointments << appointment
              appointment_map[key] = true
            end
          end
        end
      end
      
      [appointments, anniversaries]
    end

    def write_to_watch(appointments, anniversaries)
      appointments.sort_by! { |appointment| appointment.time }
      # add 3 because it always seems to be about 3 seconds behind.
      time1 = Time.now + 3
      time2 = time1.dup.utc
      
      if @protocol_version == 1
        time_model = @protocol_class::Time.new(
          zone: 1,
          time: time1,
          is_24h: false
        )
        time_name_model = @protocol_class::TimeName.new(
          zone: 1,
          name: time1.zone
        )
        utc_time_model = @protocol_class::Time.new(
          zone: 2,
          time: time2,
          is_24h: true
        )
        utc_time_name_model = @protocol_class::TimeName.new(
          zone: 2,
          name: time2.zone
        )
      else
        time_model = @protocol_class::Time.new(
          zone: 1,
          name: time1.zone,
          time: time1,
          is_24h: false,
          date_format: "%_m-%d-%y"
        )
        utc_time_model = @protocol_class::Time.new(
          zone: 2,
          name: "UTC",
          time: time2,
          is_24h: true,
          date_format: "%y-%m-%d"
        )
        time_name_model = nil # Not needed for protocol version 3 and 4
        utc_time_name_model = nil # Not needed for protocol version 3 and 4

      end

      models = [
        @protocol_class::Sync.new,
        @protocol_class::Start.new,
        time_model,
        time_name_model,
        utc_time_model,
        utc_time_name_model,
        @protocol_class::Eeprom.new(
          appointments: appointments,
          anniversaries: anniversaries,
          appointment_notification_minutes: 5
        ),
        @protocol_class::End.new
      ].compact # Remove any nil entries

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