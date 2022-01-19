require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

DAYS = %w[SUNDAY MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY]

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  number = number.gsub!(/\D/, '').to_s
  if number.length < 10
    ''
  elsif number.length == 11 && number[0] == 1
    number.chop
  else
    number
  end
end

def find_max_count(array)
  array.max_by { |i| array.count(i) }
end

def int_to_day(int); end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'
contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
registered_hours = []
registered_days = []

contents.each do |row|
  id = row[0]

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phonenumber = clean_phone_number(row[:homephone])

  registered_time = Time.strptime(row[:regdate], '%m/%d/%y %k:%M')
  registered_hours.push(registered_time.hour)
  registered_days.push(registered_time.wday)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
puts "Best hour: #{find_max_count(registered_hours)}"
puts "Best day: #{DAYS[find_max_count(registered_days)]}"
