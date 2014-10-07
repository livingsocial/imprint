require 'logger'

module Imprint
  class Middleware
    
    def self.set_request_trace_id(rack_env)
      trace_id = rack_env[Imprint::Tracer::TRACER_HEADER] || rack_env[Imprint::Tracer::RAILS_REQUEST_ID]
      if trace_id.nil?
        trace_id = "#{Time.now.to_i}_#{Imprint::Tracer.rand_trace_id}"
        logger.info("trace_status=initiated trace_id=#{trace_id}")
      end
      Imprint::Tracer.set_trace_id(trace_id, rack_env)
      trace_id
    end

    def self.logger=(logger)
      @logger = logger
    end

    def self.logger
      @logger ||= if defined?(Rails.logger)
                    Rails.logger
                  else
                    Logger.new(STDOUT)
                  end
    end
    
    def initialize(app, opts = {})
      @app = app
    end
    
    def call(env)
      ::Imprint::Middleware.set_request_trace_id(env)
      @app.call(env)
    end

  end
end
