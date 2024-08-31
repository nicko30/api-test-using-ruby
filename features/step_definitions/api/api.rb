# Created on 23/07/2024 @sebastianicko

Given(/client without auth/) do
  @headers = {
    "Content-Type": "application/json"
  }
end

Given(/client without headers/) do
  @headers = {}
end

Given(/^client set headers as:$/) do |headers_json|
  headers = JSON.parse(APIHelper.resolve_env(self, headers_json))
  headers = JSON.parse(APIHelper.resolve_variable(self, headers_json))

  # Handle when @headers nil
  @headers ||= {}

  headers.each do |key, value|
    if key == "Content-Type"
      @headers[:"Content-Type"] = headers["Content-Type"]
    else
      @headers[key] = value
    end
  end
end

When(/^client sends a (GET|POST|PUT|DELETE|PATCH) request to "(.*)"(?: with body:)?$/) do |method, endpoint, *args|
  body = args.shift

  # when body call ENV FILE
  body = body ? APIHelper.resolve_env(self, body) : nil
  body = body ? APIHelper.resolve_variable(self, body) : nil
  body_json = body ? JSON.parse(body) : nil

  # Handle when @headers nil
  @headers ||= {}

  # when content-type is application/json generate body to_json
  @body = JSON.parse(@headers.to_json)["Content-Type"] == "application/json" ? body_json.to_json : body_json

  # replace any dynamic params in variable like /banks/{id}
  @endpoint = APIHelper.resolve_env(self, endpoint)
  @endpoint = APIHelper.resolve_variable(self, endpoint)

  # Request timeout
  set_request_timeout = @request_timeout
  env_request_timeout = ENV["REQUEST_TIMEOUT"]
  get_request_timeout = env_request_timeout.nil? ? set_request_timeout[0] : env_request_timeout.to_i

  begin
    @response = HTTParty.send(
      method.downcase,
      @endpoint,
      body: @body,
      headers: @headers,
      timeout: get_request_timeout
    )

    # if @response.code != 200
    #
    puts "Request : "
    puts @body
    puts "Response code : " + @response.code.to_s
    puts "Response Body : "
    puts @response.body
    # puts "======================="
    # puts ""
    # end
  rescue Net::ReadTimeout, Net::OpenTimeout
    raise "Request timed out after #{@request_timeout[1]}"
  end
end

When(/^client collects data from response with json path "([^"]+)" as "([^"]+)"$/) do |json_path, var|
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)
  value = JsonPath.new(json_path).on(@response.to_s).first

  raise "Value collected from JSON path '#{json_path}' is nil or empty!" if value.nil? || (value.respond_to?(:empty?) && value.empty?)

  puts value
  instance_variable_set("@#{var}", value)
end

Given(/^client define value "([^"]+)" with variable "([^"]+)"$/) do |variable_value, var|
  variable_value = variable_value ? APIHelper.resolve_env(self, variable_value) : nil
  variable_value = variable_value ? APIHelper.resolve_variable(self, variable_value) : nil
  instance_variable_set("@#{var}", variable_value)
end

Given(/^client collects data from ENV "([^"]+)" as "([^"]+)"$/) do |env, var|
  env = APIHelper.resolve_env(self, env)
  value = ENV[env[4..]]
  instance_variable_set("@#{var}", value.to_s)
end

And(/^client generate email with domain "([^"]+)" with variable "([^"]+)"$/) do |domain, var|
  email = "email_test_#{Time.now.to_i}@#{domain}".to_s
  instance_variable_set("@#{var}", email)
end

Then(/^the response status should be "(\d+)"$/) do |code|
  APIHelper.status_code?(code, @response)
end

Then(/^the response body should be match with json schema "(.*)"$/) do |schema|
  begin
    expect(@response.body).to match_json_schema(schema)
  rescue JsonMatchers::InvalidSchemaError => e
    raise <<~MESSAGE
      Invalid JSON format! Please:
      - Check your JSON schema file!
      - Make sure that any other JSON schema files are are valid/not empty!
      Error message: (#{e.message})
    MESSAGE
  end
end

Then(/^the response body with json path "([^"]*)" equal to "([^"]*)"$/) do |json_path, value|
  # Resolve env & variable value json path
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  # Resolve env & variable value data
  value = APIHelper.resolve_env(self, value)
  value = APIHelper.resolve_variable(self, value)

  results = JsonPath.new(json_path).on(@response.body).to_a.map(&:to_s)

  expect(results.first).to eq(value)
end

Then(/^the response body with json path "([^"]*)" must be contains with "([^"]*)"$/) do |json_path, expected|
  # Resolve env & variable value json path
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  # Resolve env & variable expected data
  expected = APIHelper.resolve_env(self, expected)
  expected = APIHelper.resolve_variable(self, expected)

  actual = JsonPath.new(json_path).on(@response.body)[0]

  begin
    expect("#{actual}".downcase).to include("#{expected}".downcase)
  rescue RSpec::Expectations::ExpectationNotMetError
    raise <<~MESSAGE
      Expected contains: #{expected}
      Actual: #{actual}
    MESSAGE
  end
end

Then(/^the response body ?(?:with json path "([^"]*)")? should be:$/) do |json_path, json|
  json = APIHelper.resolve_env(self, json)
  json = APIHelper.resolve_variable(self, json)

  json_path = json_path ? JsonPath.new(json_path).on(@response.body).first : JSON.parse(@response.body)

  expect(json_path).to eq(JSON.parse(json))
end

And(/^client generate random text ?(?:"([^"]+)")? with variable "([^"]+)"$/) do |variable_value, var|
  variable_value = variable_value ? APIHelper.resolve_env(self, variable_value) : nil
  variable_value = variable_value ? APIHelper.resolve_variable(self, variable_value) : nil

  random_text = "#{(0...15).map { ('a'..'z').to_a[rand(26)] }.join}"
  text = "#{variable_value}test#{random_text[5..]}"

  instance_variable_set("@#{var}", text)
end

And(/^client random pick "([^"]+)" with variable "([^"]+)"$/) do |text, var|
  text = text.split(",")
  instance_variable_set("@#{var}", text.sample)
end

And(/^calculates the data "([^"]*)"$/) do |data|
  data = APIHelper.resolve_env(self, data)
  data = APIHelper.resolve_variable(self, data)

  @result = Utils.calculates(data)
end

And(/^calculates the data "([^"]*)" and save as variable "([^"]*)"$/) do |data, variable_name|
  data = APIHelper.resolve_env(self, data)
  data = APIHelper.resolve_variable(self, data)

  result = Utils.calculates(data)

  instance_variable_set("@#{variable_name}", result)
end

And(/^client verify data calculation "([^"]*)" equal to "([^"]*)"$/) do |actual_calculation, expected_calculation|
  actual_calculation = APIHelper.resolve_env(self, actual_calculation)
  actual_calculation = APIHelper.resolve_variable(self, actual_calculation)

  expected_calculation = APIHelper.resolve_env(self, expected_calculation)
  expected_calculation = APIHelper.resolve_variable(self, expected_calculation)

  expect(Utils.calculates(actual_calculation)).to eq(expected_calculation.to_f.round(2))
end

Then("the result should be {string}") do |result|
  result = APIHelper.resolve_env(self, result)
  result = APIHelper.resolve_variable(self, result)

  expect(@result.to_s).to eq(result.to_s)
end

Then(/^the response body with json path "([^"]*)" must be not null$/) do |json_path|
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  value = JsonPath.on(@response, json_path).first

  expect(value).not_to be_nil
end

Then(/^the response body with json path "([^"]*)" must be null$/) do |json_path|
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  value = JsonPath.on(@response, json_path).first

  expect(value).to be_nil
end

And(/^client wait until "(\d+)" seconds$/) do |seconds|
  sleep(seconds.to_i)
end

Then(/^the response body with json path "([^"]*)" must be include with "([^"]*)"$/) do |json_path, value|
  value = APIHelper.resolve_variable(self, value)
  json_path = APIHelper.resolve_variable(self, json_path)

  results = JsonPath.new(json_path).on(@response.body).to_a.map(&:to_s)

  expect(value).to include(results.first)
end

Then(/^the response body with json path "([^"]*)" must not equal to "([^"]*)"$/) do |json_path, value|
  value = APIHelper.resolve_variable(self, value)
  json_path = APIHelper.resolve_variable(self, json_path)

  results = JsonPath.new(json_path).on(@response.body).to_a.map(&:to_s)

  expect(results.first).not_to eq(value)
end

Then(/^the response body with json path "([^"]*)" must have "([^"]*)" data$/) do |json_path, value|
  value = APIHelper.resolve_variable(self, value)
  json_path = APIHelper.resolve_variable(self, json_path)

  size = APIHelper.extract_json_values(@response.body, json_path).size

  expect(size).to eq(value.to_i)
end

And(/^format date "([^"]*)" to "([^"]*)" and save as variable "([^"]*)"$/) do |date, date_format, variable_name|
  date = APIHelper.resolve_variable(self, date)
  instance_variable_set("@#{variable_name}", Utils.date_format(Date.parse(date), date_format))
end

Then(/^the array data "([^"]*)" equal with list data response body with json path "([^"]*)"$/) do |expected_value, json_path|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  # Resolve env & variable expected value data
  expected_value = APIHelper.resolve_env(self, expected_value)
  expected_value = APIHelper.resolve_variable(self, expected_value)

  list_data = APIHelper.extract_json_values(@response.body, json_path)

  Utils.is_array_equal_subarray(list_data, expected_value)
end

Then(/^the response body with json path "([^"]*)" as list data must be include with "([^"]*)"$/) do |json_path, expected_value|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  # Resolve env & variable expected value data
  expected_value = APIHelper.resolve_env(self, expected_value)
  expected_value = APIHelper.resolve_variable(self, expected_value)

  list_data = APIHelper.extract_json_values(@response.body, json_path)

  expect(list_data).to include(expected_value)
end

Then(/^the response body with json path "([^"]*)" as list data equal with "([^"]*)"$/) do |json_path, expected_data|
  expected_data = APIHelper.resolve_variable(self, expected_data)
  json_path = APIHelper.resolve_variable(self, json_path)

  actual_list_data = APIHelper.extract_json_values(@response.body, json_path)

  Utils.all_array_equal_with_data?(actual_list_data, expected_data)
end

Then(/^the response body with json path "([^"]*)" as list data must be sorted (ascending|descending|ASC|DESC)$/) do |json_path, sorting|
  sorting = APIHelper.resolve_variable(self, sorting)
  json_path = APIHelper.resolve_variable(self, json_path)

  list_data = APIHelper.extract_json_values(@response.body, json_path)

  case sorting.upcase
  when "ascending"
  when "ASC"
    expect(list_data).to eq(list_data.sort)
  when "descending"
  when "DESC"
    expect(list_data).to eq(list_data.sort.reverse)
  else
    raise "Sorting must be ascending or descending value"
  end
end

And(/^client get "(today|yesterday|tomorrow|yesterday\+\d+|tomorrow\+\d+)" date with format "([^"]*)"$/) do |specific_date, date_format|
  # Sample date format you can use: https://gist.github.com/dikako/1a357cd91d1ced1095071e734664a318
  date = Utils.get_specific_date(specific_date, date_format)
  instance_variable_set("@#{specific_date}".gsub(/\+/, "_"), date)
end

And(/^client generate random integer between "(\d+)" and "(\d+)" and save as variable "([^"]*)"$/) do |min, max, variable_name|
  random_integer = rand(min..max)
  instance_variable_set("@#{variable_name}", random_integer)
end

And(/^client generate uuid with variable "([^"]*)"$/) do |variable_name|
  instance_variable_set("@#{variable_name}", Utils.generate_uuid)
end

And(/^the response body with json path "([^"]*)" as integer equal to "([^"]*)"$/) do |json_path, value|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  # Resolve env & variable value data
  value = APIHelper.resolve_env(self, value)
  value = APIHelper.resolve_variable(self, value)

  results = JsonPath.new(json_path).on(@response.body).to_a.map(&:to_i)

  expect(results.first).to eq(value.to_i)
end

And(/^client generate random string of "([^"]+)" characters with variable "([^"]+)"$/) do |number_of_character, var|
  # Resolve env & variable number of character data
  number_of_character = APIHelper.resolve_env(self, number_of_character)
  number_of_character = APIHelper.resolve_variable(self, number_of_character)

  random_string = Utils.generate_random_string(number_of_character)

  instance_variable_set("@#{var}", random_string)
end

And(/^client generate random alphabet of "([^"]+)" characters, with case "(uppercase|lowercase|mix)" and save as variable "([^"]+)"$/) do |number_of_character, characters, var|
  # Resolve env & variable number of character data
  number_of_character = APIHelper.resolve_env(self, number_of_character)
  number_of_character = APIHelper.resolve_variable(self, number_of_character)

  case characters
    # if u want use random case, you can use "mix"
  when 'uppercase'
    instance_variable_set("@#{var}", Utils.generate_random_alphabet(number_of_character).upcase)
  when 'lowercase'
    instance_variable_set("@#{var}", Utils.generate_random_alphabet(number_of_character).downcase)
  when 'mix'
    instance_variable_set("@#{var}", Utils.generate_random_alphabet(number_of_character))
  else
    raise "wrong case input! you can only type uppercase, lowercase, or mix"
  end
end

And(/^client generate random number of maximum "([^"]+)" characters with variable "([^"]+)"$/) do |number_of_character, var|
  random_number = Utils.generate_random_number(number_of_character.to_i)
  instance_variable_set("@#{var}", random_number)
end

When(/^client collects array data from response with json path "([^"]+)" as "([^"]+)"$/) do |json_path, var|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  value = APIHelper.extract_json_values(@response.body, json_path)

  instance_variable_set("@#{var}", value)
end

And(/extract string "([^"]*)" using regex "([^"]*)" as "([^"]*)"/) do |string, regex, var|
  # Resolve env & variable string data
  string = APIHelper.resolve_env(self, string)
  string = APIHelper.resolve_variable(self, string)

  string_extracted = Utils.extract_string(string, regex)

  instance_variable_set("@#{var}", string_extracted)
end

And(/^client collects data as integer from response with json path "([^"]+)" as "([^"]+)"$/) do |json_path, var|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  value_response = JsonPath.new(json_path).on(@response.to_s)
  value = value_response.to_s.gsub(/\D/, '').to_i

  instance_variable_set("@#{var}", value)
end

And(/^client collects array data from response with json path "([^"]+)" as "([^"]+)" truncate "([^"]+)"$/) do |json_path, var, number_of_truncate|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  values = APIHelper.extract_json_values(@response.body, json_path)
  values_round = values.map { |num| BigDecimal(num.to_s).truncate(number_of_truncate.to_i).to_f }

  instance_variable_set("@#{var}", values_round)
end

Then(/^the response body with json path "([^"]+)" equal with regex "([^"]+)"$/) do |json_path, regex|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  actual = JsonPath.new(json_path).on(@response.body)[0]

  regex = Regexp.new(regex)
  is_match = actual.match?(regex)

  begin
    expect(is_match).to eq(true)
  rescue RSpec::Expectations::ExpectationNotMetError
    raise <<~MESSAGE
      Expected regex: #{regex}
      Actual: #{actual}
    MESSAGE
  end
end

Then(/^the response body array with json path "([^"]+)" all array data equal to "([^"]+)"$/) do |json_path, expected|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  # Resolve env & variable expected data
  expected = APIHelper.resolve_env(self, expected)
  expected = APIHelper.resolve_variable(self, expected)

  actual = APIHelper.extract_json_values(@response.body, json_path).map(&:to_s)

  begin
    expect(actual).to all(include(expected))
  rescue RSpec::Expectations::ExpectationNotMetError
    raise <<~MESSAGE
      Error: Not all array data equal with '#{expected}'
      Expected data: #{expected}
      Actual array data: #{actual}
    MESSAGE
  end
end

Then(/^the response body array with json path "([^"]+)" all array data contains to "([^"]+)"$/) do |json_path, expected|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  # Resolve env & variable expected data
  expected = APIHelper.resolve_env(self, expected)
  expected = APIHelper.resolve_variable(self, expected)

  actual = APIHelper.extract_json_values(@response.body, json_path).map(&:to_s)

  begin
    expect(actual).to include(expected)
  rescue RSpec::Expectations::ExpectationNotMetError
    raise <<~MESSAGE
      Error: Not all array data contains with '#{expected}'
      Expected data: #{expected}
      Actual array data: #{actual}
    MESSAGE
  end
end

Given(/^client define env variable "([^"]+)"$/) do |var|
  # Resolve env & variable var data
  var = APIHelper.resolve_env(self, var)
  var = APIHelper.resolve_variable(self, var)

  key, value = var.split(":")

  ENV[key] = value
end

And(/^client generate md5 hash for "([^"]+)" and store it to a variable named "([^"]+)"$/) do |message, var|
  # Resolve env & variable message data
  message = APIHelper.resolve_env(self, message)
  message = APIHelper.resolve_variable(self, message)

  md5hash = Utils.generate_md5_hash(message)
  instance_variable_set("@#{var}", md5hash)
end

# This step definition is designed to handle a scenario where the client wants to send a GET request to multiple endpoint,
# receive the response, and then extract specific data from the response using JSONPath, saving it to variables for later use.
# How to use:
# When client sends a GET request to "{ENV:YOUR_BASE_URL}" and save response to variable
# |endpoint|json_path  |variable_name|
# |/first  |first_path |variable1    |
# |/second |second_path|variable2    |
When(/^client sends a GET request to "(.*)" and save response to variable$/) do |base_url, table|
  # Convert the data table into a array
  data_table = table.raw

  # Extract headers from the data table and convert them to symbols
  headers = data_table.shift.map(&:to_sym)

  # Resolve env & variable base_url data
  base_url = APIHelper.resolve_env(self, base_url)
  base_url = APIHelper.resolve_variable(self, base_url)
  json_path = nil
  variable_name = nil

  data_table.each do |row|
    # Convert the row data into a hash using the column headers as keys
    data = Hash[headers.zip(row)]

    # Resolve env & variable data
    @endpoint = APIHelper.resolve_env(self, data[:endpoint])
    @endpoint = APIHelper.resolve_variable(self, data[:endpoint])

    # Resolve env & variable expected data[:json_path]
    json_path = APIHelper.resolve_env(self, data[:json_path])
    json_path = APIHelper.resolve_variable(self, data[:json_path])

    # Resolve env & variable expected data[:variable_name]
    variable_name = APIHelper.resolve_env(self, data[:variable_name])
    variable_name = APIHelper.resolve_variable(self, data[:variable_name])

    @response = HTTParty.get(
      "#{base_url}#{@endpoint}",
      body: @body,
      headers: @headers
    )

    split_json_path = json_path.split(",")
    split_variable_name = variable_name.split(",")

    # Iterate over the arrays simultaneously using each_with_index
    split_json_path.each_with_index do |path, index|
      # Access the corresponding element from array2
      var = split_variable_name[index]
      json_path_value = JsonPath.new(path).on(@response.body)[0]
      instance_variable_set("@#{var}", json_path_value)
    end
  end
end

Then(/^the response body with json path "([^"]*)" equal to "([^"]*)" with differences not more than 1$/) do |json_path, expected_value|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  # Resolve env & variable expected value data
  expected_value = APIHelper.resolve_env(self, expected_value)
  expected_value = APIHelper.resolve_variable(self, expected_value)

  actual = JsonPath.new(json_path).on(@response.body).to_a.map(&:to_i)

  Utils.compare_numbers(expected_value.to_i, actual.first)
end

# This step for download google sheet file by google sheet name and save to specific file name
When(/^client download google sheet file "([^"]*)" as "([^"]*)"$/) do |google_sheet_name, saved_file_name|
  spreadsheet = google_sheet_name.split(":")
  spreadsheet_name = spreadsheet[0]

  if spreadsheet.size == 1
    APIHelper.download_spreadsheet(spreadsheet_name, "features/assets/#{saved_file_name}")
  else
    APIHelper.download_spreadsheet(spreadsheet_name, "features/assets/#{saved_file_name}", spreadsheet[1])
  end
end

And(/^client calculates the data "([^"]+)" to integer as "([^"]+)"$/) do |data, var|
  # Resolve env & variable data
  data = APIHelper.resolve_variable(self, data)
  data = APIHelper.resolve_env(self, data)

  result = Utils.calculates_to_i(data)

  instance_variable_set("@#{var}", result)
end

And(/^client save request body to file "([^"]*)"$/) do |file_name|
  Utils.save_data_to_file("#{Dir.pwd}/#{file_name}", @body)
end

And(/^client save response ?(?:with json path "([^"]*)")? to file "([^"]*)"$/) do |json_path, file_name|
  path = "#{Dir.pwd}/#{file_name}"

  # Resolve env & variable json path data
  json_path = json_path ? APIHelper.resolve_variable(self, json_path) : nil

  response = json_path ? JsonPath.new(json_path).on(@response.body).first&.to_json : @response.body

  FileUtils.rm_rf(path)
  Utils.save_data_to_file(path, response.to_s)
end

And(/^client download file from url "([^"]*)" as "([^"]*)" to folder "([^"]*)"$/) do |url, file_name, folder_path|
  url = APIHelper.resolve_variable(self, url)
  download_file = HTTParty.get(url)
  raise "Failed to download file!" unless download_file.success?

  file_path = File.join(folder_path, file_name)

  File.open(file_path, "wb") do |file|
    file.write(download_file.body)
  end
end

And(/^the download file "([^"]*)" at row "([^"]*)" must contains "([^"]*)"$/) do |file_name, json_path, expected_data|
  data = Utils.convert_xlsx_to_json(file_name, headers: false)

  # Resolve variable json path data
  json_path = APIHelper.resolve_variable(self, json_path)

  # Resolve env & variable expected data
  expected_data = APIHelper.resolve_env(self, expected_data)
  expected_data = APIHelper.resolve_variable(self, expected_data)

  # Flag to check if any match is found
  match_found = false

  # Iterate over each item in the response array
  actual_data = []
  data.each do |item|
    # Get the value at the specified path for each item
    json_value = item[json_path]

    actual_data << json_value
    # Check if the value at the specified path matches the expected data after removing trailing zeros
    if json_value.to_s.gsub(/\.?0*$/, '') == expected_data.to_s.gsub(/\.?0*$/, '')
      match_found = true
      break
    end
  end
  raise "No match found for expected data: '#{expected_data}', but found '#{actual_data}' at column '#{json_path}'." unless match_found

  # Check if any match was found
  expect(match_found).to eq(true)
end

When(/^client convert data "([^"]+)" to array as "([^"]+)"$/) do |data, var|
  # Resolve env & variable data
  data = APIHelper.resolve_variable(self, data)
  data = APIHelper.resolve_env(self, data)

  values = Utils.convert_to_array(data)

  instance_variable_set("@#{var}", values)
end

When(/^client collects data from CSV file "([^"]*)" column "([^"]*)" with value as "([^"]*)"$/) do |csv_file_path, column_name, var|
  # Resolve variable csv file path data
  csv_file_path = APIHelper.resolve_variable(self, csv_file_path)

  # Resolve variable column name data
  column_name = APIHelper.resolve_variable(self, column_name)

  csv_data = CSV.read(File.join(Dir.pwd, csv_file_path), headers: true).map(&:to_h)

  raise "Column '#{column_name}' not found in CSV file '#{csv_file_path}'!" unless csv_data[0].key?(column_name)

  # Extract only the first value from the specified column
  value = csv_data.first[column_name]

  raise "No value found in column '#{column_name}' of CSV file '#{csv_file_path}'!" if value.nil?

  instance_variable_set("@#{var}", value)
end

And(/^client generate price fraction of "([^"]*)" and save as variable "([^"]*)"$/) do |price, variable_name|
  # Resolve variable price data
  price = APIHelper.resolve_variable(self, price)

  instance_variable_set("@#{variable_name}", Utils.fraction_price(price.to_i))
end

And(/^convert to array using split with "([^"]*)" the response body with json path "([^"]*)" as "([^"]*)"$/) do |splitter, json_path, variable_name|
  # Resolve env & variable json path data
  json_path = APIHelper.resolve_env(self, json_path)
  json_path = APIHelper.resolve_variable(self, json_path)

  # data "12,13,14" => ["12","13","14"]
  result = JsonPath.new(json_path).on(@response.body).first.to_s.split(splitter)

  instance_variable_set("@#{variable_name}", result)
end

And(/^count the array data "([^"]*)" as "([^"]*)"$/) do |array_data, variable_name|
  # Resolve env & variable array data
  array_data = APIHelper.resolve_env(self, array_data)
  array_data = APIHelper.resolve_variable(self, array_data)

  # JSON.parse(array_data) => Convert "[\"12\", \"23\"]" to ["12", "23"]
  size_of_array = JSON.parse(array_data).size

  instance_variable_set("@#{variable_name}", size_of_array)
end

Then(/^data "([^"]*)" equal to "([^"]*)"$/) do |actual, expected|
  # Resolve variable actual data
  actual = APIHelper.resolve_variable(self, actual)

  # Resolve variable expected data
  expected = APIHelper.resolve_variable(self, expected)

  expect(expected).to eq(actual)
end

And(/^join array data "([^"]*)" with "([^"]*)" as "([^"]*)"$/) do |array_data, joiner, variable_name|
  # Resolve variable array data
  array_data = APIHelper.resolve_variable(self, array_data)

  # data ["12","13","14"] => "12,13,14"
  result = JSON.parse(array_data).map { |item| item }.join(joiner)

  instance_variable_set("@#{variable_name}", result)
end

And(/^client extract zip "([^"]*)" to folder "([^"]*)"$/) do |zip_file, extract_folder|
  # Resolve variable zip file data
  zip_file = APIHelper.resolve_variable(self, zip_file)

  # Resolve variable extract folder data
  extract_folder = APIHelper.resolve_variable(self, extract_folder)

  # input where your path zip file is save
  raise "ZIP File not found." unless File.exist?(zip_file)

  begin
    Zip::File.open(zip_file) do |file|
      file.each do |entry|
        entry.extract(File.join(extract_folder, entry.name))
      end
    end
  rescue StandardError => e
    raise "ZIP File failed to convert: #{e.message}"
  end
end

When(/^client set request timeout to "(.*ms|.*s)"$/) do |timeout|
  @request_timeout = [
    timeout.end_with?("ms") ? timeout.to_i / 1000.0 : timeout.to_i,
    timeout
  ]
end
