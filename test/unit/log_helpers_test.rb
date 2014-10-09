require File.expand_path('../../test_helper', __FILE__)
require 'imprint/log_helpers'
require 'logger'

####
# Testing Rails integration without Rails isn't fun
# The below test double classes let us do that.
# along with the implemented fakes as protected methods
####
module ActionDispatch
  module Http
    class ParameterFilter
      def initialize(opts)
      end

      def filter(params)
        params
      end
    end
  end
end

class Rails
  def self.application
    @app ||= Object.new.tap do |app|
      def app.config
        @config ||= Object.new.tap do |config|
          def config.filter_parameters
            []
          end
        end
      end
    end
  end
end

class Time
  def to_default_s
    self.to_s
  end
end

class LogHelpersTest < Minitest::Test
  include Imprint::LogHelpers
  Imprint.configure({})

  should "log entry" do
    count           = 0
    increment_count = Proc.new { count += 1 }

    logger.stub :info, increment_count do
      log_entrypoint
    end

    assert_equal 1, count
  end

  should "log entry catches exceptions and logs them" do
    Imprint.stub :configuration, nil do
      count           = 0
      increment_count = Proc.new { count += 1 }

      logger.stub :error, increment_count do
        log_entrypoint
      end

      assert_equal 2, count
    end
  end

  protected

  def request
    request = Rack::MockRequest.env_for("/anything.json")

    def request.headers
      {}
    end

    def request.method
      {}
    end

    def request.url
      ''
    end

    def request.path
      ''
    end

    def request.remote_ip
      ''
    end

    def request.query_parameters
      {}
    end

    request
  end

  def logger
    @fake_log ||= Logger.new(STDOUT)
  end

  def cookies
    {}
  end

end
