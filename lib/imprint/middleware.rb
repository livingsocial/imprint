module Imprint
  class Middleware
    
    def self.set_trace_id(rails_env, rack_env)
      existing_id = rack_env[Imprint::Tracer::TRACER_HEADER]
      existing_id ||= "#{Time.now.to_i}_#{Imprint::Tracer.rand_trace_id}"
      Imprint::Tracer.set_trace_id(existing_id, rails_env, rack_env)
    end
    
    def initialize(app, opts = {})
      @app = app
    end
    
    def call(env)
      ::Imprint::Middleware.set_trace_id(ENV, env)
      @app.call(env)
    end

  end
end
