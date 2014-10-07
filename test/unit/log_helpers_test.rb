require File.expand_path('../../test_helper', __FILE__)
require 'imprint/log_helpers'

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
    count = 0
    logger.expect(:info, nil) { count += 1 }
    log_entrypoint
    logger.verify
    assert_equal 1, count
  end

  should "log entry catches exceptions and logs them" do
    count = 0
    logger.expect(:error, nil) { count += 1 }
    log_entrypoint
    logger.verify
    assert_equal 1, count
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
    @fake_log ||= Minitest::Mock.new
  end

  def cookies
    {}
  end

end
