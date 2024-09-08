Feature: Supporting feature for test

  @API @TEST_API-97
  Scenario: [API] Check all vonix coins on kucoin
    Given client login using "TRADING" account
    Then client compare all vonix coins with kucoin

  @API @TEST_ATI-98
  Scenario: [API] User buy and sell for all coins on vonix
    Given client login using "TRADING" account
    Then client buy and sell for all coins on vonix

  @API @TEST_ATI-99
  Scenario: [API] User withdraw using all bank account
    Given client login using "TRADING" account
    Then client withdraw using all bank with minimum balance

  @API @TEST_API-100
  Scenario: [API] User add new all banks
    Given client login using "TRADING" account
    And client add new all bank for withdraw
    Then the response status should be "200"

  @API @TEST_API-101
  Scenario: [API] User approve all requested banks
    Given client login using "TRADING" account
    And client sends a GET request to "{ENV:VONIX_API_URL}/v1/account/banks"
    Then the response status should be "200"
    And client collects data from response with json path "banks" as "banks"
    Given client login using "ADMIN" account
    And client approve all requested bank





