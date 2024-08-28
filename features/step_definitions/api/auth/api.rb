# Created on 23/07/24 @sebastianicko

Given(/^client login using "(.*)" account$/) do |credentials|
  @headers = {
    "Content-Type": "application/json",
    "Authorization": Auth.login_token(credentials)
  }
end
