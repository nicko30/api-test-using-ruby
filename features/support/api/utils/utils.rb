# Created on 23/07/2024 @sebastianicko
# The `Utils` class provides utility methods for support API Testing.
class Utils
  class << self
    def generate_md5_hash(string)
      Digest::MD5.hexdigest(string)
    end

    def calculates(expression)
      allowed_chars = "0123456789()+-*/. "
      return "Error: Invalid characters in the input." if expression.chars.any? { |char| !allowed_chars.include?(char) }

      begin
        eval(expression).round(2)
      rescue StandardError => e
        "Error: #{e.message}"
      end
    end

    def image_to_base64(image_path)
      # Read the image file as binary data
      image = File.read("#{Dir.pwd}/features/assets/#{image_path}", mode: "rb")

      # Convert binary data to Base64
      Base64.encode64(image).gsub("\n", "")
    end

    def generate_hmac256(base_string, secret_key)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, base_string)
    end

    def generate_uuid
      SecureRandom.uuid
    end

    def generate_random_string(length)
      (0...length.to_i).map { [*('a'..'z'), *('A'..'Z'), *(0..9)].sample }.join
    end

    def generate_random_alphabet(length)
      (0...length.to_i).map { [*('a'..'z'), *('A'..'Z')].sample }.join
    end

    def generate_random_number(digits)
      min = 10 ** (digits - 1)
      max = (10 ** digits) - 1
      SecureRandom.random_number(min..max)
    end

    def generate_sid
      "IDD#{generate_random_number(12)}"
    end

    def generate_phone_number
      Faker::Config.locale = 'id'
      base_number = Faker::PhoneNumber.cell_phone_in_e164.gsub(/^(\+|)\d{3}/, "")
      required_length = rand(7..9)
      phone_number = base_number[0, required_length].to_s
      prefixes = %w[851 852 878 879 821 822 895 896]
      selected_prefix = prefixes.sample
      selected_prefix + phone_number
    end

    def date_format(date, date_format)
      date.strftime(date_format)
    end

    def get_specific_date(specific_date, date_format)
      today = Date.today

      # Set instance variable based on input value
      case specific_date
      when "today"
        date = date_format(today, date_format)
      when "yesterday"
        date = date_format(today - 1, date_format)
      when "tomorrow"
        date = date_format(today + 1, date_format)
      when /\Ayesterday\+\d+\z/
        days = specific_date.match(/\d+/)[0].to_i
        puts "Hari: #{today - days}"
        date = date_format(today - days, date_format)
      when /\Atomorrow\+\d+\z/
        days = specific_date.match(/\d+/)[0].to_i
        date = date_format(today + days, date_format)
      else
        date = nil
        raise_error("Invalid argument. Use: [today|yesterday|tomorrow|yesterday+n|tomorrow+n]")
      end

      date
    end

    # extract string value using regex
    def extract_string(string, regex_pattern)
      regex = Regexp.new(regex_pattern)
      match = string[regex]
      match&.to_s
    end

    def read_json_file(file_path)
      begin
        file = File.read(file_path)
        JSON.parse(file)
      rescue Errno::ENOENT
        puts "File not found: #{file_path}"
      rescue JSON::ParserError
        puts "Invalid JSON format in file: #{file_path}"
      end
    end

    def compare_numbers(number1, number2)
      difference = (number1 - number2).abs
      return if difference <= 1

      raise "Expected number #{number1} not match with actual number #{number2}"
    end

    # This function extracts data from a CSV file based on the given header and returns the extracted data.
    # @param csv_file [String] - The name of the CSV file (excluding the extension) located in the "features/assets/" directory.
    # @param header [Symbol] - The header value to be extracted from the CSV file.
    # @return [Array] - An array containing the extracted data from the specified header in the CSV file.
    def extract_csv_file(csv_file, header)
      # Initialize an empty array to store csv data
      data = []

      # Iterate through each row in the CSV file located in the specified directory.
      # Append the value of the specified header from each row to the 'data' array.
      CSV.foreach("#{csv_file}.csv", headers: true) do |row|
        data << row[header.to_s]
      end

      # Return the extracted data.
      data
    end

    def all_array_equal_with_data?(array_data, specific_data)
      array_data.all? do |data|
        unless data == specific_data
          raise <<~MESSAGE
            \nActual all array data: #{array_data}
            Not equal with expected data: #{specific_data}
          MESSAGE
        end
      end
    end

    def is_array_equal_subarray(main_array, sub_array)
      # Convert the sub_array into an array of elements
      sub_array_elements = sub_array.split(",")

      # Initialize variables to track one comparison
      sub_array_index = 0
      matching_elements = []

      # Iterate through the main_array
      main_array.each do |element|
        if element == sub_array_elements[sub_array_index]
          matching_elements << element
          sub_array_index += 1
        end
      end

      # Check if the matching elements are equal to the elements in the sub_array
      return if matching_elements == sub_array_elements

      raise <<~MESSAGE
        \nActual all array data: #{sub_array_elements}
        Not equal with expected sub array data: #{main_array}
      MESSAGE
    end

    def is_expected_digit(data, expected_length)
      length_of_string_data = data.to_s.length
      return if length_of_string_data == expected_length.to_i

      raise "Expected length of data '#{data}' is '#{expected_length}' but actual '#{length_of_string_data}'"
    end

    def is_equal?(expected, actual)
      expected == actual
    end

    # This method takes a list of errors and raises an exception if the list is not empty.
    # If there are errors in the list, it formats them as a string with each error preceded by a dash
    # and raises an exception containing the formatted error message.
    # @param list_error [Array] - list of errors messages
    def print_errors(list_error)
      raise "\n#{list_error.map { |item| "- #{item}" }.join("\n")}" unless list_error.empty?
    end

    # Helper method to validate csv headers
    def validate_csv_headers(expected_headers, actual_headers)
      return if actual_headers == expected_headers

      raise <<~MESSAGE
        \nHeaders Data Table must be:
        #{expected_headers.map { |item| "- #{item}" }.join("\n")}
      MESSAGE
    end

    # Function to validate if a date is a weekday
    def weekday?(string_date)
      # Parse the date string into a Date object
      date = Date.parse(string_date)

      # Check if the day of the week is Monday to Friday (1 to 5)
      (1..5).cover?(date.wday)
    end

    # Save data to a file, creating the necessary folder structure if it doesn't exist.
    # @param file_path [String] The path to the file where data will be saved.
    # @param data [String] The data to be appended to the file.
    # @return [void]
    def save_data_to_file(file_path, data)
      # Extract the folder path from the file_path
      folder_path = File.dirname(file_path)

      # Create the folder structure if it doesn't already exist
      FileUtils.mkdir_p(folder_path) unless File.directory?(folder_path)

      # Open the file in "append" mode, write the data, and then close the file
      file_path = File.open(file_path, "a")
      file_path.write("#{data}\n")
      file_path.close
    end

    # This method lists files in a specified folder and returns an array of file names.
    # It excludes the current directory ('.') and parent directory ('..') entries.
    def list_file_in_folder(folder_path)
      begin
        # Use Dir.entries to list all files and directories in the folder.
        # Exclude '.' (current directory) and '..' (parent directory) entries.
        files = Dir.entries(folder_path).reject { |f| %w[. ..].include?(f) }

        # Initialize an empty array to store the list of file names.
        list_file = []

        # Loop through the 'files' array and add each file name to 'list_file'.
        files.each do |file|
          list_file << file
        end
      rescue StandardError => e
        # If an error occurs (e.g., folder not found), raise an exception with an error message.

        raise "Folder not found!\n #{e.message}"
      end

      # Return the list of file names in the folder.
      list_file
    end

    def calculates_to_i(expression)
      allowed_chars = "0123456789()+-*/. "
      return "Error: Invalid characters in the input." if expression.chars.any? { |char| !allowed_chars.include?(char) }

      begin
        eval(expression).to_i
      rescue StandardError => e
        "Error: #{e.message}"
      end
    end

    def send_to_google_chat(message_payload)
      # Send chat to google chat using webhook
      response = HTTParty.post(
        ENV["GOOGLE_CHAT_WEBHOOK"],
        headers: {
          "Content-Type": "application/json"
        },
        body: message_payload.to_json
      )

      # Check when failed send slack report
      return if response.code == 200

      error_message = <<~MESSAGE
        *Failed send slack notification to slack*
        Response: _#{response.body}_
      MESSAGE

      HTTParty.post(
        ENV["GOOGLE_CHAT_WEBHOOK"],
        headers: {
          "Content-Type": "application/json"
        },
        body: {
          text: "#{error_message}"
        }.to_json
      )
    end

    def slack_report_assets(cucumber_report)
      all_passed = cucumber_report[:total_failed].zero?

      {
        "all_passed" => all_passed,
        "emoji" => all_passed ? ":white_check_mark:" : ":alert-siren:",
        "button" => all_passed ? "primary" : "danger",
        "tag" => ENV["TAGS"]
      }
    end

    def duplicate_array?(array_data)
      seen = {}
      duplicates = []

      array_data.each do |element|
        if seen[element]
          duplicates << element
        else
          seen[element] = true
        end
      end

      duplicates.uniq
    end

    def convert_xlsx_to_json(xlsx_file, *json_file, headers: true, save_to_file: false)
      xlsx = Roo::Spreadsheet.open(xlsx_file)

      data_headers = headers ? xlsx.row(1) : (1..xlsx.last_column).map(&:to_s)
      data_start = headers ? 2 : 1

      data = (data_start..xlsx.last_row).map { |i| Hash[data_headers.zip(xlsx.row(i))] }

      json_data = JSON.pretty_generate(data)
      if save_to_file
        File.open(json_file, 'w') do |file|
          file.write(json_data)
        end
      else
        JSON.parse(json_data)
      end
    end

    def clean_value(data)
      return data if data.is_a?(Integer) || data.is_a?(Float)

      case data
      when /\A\d+(\.\d+)? %\z/ # Data is a string with format (e.g., "1.55 %")
        data.gsub(/[% ]/, '')
      when /\A\d+,\d+(\.\d+)? %\z/ # Data is a string with comma format and percentage (e.g., "2,200 %")
        data.gsub(/[% ,]/, '')
      when /\A\d+,\d+\z/ # Data is a string with comma format (e.g., "2,200")
        data.gsub(',', '')
      when /\A\d+\z/ # Data is as string from 0-9 without other character
        data
      else
        raise "Unsupported data format: #{data}"
      end
    end

    def execute_cucumber_test(feature_file_path)
      system "cucumber features/assets/scenarios/#{feature_file_path}.feature"
      $CHILD_STATUS
    end

    def convert_to_array(value)
      Array(value)
    end

    def generate_hmac_sha256_unpack1(key, data)
      hmac = OpenSSL::HMAC.digest('sha256', key, data)
      hmac.unpack1('H*')
    end

    def generate_sha256_from_string(str)
      sha256 = Digest::SHA256.new
      sha256.update(str)
      sha256.hexdigest
    end

    def fraction_price(number)
      case number
      when 1..200
        number
      when 201..500
        number.even? ? number : number + 1
      when 501..2000
        (number % 5).zero? ? number : number + (5 - (number % 5))
      when 2001..5000
        (number % 10).zero? ? number : number + (10 - (number % 10))
      else
        (number % 25).zero? ? number : number + (25 - (number % 25))
      end
    end

    def ara_arb_factor(price)
      case price
      when 50..200 then 0.35
      when 201..5000 then 0.25
      when 5001..Float::INFINITY then 0.20
      else
        "Not Common Stock"
      end
    end

    def format_number(number)
      # Check if the input is already a string
      return number.to_s if number.is_a?(String)

      # Format the number with a thousand separator
      number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end

    def merge_unique_arrays(*arrays)
      arrays.flatten.uniq
    end
  end
end
