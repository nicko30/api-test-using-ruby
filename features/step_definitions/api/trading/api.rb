And(/^client create (BUY|SELL) "([^"]*)" market order between "([^"]*)" and "([^"]*)" with interval "([^"]*)" times$/) do |order_type, symbol, min_amount, max_amount, times|
  min_amount = min_amount.to_f
  max_amount = max_amount.to_f
  times = times.to_i
  amount_coin_type = order_type == "BUY" ? "QUOTE_COIN" : "BASE_COIN"

  (1..times).each do
    random_amount = rand(min_amount..max_amount).round(4)
    puts "amount : " + format('%.4f', random_amount)
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
  steps %(
      And client sends a GET request to "{ENV:VONIX_API_URL}/v2/master/coins?isDisabled=false"
      And the response status should be "200"
    )
  token_codes = APIHelper.extract_json_values(@response.body, "data")

  failed_token = ""
  token_codes.each do |token_code|
    next if token_code["isBuyDisabled"] == true || token_code["isSellDisabled"] == true

    puts "Token : " + token_code["code"]

    steps %(
            And client sends a POST request to "{ENV:VONIX_API_URL}/v1/transaction/trade/place/purchase" with body:
            """
            {
              "symbol": "#{token_code["code"]}-USDT",
              "orderType": "MARKET",
              "side": "BUY",
              "amount": "10",
              "amountCoinType": "QUOTE_COIN",
              "price": 0
            }
            """
    )

    sleep(15)
    if @response.code == 200
      trx_id = JSON.parse(@response.body)["data"]["transactionCode"]

      steps %(
              And client sends a GET request to "{ENV:VONIX_API_URL}/v1/transaction/history/trade-details?transactionId=#{trx_id}"
      )
      transaction_status = JSON.parse(@response.body)["status"]
      amount_to_sell = JSON.parse(@response.body)["totalAmount"].to_d

      formatted_value = amount_to_sell.to_s('F').sub(/\.?0+$/, '')
      puts "formatted value : " + formatted_value

      if transaction_status == "SUCCESS" && amount_to_sell != 0
        steps %(
                And client sends a POST request to "{ENV:VONIX_API_URL}/v1/transaction/trade/place/purchase" with body:
                """
                {
                  "symbol": "#{token_code["code"]}-USDT",
                  "orderType": "MARKET",
                  "side": "SELL",
                  "amount": "#{formatted_value.to_d}",
                  "amountCoinType": "BASE_COIN",
                  "price": 0
                }
                """
      )
        sleep(5)
      else
        failed_token += token_code["code"] + ", "
      end

      puts ""
      puts "======================="
    else
      failed_token += token_code["code"] + ", "
    end
  end
  puts "failed token : " + failed_token
end
