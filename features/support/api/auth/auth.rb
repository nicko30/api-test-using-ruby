# Created on 23/07/2024 @sebastianicko.
# The `Auth` class provides utility methods for handle auth for API Testing.

class Auth
  class << self
    def generate_login_token(email, password)
      headers = {
        "Content-Type": "application/json"
      }

      body = {
        "email": email,
        "password": password
      }

      response = HTTParty.post(
        "#{ENV["VONIX_API_URL"]}/v1/auth/login",
        body: body.to_json,
        headers: headers
      )

      status_code = response.code
      raise <<~MESSAGE unless status_code == 200
        Failed generate login token!
        Status code: #{status_code}
        Response body:
        #{response.body}
      MESSAGE

      "Bearer #{JSON.parse(response.body)["accessToken"]}"
    end

    def login_token(credentials)
      email = "#{ENV[credentials.gsub(" ", "_").upcase + "_EMAIL"]}"
      password = "#{ENV[credentials.gsub(" ", "_").upcase + "_PASSWORD"]}"

      generate_login_token(email, password)
    end
  end
end
