require 'imprint/version'
require 'imprint/middleware'

module Imprint
  class Tracer
    
    TRACE_CHARS = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    @@trace_id = -1

    def self.set_trace_id(id)
      @@trace_id = id
    end

    def self.get_trace_id
      @@trace_id
    end

    def self.rand_trace_id
      (0...6).map { TRACE_CHARS[rand(TRACE_CHARS.length)] }.join    
    end
    
  end
end
