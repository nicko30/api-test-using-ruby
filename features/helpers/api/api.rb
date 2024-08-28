# Created on 23/07/2024 @sebastianicko
# The `APIHelper` class provides utility methods for support API Testing.
class APIHelper
  class << self
    # Matcher is only available for curly brackets format ({}, {{}}, and so on)
    def resolve_variable(object, target, matcher = /{([a-zA-Z0-9_]+)}/)
      target.gsub(matcher) do |var|
        var.gsub!(/[{}]/, "")
        value = object.instance_variable_get("@#{var}")
        puts "Variable @#{var} is nil or false!" unless value

        value
      end || target
    end

    # Matcher is only available for curly brackets format "{ENV:XXX}" and so on)
    def resolve_env(_object, target, matcher = /{ENV:([a-zA-Z0-9_]+)}/)
      target.gsub!(matcher) do |env_var|
        match = Regexp.last_match
        value = ENV[match[1]]
        puts "Variable @#{env_var} is nil or false!" unless value

        value
      end || target
    end

    def extract_json_values(json, path)
      keys = path.split('.')
      current_value = JSON.parse(json)

      keys.each do |key|
        if current_value.is_a?(Hash)
          current_value = current_value[key]
        elsif current_value.is_a?(Array)
          new_value = []
          current_value.each do |item|
            new_value << item[key] if item.is_a?(Hash) && item[key]
          end
          current_value = new_value.flatten
        end
      end

      current_value
    end

    def status_code?(expected, actual)
      error_message = <<~MESSAGE
        Status Code Not #{expected}
        Response Body
        #{JSON.parse(actual.to_json)}
      MESSAGE
      assert_equal(expected, actual.code, error_message)
    end

    def google_sheet_auth
      auth = Base64.decode64(ENV['GOOGLE_SHEET_AUTH'])
      auth_file_name = "google_sheet_auth.json"
      File.open(auth_file_name, 'w') do |file|
        file.write(JSON.parse(auth).to_json)
      end
      auth_file_name
    end

    def google_drive_session
      GoogleDrive::Session.from_config(google_sheet_auth)
    end

    def spreadsheet_session(spreadsheet_name)
      google_drive_session.file_by_id(get_file_id(spreadsheet_name))
    end

    def download_spreadsheet(spreadsheet_name, download_filename, *worksheet_name)
      session = spreadsheet_session(spreadsheet_name)
      file = worksheet_name.empty? ? session : session.worksheet_by_title(worksheet_name.first)

      begin
        file.export_as_file("#{download_filename}.csv")
      rescue NoMethodError
        raise "Failed download google sheet file!"
      end
    end

    def get_file_id(spreadsheet_name)
      begin
        files = google_drive_session.files(q: "name = '#{spreadsheet_name}'")
        files.map(&:id)[0]
      rescue NoMethodError
        raise "Spreadsheet with name '#{spreadsheet_name}' not found!"
      end
    end

    def get_worksheets(spreadsheet_name)
      worksheets = spreadsheet_session(spreadsheet_name).worksheets
      [worksheets.map(&:title), worksheets.map(&:gid)]
    end

    def add_worksheet(spreadsheet_name, worksheet_name, max_rows = 100, max_cols = 20)
      session = spreadsheet_session(spreadsheet_name)
      worksheet = session.add_worksheet(worksheet_name, max_rows, max_cols)
      worksheet.save

      worksheet_name
    end

    def input_spreadsheet(spreadsheet_name, worksheet_name, headers, list_data, splitter, create_worksheet: false)
      # Create new worksheet when create_worksheet: true
      worksheet_name = add_worksheet(spreadsheet_name, worksheet_name, list_data.size, headers.size) if create_worksheet

      session = spreadsheet_session(spreadsheet_name).worksheet_by_title(worksheet_name)

      # Add headers
      headers.each_with_index do |header, index|
        session[1, index + 1] = header
      end

      # Add value
      list_data.each_with_index do |data, index|
        if splitter.nil?
          session[2, index + 1] = data
        else
          data = data.split("#{splitter}")

          data.each_with_index do |value, index_value|
            session[index + 2, index_value + 1] = value
          end
        end
      end
      session.save
    end

    # Import the uploaded file into a specific Google Sheet and worksheet
    def import_xlsx_to_google_sheet(spreadsheet_name, worksheet_name, file_path)
      # Find the specific spreadsheet by name
      spreadsheet = google_drive_session.spreadsheet_by_title(spreadsheet_name)
      raise "Spreadsheet not found" if spreadsheet.nil?

      # Find the specific worksheet by name or create it if it doesn't exist
      worksheet = spreadsheet.worksheet_by_title(worksheet_name)
      worksheet = spreadsheet.add_worksheet(worksheet_name) if worksheet.nil?

      # Read the XLSX file
      xlsx = Roo::Spreadsheet.open(file_path)

      # Copy the contents to the worksheet
      xlsx.sheet(0).each_with_index do |row, row_index|
        row.each_with_index do |cell, col_index|
          worksheet[row_index + 1, col_index + 1] = cell
        end
      end

      # Save changes
      worksheet.save
    end
  end
end
