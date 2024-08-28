And(/client withdraw using all bank with minimum balance/) do
  steps %(
    Given client sends a GET request to "{ENV:VONIX_API_URL}/v1/account/banks"
    When the response status should be "200"
  )

  banks = APIHelper.extract_json_values(@response.body, "banks")
  # Iterate over each bank
  banks.each do |bank|
    body = {
      "amount" => 1.1,
      "bankAccountTitle" => bank["label"],
      "bankCode" => bank["bankCode"],
      "bankAccountNumber" => bank["accountNumber"],
      "bankAccountName" => bank["accountHolderName"]
    }

    # Add the new header Idempotency-Key
    @headers[:'Idempotency-Key'] = SecureRandom.uuid

    response = HTTParty.post(
      "#{ENV["VONIX_API_URL"]}/v2/portfolio/withdraw/cash/xendit",
      headers: @headers,
      body: body.to_json
    )

    if response.code != 200
      puts "Request body : "
      puts JSON.pretty_generate(body)
      puts "Response code : " + response.code.to_s
      puts "Response body : "
      puts JSON.pretty_generate(response.body)
      puts "========================================================================"
      puts ""
    end
  end
end

And(/client add new all bank for withdraw/) do
  steps %(
    Given client sends a GET request to "{ENV:VONIX_API_URL}/v1/master/banks"
    When the response status should be "200"
  )
  banks = APIHelper.extract_json_values(@response.body, "banks")

  steps %(
    Given client sends a GET request to "{ENV:VONIX_API_URL}/v1/account/banks"
    When the response status should be "200"
  )
  requested_banks = APIHelper.extract_json_values(@response.body, "banks")

  requested_bank_codes = requested_banks.to_set { |bank| bank["bankCode"] }
  banks.each do |bank|
    next if requested_bank_codes.include?(bank["bankCode"])

    body = {
      "label": bank["bankCode"],
      "bankCode": bank["bankCode"],
      "bankAccountNumber": Utils.generate_random_number(10)
    }

    response = HTTParty.post(
      "#{ENV["VONIX_API_URL"]}/v1/account/bank",
      headers: @headers,
      body: body.to_json
    )
    APIHelper.status_code?(200, response)
  end
end

And(/client approve all requested bank/) do
  @banks.each do |bank|
    next unless bank["status"] != "PENDING" || bank["status"] != "REJECTED"

    formatted_date_now = Time.now.strftime("%Y-%m-%dT%H:%M:%S.%LZ")
    puts formatted_date_now
    body = {
      "status": "COMPLETED",
      "bank_account_number": bank["accountNumber"],
      "bank_code": bank["bankCode"],
      "created": formatted_date_now,
      "updated": formatted_date_now,
      "id": "bknv_63c10f34a17833001b32c30b",
      "result": {
        "is_found": true,
        "is_virtual_account": false,
        "need_review": false,
        "name_matching_result": "MATCH"
      }
    }

    response = HTTParty.post(
      "#{ENV["VONIX_API_URL"]}/v1/account/validations/bank/webhook",
      headers: @headers,
      body: body.to_json
    )

    APIHelper.status_code?(200, response)
  end
end
