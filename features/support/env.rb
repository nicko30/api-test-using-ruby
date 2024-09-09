# Created on 23/07/2024 @sebastianicko

require "json"
require "jsonpath"
require "json-schema"
require "test-unit"
require "test/unit/assertions"
require "minitest"
require "dotenv/load"
require "base64"
require "httparty"
require "rspec"
require "cucumber"
require "json_matchers/rspec"
require "json-schema-rspec"
require "pry"
require "date"
require "securerandom"
require "time"
require "openssl"
require "csv"
require "zip"
require "fileutils"
require "google_drive"
require "parallel"
require "roo"
require "English"
require 'bigdecimal'
require 'bigdecimal/util'
require_relative "../helpers/api/api"
require_relative "api/auth/auth"
require_relative "logger"
require_relative "hooks"

include Test::Unit::Assertions

JsonMatchers.schema_root = "features/json_schemas/api"

Dotenv.load
