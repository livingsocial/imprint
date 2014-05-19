module Imprint
  class Middleware
    
    def self.set_request_trace_id(rack_env)
      existing_id = rack_env[Imprint::Tracer::TRACER_HEADER] || rack_env[Imprint::Tracer::RAILS_REQUEST_ID]
      existing_id ||= "#{Time.now.to_i}_#{Imprint::Tracer.rand_trace_id}"
      Imprint::Tracer.set_trace_id(existing_id, rack_env)
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
