# Created on 23/07/2024 @sebastianicko

require "logger"

def log_to_file(file_name)
  log_path =
    if ENV["DEBUG"] == "true"
      begin
        File.delete("#{file_name}.log")
      rescue StandardError
        # ignore
      end
      "#{file_name}.log"
    else
      path = "logger"
      FileUtils.mkdir_p(path) unless File.directory?(path)
      File.join(path, "#{file_name}.log")
    end

  Logger.new(log_path)
end

def log_to_console(log_message, level = :info)
  # Create a logger instance that logs to STDOUT (the terminal)
  logger = Logger.new($stdout)

  # Set the log level
  logger.level = Logger::DEBUG

  # Custom formatting
  logger.formatter = proc do |severity, datetime, _prog_name, msg|
    "#{datetime} - #{severity}: #{msg}\n"
  end

  # Log the message based on the specified level
  case level
  when :debug
    logger.debug(log_message)
  when :warn
    logger.warn(log_message)
  when :error
    logger.error(log_message)
  when :fatal
    logger.fatal(log_message)
  else
    logger.info(log_message)
  end
end
