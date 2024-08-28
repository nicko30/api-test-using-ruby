And(/^client create (BUY|SELL) "([^"]*)" market order between "([^"]*)" and "([^"]*)" with interval "([^"]*)" times$/) do |order_type, symbol, min_amount, max_amount, times|
  min_amount = min_amount.to_f
  max_amount = max_amount.to_f
  times = times.to_i
  amount_coin_type = order_type == "BUY" ? "QUOTE_COIN" : "BASE_COIN"

  (1..times).each do
    random_amount = rand(min_amount..max_amount).round(1)
    puts "amount : " + format('%.1f', random_amount)
    steps %(
      And client sends a POST request to "{ENV:VONIX_API_URL}/v1/transaction/trade/place/purchase" with body:
      """
      {
        "symbol": "#{symbol}-USDT",
        "orderType": "MARKET",
        "side": "#{order_type}",
        "amount": "#{random_amount}",
        "amountCoinType": "#{amount_coin_type}",
        "price": 0
      }
      """
    )
    sleep(5)
  end
end

Then(/client buy and sell for all coins on vonix/) do
  # Read the content of the file
  file_content = File.read('result4.txt')

  # Regex pattern to match the symbol before -USDT and a response code not equal to 200 with a newline in between
  pattern = /"symbol":"([A-Z]+)-USDT".*?\nResponse code : (?!200\b)\d{3}/

  # Use scan to find all matches and return them in an array
  results = file_content.scan(pattern)

  # steps %(
  #     And client sends a GET request to "{ENV:VONIX_API_URL}/v2/master/coins"
  #     And the response status should be "200"
  #   )
  #
  # token_codes = APIHelper.extract_json_values(@response.body, "data")
  symbols = results.flatten.uniq
  puts symbols
  symbols.each do |symbol|
    # next if token_code["isBuyDisabled"] == true || token_code["isSellDisabled"] == true
    puts "Token : " + symbol
    steps %(
      And client sends a POST request to "{ENV:VONIX_API_URL}/v1/transaction/trade/place/purchase" with body:
      """
      {
        "symbol": "#{symbol}-USDT",
        "orderType": "MARKET",
        "side": "BUY",
        "amount": "8.0",
        "amountCoinType": "QUOTE_COIN",
        "price": 0
      }
      """
    )
    puts ""
    # token_amount = JSON.parse(@response.body)["data"]["amountPaid"].to_f
    sleep(6)

    # "amount": "#{token_amount.floor}",
    steps %(
      And client sends a POST request to "{ENV:VONIX_API_URL}/v1/transaction/trade/place/purchase" with body:
      """
      {
        "symbol": "#{symbol}-USDT",
        "orderType": "MARKET",
        "side": "SELL",
        "amount": "7.0",
        "amountCoinType": "QUOTE_COIN",
        "price": 0
      }
      """
    )

    puts ""
    puts "======================="
  end
end
