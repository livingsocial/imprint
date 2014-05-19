require 'imprint/version'
require 'imprint/middleware'

module Imprint
  class Tracer
    TRACER_HEADER    = 'HTTP_IMPRINTID'
    TRACER_KEY       = 'IMPRINTID'
    RAILS_REQUEST_ID = "action_dispatch.request_id"

    TRACE_CHARS = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten

    def self.set_trace_id(id, rack_env = {})
      Thread.current[TRACER_KEY] = id
      # setting to the rack_env, gives error tracking support in some systems
      rack_env[TRACER_KEY] = id
    end

    def self.get_trace_id
      Thread.current[TRACER_KEY]
    end

    def self.rand_trace_id
      (0...6).map { TRACE_CHARS[rand(TRACE_CHARS.length)] }.join    
    end
    
  end
end
