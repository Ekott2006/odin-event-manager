require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end
def clean_phone_number(number)
  cleaned_number = number.gsub(/\D+/, '')
  cleaned_number = cleaned_number[1..10] if cleaned_number.match?(/1\d{10}/)
  cleaned_number if cleaned_number.match?(/\d{10}/)
end


def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hour_count = Hash.new(0)
day_count = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  row[:homephone] = clean_phone_number(row[:homephone])
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  date = Time.strptime(row[:regdate], '%m/%d/%y %H:%M')
  hour_count[date.hour] += 1
  day_count[date.wday] += 1
end

puts '5 most active hours are: '
hour_count.sort_by { |_, value| value}.reverse[0..4].each do |(h, f)|
  puts "#{Time.strptime(h.to_s, '%H').strftime('%R')} had #{f} registrations "
end

puts '3 most active days are: '
day_count.sort_by { |_, value| value}.reverse[0..2].each do |(h, f)|
  puts "#{Date::DAYNAMES[h]} had #{f} registrations "
end
