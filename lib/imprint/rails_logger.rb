if defined?(ActiveSupport::BufferedLogger)
  #Rails 3
  module ActiveSupport
    class BufferedLogger
      def add(severity, message = nil, progname = nil, &block)
        return if @level > severity
        message = (message || (block && block.call) || progname).to_s
        # If a newline is necessary then create a new message ending with a newline.
        # Ensures that the original message is not mutated.
        message = "#{message}\n" unless message[-1] == "\n"
        if (defined?(Imprint::Tracer)) && message && message.is_a?(String) && message.length > 1 && Imprint::Tracer.get_trace_id
          message = message.gsub("\n"," [trace_id=#{Imprint::Tracer.get_trace_id}]\n")
        end
        buffer << message
        auto_flush
        message
      end
    end
  end

end

if defined?(ActiveSupport::Logger::SimpleFormatter)
  #Rails 4
  class ActiveSupport::Logger::SimpleFormatter
    def call(severity, time, progname, message)
      message = (message || (block && block.call) || progname).to_s
      # If a newline is necessary then create a new message ending with a newline.
      # Ensures that the original message is not mutated.
      message = "#{message}\n" unless message[-1] == "\n"
      if (defined?(Imprint::Tracer)) && message && message.is_a?(String) && message.length > 1 && Imprint::Tracer.get_trace_id
        message = message.gsub("\n"," [trace_id=#{Imprint::Tracer.get_trace_id}]\n")
      end
      message
    end
  end

end
