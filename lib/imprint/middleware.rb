module Imprint
  class Middleware
    
    def self.set_trace_id(env)
      existing_id = env[Imprint::Tracer::TRACER_HEADER]
      existing_id ||= "#{Time.now.to_i}_#{Imprint::Tracer.rand_trace_id}"
      Imprint::Tracer.set_trace_id(existing_id)
    end
    
    def self.get_trace_id
      Imprint::Tracer.get_trace_id
    end
    
    def initialize(app, opts = {})
      @app = app
    end
    
    def call(env)
      ::Imprint::Middleware.set_trace_id(env)
      @app.call(env)
    end

  end
end
