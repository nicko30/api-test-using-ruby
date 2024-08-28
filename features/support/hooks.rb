# Created on 23/07/2024 @sebastianicko

Before do
  @response = nil
  @request_timeout = [
    2,
    "2s"
  ] # Default request timeout
end

After do |scenario|
  # Get scenario name
  scenario_name = scenario.name

  # Retrieve the tags associated with the scenario and convert them to an array
  scenario_tags = eval(scenario.source_tag_names.to_s)

  # Define a regular expression pattern to match tags of the form @TEST_ATI-{number}
  pattern = /^@TEST_ATI-\d+$/

  # Select tags from the scenario tags array that match the defined pattern
  test_id = scenario_tags.select do |item|
    item.match(pattern)
  end

  # Extract the test ID from the first matched tag by removing the '@TEST_' prefix
  begin
    log_name = test_id[0].gsub("@TEST_", "")
  rescue StandardError
    log_name = "TEST"
  end

  # Get url
  url = instance_variable_get("@endpoint")

  # Get request headers
  request_headers = JSON.pretty_generate(instance_variable_get("@headers"))

  # Get request body
  body = instance_variable_get("@body")
  if body == "null"
    request_body = "No request body!"
  else
    request_body = body
  end

  # Get response
  response = instance_variable_get("@response")
  begin
    response = JSON.pretty_generate(JSON.parse(response.to_s))
  rescue StandardError
    response = response.to_s
  end

  # Get error scenario
  if scenario.failed?
    scenario_error = scenario.exception.message.to_s.gsub("\n", "")
  else
    scenario_error = "No error!"
  end

  if ENV["DEBUG"] == "true"
    log_to_file(log_name).error(
      <<~MESSAGE
        #{scenario_name}

        URL: #{url}

        ERROR: #{scenario_error}

        REQUEST HEADERS:
        #{request_headers}

        REQUEST BODY:
        #{request_body}

        RESPONSE:
        #{response}
      MESSAGE
    )
  else
    # Check if the scenario has failed
    if scenario.failed?
      # Call a logger function with the extracted test ID as the log name and log an error message
      log_to_file(log_name).error(
        <<~MESSAGE
          #{scenario_name}

          URL: #{url}

          ERROR: #{scenario_error}

          REQUEST HEADERS:
          #{request_headers}

          REQUEST BODY:
          #{request_body}

          RESPONSE:
          #{response}
        MESSAGE
      )
    end
  end

  instance_variables.each do |instance_variable|
    remove_instance_variable(instance_variable)
  end
end
