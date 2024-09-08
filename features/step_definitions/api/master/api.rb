Then(/client compare all vonix coins with kucoin/) do
  steps %(
    And client sends a GET request to "{ENV:VONIX_API_URL}/v2/master/coins"
    And the response status should be "200"
  )
  # Extract the list of coins from the Vonix API response
  vonix_coins = APIHelper.extract_json_values(@response.body, "data")

  steps %(
    Given client without auth
    And client sends a GET request to "{ENV:KUCOIN_API_URL}/api/v2/symbols"
    And the response status should be "200"
  )
  # Extract the list of trading pairs from the Kucoin API response
  kucoin_symbols = APIHelper.extract_json_values(@response.body, "data.symbol")

  # Initialize a string to hold the names of coins that are on Vonix but not on Kucoin
  missing_coins = ""

  # Iterate through each Vonix coin
  vonix_coins.each do |coin|
    # Check if the coin is active (not disabled)
    if coin["isDisabled"] == "false"
      # Check if the coin has a USDT trading pair on Kucoin
      coin_with_usdt_pair = coin["code"] + "-USDT"
      # If the coin does not exist on Kucoin, add it to the missing_coins list
      missing_coins += coin["code"] + ", " unless kucoin_symbols.include?(coin_with_usdt_pair)
    end
  end

  unless missing_coins.empty?
    notification_message = {
      text: "Please delete these coins on Vonix: #{missing_coins}"
    }

    # Send the message to Google Chat
    Utils.send_to_google_chat(notification_message)
  end
end
