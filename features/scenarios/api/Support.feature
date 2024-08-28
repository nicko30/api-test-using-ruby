Feature: Supporting feature for test

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





