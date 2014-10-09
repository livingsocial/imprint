module Imprint
  class Tracer
    TRACER_HEADER    = 'HTTP_IMPRINTID'
    TRACER_KEY       = 'IMPRINTID'
    RAILS_REQUEST_ID = "action_dispatch.request_id"
    TRACE_ID_DEFAULT = -1

    TRACE_CHARS = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten

    def self.set_trace_id(id, rack_env = {})
      Thread.current[TRACER_KEY] = id
      # setting to the rack_env, gives error tracking support in some systems
      rack_env[TRACER_KEY] = id
    end

    def self.get_trace_id
      if Thread.current.key?(TRACER_KEY)
        Thread.current[TRACER_KEY]
      else
        TRACE_ID_DEFAULT
      end
    end

    def self.insert_trace_id_in_message(message)
      if message && message.is_a?(String) &&
          message.length > 1 && !message.include?('trace_id=') &&
          trace_id = get_trace_id && trace_id != TRACE_ID_DEFAULT
        message.gsub!("\n"," trace_id=#{trace_id}\n")
      end
    end

    def self.rand_trace_id
      (0...6).map { TRACE_CHARS[rand(TRACE_CHARS.length)] }.join
    end
  end
end
