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
    stub_rails
    logger.expects(:info).with(anything).once
    log_entrypoint
  end

  should "log entry catches exceptions and logs them" do
    logger.expects(:error).with(anything).once
    log_entrypoint
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

  def stub_rails
    rails_config ||= mock('config')
    rails_config.stubs(:filter_parameters).returns([])
    rails_app ||= mock('application')
    rails_app.stubs(:config).returns(rails_config)
    Rails.stubs(:application).returns(rails_app)
  end

  def logger
    @fake_log ||= mock('logger')
  end

  def cookies
    {}
  end

end
