require 'imprint/version'
require 'imprint/middleware'

module Imprint
  class Tracer
    TRACER_HEADER = 'HTTP_IMPRINTID'
    TRACER_KEY    = 'IMPRINTID'

    TRACE_CHARS = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten

    def self.set_trace_id(id, rails_env, rack_env)
      rails_env[TRACER_KEY] = id
      rack_env[TRACER_KEY] = id
    end

    #this assumes the rails ENV is available at ENV
    def self.get_trace_id(rails_env = ENV)
      rails_env[TRACER_KEY]
    end

    def self.rand_trace_id
      (0...6).map { TRACE_CHARS[rand(TRACE_CHARS.length)] }.join    
    end
    
  end
end
