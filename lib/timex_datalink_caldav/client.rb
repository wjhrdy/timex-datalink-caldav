require 'calendav'
require 'icalendar'
require 'icalendar/recurrence'
require 'timex_datalink_client'
require 'active_support/time'
require 'tzinfo'
require 'humanize'
require_relative 'similar_word'

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
                          when 7 then TimexDatalinkClient::Protocol7
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
    
      phrase_builder = SimlarWord.new(database: "pcvocab.mdb") if @protocol_version == 7
    
      events.each do |event|
        next unless event && event.dtstart && event.dtend
    
        summary_words = parse_summary(event)
    
        occurrences = event.occurrences_between(Time.now, Time.now + @days_forward*24*60*60)
    
        if @protocol_version == 7
          if all_day_event?(event)
            add_anniversary_event(anniversary_map, anniversaries, phrase_builder, summary_words, occurrences)
          else
            add_appointment_event(appointment_map, appointments, phrase_builder, summary_words, occurrences)
          end
        else
          if all_day_event?(event)
            add_anniversary(event, anniversary_map, anniversaries, summary_words, occurrences)
          else
            add_appointment(event, appointment_map, appointments, summary_words, occurrences)
          end
        end
      end
    
      [appointments, anniversaries]
    end
    
    def all_day_event?(event)
      (event.dtend.to_date - event.dtstart.to_date == 1) && event.dtstart.to_datetime.hour == 0 && event.dtstart.to_datetime.min == 0 && event.dtend.to_datetime.hour == 0 && event.dtend.to_datetime.min == 0
    end
    
    def parse_summary(event)
      event.summary.to_s.split.map do |word| 
        if word =~ /\A[a-zA-Z]+\z/
          word
        elsif word =~ /\A\d+\z/ 
          word.to_i.humanize
        end
      end.compact
    end
    
    def add_appointment_event(appointment_map, appointments, phrase_builder, summary_words, occurrences)
      occurrences.each do |occurrence|
        est_time = occurrence.start_time.in_time_zone(get_localzone)
        key = "#{est_time}_#{summary_words}"
        unless appointment_map[key]
          puts "Adding appointment event: #{summary_words.join(' ')} at time #{est_time}"
          event_phrase = phrase_builder.vocab_ids_for(*summary_words)
          appointment = @protocol_class::Eeprom::Calendar::Event.new(
            time: est_time,
            phrase: event_phrase
          )
          appointments << appointment
          appointment_map[key] = true
        end
      end
    end
    
    def add_anniversary_event(anniversary_map, anniversaries, phrase_builder, summary_words, occurrences)
      occurrences.each do |occurrence|
        est_time = occurrence.start_time.in_time_zone(get_localzone)
        key = "#{est_time}_#{summary_words.join(' ')}"
        unless anniversary_map[key]
          puts "Adding anniversary event: #{summary_words.join(' ')} at date #{event.dtstart.to_s}"
          event_phrase = phrase_builder.vocab_ids_for(*summary_words)
          anniversary = @protocol_class::Eeprom::Calendar::Event.new(
            time: Time.new(est_time.year, est_time.month, est_time.day, 9, 30, 0),
            phrase: event_phrase
          )
          anniversaries << anniversary
          anniversary_map[key] = true
        end
      end
    end
    
    def add_appointment(event, appointment_map, appointments, summary_words, occurrences)
      occurrences.each do |occurrence|
        est_time = occurrence.start_time.in_time_zone(get_localzone)
        key = "#{est_time}_#{summary_words}"
        unless appointment_map[key]
          puts "Adding appointment: #{summary_words.join(' ')} at time #{est_time}"
          appointment = @protocol_class::Eeprom::Appointment.new(
            time: est_time,
            message: summary_words.join(' ')
          )
          appointments << appointment
          appointment_map[key] = true
        end
      end
    end
    
    def add_anniversary(event, anniversary_map, anniversaries, summary_words, occurrences)
      occurrences.each do |occurrence|
        est_time = occurrence.start_time.in_time_zone(get_localzone)
        key = "#{est_time}_#{summary_words}"
        unless anniversary_map[key]
          puts "Adding anniversary: #{summary_words.join(' ')} at date #{event.dtstart.to_s}"
          anniversary = @protocol_class::Eeprom::Anniversary.new(
            time: event.dtstart.to_time,
            anniversary: summary_words.join(' ')
          )
          anniversaries << anniversary
          anniversary_map[key] = true
        end
      end
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
      elsif @protocol_version == 3 || @protocol_version == 4
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

      else
        time_model = nil
        utc_time_model = nil
        time_name_model = nil
        utc_time_name_model = nil
      end
      
      if @protocol_version == 7
        calendar = @protocol_class::Eeprom::Calendar.new(
          time: time1,
          events: appointments
        )
        models = [
          @protocol_class::Sync.new,
          @protocol_class::Start.new,
          @protocol_class::Eeprom.new(
            calendar: calendar
          )
        ]
      else
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
      end

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