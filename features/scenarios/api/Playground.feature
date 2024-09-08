Feature: Playground

  @API @TEST_ATI-1
  Scenario: [API] User success login
    Given client without auth
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/auth/login" with body:
			"""
			{
			"email": "{ENV:TRADING_EMAIL}",
			"password": "{ENV:TRADING_PASSWORD}"
			}
			"""
    And the response status should be "200"
    Then the response body should be match with json schema "login/success_login"

  @API @TEST_ATI-2
  Scenario: [API] User login with blank email and password
    Given client without auth
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/auth/login" with body:
			"""
			{
			"email": "",
			"password": ""
			}
			"""
    And the response status should be "401"
    Then the response body should be match with json schema "login/failed_login_blank_email_blank_password"

  @API @TEST_ATI-3
  Scenario: [API] User login with blank password
    Given client without auth
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/auth/login" with body:
			"""
			{
			"email": "{ENV:TRADING_EMAIL}",
			"password": ""
			}
			"""
    And the response status should be "401"
    Then the response body should be match with json schema "login/failed_login_invalid_credentials"

  @API @TEST_ATI-4
  Scenario: [API] User login with blank email
    Given client without auth
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/auth/login" with body:
			"""
			{
			"email": "",
			"password": "{ENV:TRADING_PASSWORD}"
			}
			"""
    And the response status should be "401"
    Then the response body should be match with json schema "login/failed_login_blank_email_blank_password"

  @API @TEST_ATI-5
  Scenario: [API] User logout with invalid token
    Given client without auth
    And client set headers as:
			"""
			{
			"Authorization": "Bearer 12345"
			}
			"""
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/auth/logout" with body:
    		"""
			{
			}
			"""
    And the response status should be "401"
    Then the response body should be match with json schema "login/failed_logout_using_invalid_token"

  @API @TEST_ATI-6
  Scenario: [API] User success logout
    Given client login using "TRADING" account
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/auth/logout" with body:
    And the response status should be "200"
    Then the response body should be match with json schema "login/success_logout"

  @API @TEST_ATI-7
  Scenario: [API] User get portfolio assets summary
    Given client login using "TRADING" account
    And client sends a GET request to "{ENV:VONIX_API_URL}/v2/portfolio/assets/summary"
    And the response status should be "200"
    Then the response body should be match with json schema "portfolio/get_PortfolioAssets"

  @API @TEST_API-8
  Scenario: [API] User deposit using bank transfer
    Given client login using "TRADING" account
    And client sends a POST request to "{ENV:VONIX_API_URL}/v2/portfolio/deposit/virtual-account" with body:
			"""
			{
			"bankCode": "MANDIRI"
			}
			"""
    And the response status should be "201"
    Then the response body should be match with json schema "portfolio/post_create_deposit_virtual_account_number"
    And client sends a POST request to "{ENV:VONIX_API_URL}/v2/portfolio/deposit/virtual-account" with body:
			"""
			{
			"bankCode": "PERMATA"
			}
			"""
    And the response status should be "201"
    Then the response body should be match with json schema "portfolio/post_create_deposit_virtual_account_number"
    And client sends a POST request to "{ENV:VONIX_API_URL}/v2/portfolio/deposit/virtual-account" with body:
			"""
			{
			"bankCode": "BRI"
			}
			"""
    And the response status should be "201"
    Then the response body should be match with json schema "portfolio/post_create_deposit_virtual_account_number"
    And client sends a POST request to "{ENV:VONIX_API_URL}/v2/portfolio/deposit/virtual-account" with body:
			"""
			{
			"bankCode": "SAHABAT_SAMPOERNA"
			}
			"""
    And the response status should be "201"
    Then the response body should be match with json schema "portfolio/post_create_deposit_virtual_account_number"
    And client sends a POST request to "{ENV:VONIX_API_URL}/v2/portfolio/deposit/virtual-account" with body:
			"""
			{
			"bankCode": "OTHER-BANK"
			}
			"""
    And the response status should be "201"
    Then the response body should be match with json schema "portfolio/post_create_deposit_virtual_account_number"

  @API @TEST_API-9
  Scenario: [API] User deposit using e-wallet
    Given client login using "TRADING" account
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/portfolio/deposit/e-wallet" with body:
			"""
			{
			"walletName": "LINKAJA",
            "phoneNumber": "+6289529922120",
            "amount": 10000
			}
			"""
    And the response status should be "200"
    Then the response body should be match with json schema "portfolio/post_create_deposit_ewallet"
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/portfolio/deposit/e-wallet" with body:
			"""
			{
			"walletName": "DANA",
            "phoneNumber": "+6289529922120",
            "amount": 10000
			}
			"""
    And the response status should be "200"
    Then the response body should be match with json schema "portfolio/post_create_deposit_ewallet"
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/portfolio/deposit/e-wallet" with body:
			"""
			{
			"walletName": "OVO",
            "phoneNumber": "+6289529922120",
            "amount": 10000
			}
			"""
    And the response status should be "200"
    Then the response body should be match with json schema "portfolio/post_create_deposit_ewallet"

  @API @TEST_API-10
  Scenario: [API] User deposit using qris
    Given client login using "TRADING" account
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/portfolio/deposit/qris" with body:
			"""
			{
            "amount": 10000
            }
			"""
    And the response status should be "200"
    Then the response body should be match with json schema "portfolio/post_create_deposit_qris"

  @API @TEST_API-11
  Scenario: [API] User deposit using retail store
    Given client login using "TRADING" account
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/portfolio/deposit/retail-store" with body:
			"""
			{
			"retailStoreName": "ALFAMART",
            "amount": 10000.0
            }
			"""
    And the response status should be "200"
    Then the response body should be match with json schema "portfolio/post_create_deposit_retail_store"

  @API @TEST_API-12
  Scenario: [API] User create buy market order
    Given client login using "TRADING" account
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/transaction/trade/place/purchase" with body:
			"""
            {
              "symbol": "BTC-USDT",
              "orderType": "MARKET",
              "side": "BUY",
              "amount": "1",
              "amountCoinType": "QUOTE_COIN",
              "price": 0
            }
			"""
    And the response status should be "200"
    Then the response body should be match with json schema "trading/post_create_market_order"

  @API @TEST_API-13
  Scenario: [API] User create sell market order
    Given client login using "TRADING" account
    And client sends a POST request to "{ENV:VONIX_API_URL}/v1/transaction/trade/place/purchase" with body:
			"""
            {
              "symbol": "BTC-USDT",
              "orderType": "MARKET",
              "side": "SELL",
              "amount": "0.00001",
              "amountCoinType": "BASE_COIN",
              "price": 0
            }
			"""
    And the response status should be "200"
    Then the response body should be match with json schema "trading/post_create_market_order"

  @API @TEST_API-14
  Scenario: [API] User create buy market order with interval and range amount
    Given client login using "TRADING" account
    #And client create BUY "ETHUP" market order between "0.4" and "0.6" with interval "100" times
    And client create BUY "ETH" market order between "0.5" and "1" with interval "100" times

  @API @TEST_API-15
  Scenario: [API] User create sell market order with interval and range amount
    Given client login using "TRADING" account
    #And client create SELL "XRP" market order between "0.00001" and "0.00005" with interval "15" times
    And client create SELL "ETH" market order between "0.0001" and "0.0005" with interval "100" times
    #And client create SELL "BTC" market order between "15" and "20" with interval "15" times

