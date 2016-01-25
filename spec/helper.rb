require 'simplecov'
require 'coveralls'

SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

SimpleCov.start do
  add_filter "/spec"
  minimum_coverage(90)
end

require 'semver'
require 'twitter'
require 'rspec'
require 'webmock/rspec'
require 'byebug'
require 'dotenv'
require 'csv'
require 'active_support/all'
require 'terminal-table'
require 'i_delete_my_tweets'

WebMock.disable_net_connect!(allow: "coveralls.io")

RSpec.configure do |config|
  config.before do
    Dotenv.overload('.env.test') # force test ENV
    @env_keys = ENV.keys
  end
  config.after { ENV.delete_if { |k, _v| !@env_keys.include?(k) } }

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def capture_warning
  begin
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    result = $stderr.string
  ensure
    $stderr = old_stderr
  end
  result
end

def fixture_path
  File.expand_path('fixtures', __dir__)
end

def fixture(file)
  File.new("#{fixture_path}/#{file}")
end

def spec_logger
  @spec_logger ||= Logger.new($stdout).tap { |l| l.level = Logger::DEBUG }
end

def cli_stdout(message, _color, _newline)
  spec_logger.info "\n#{message}"
end
