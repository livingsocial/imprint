if defined?(ActiveSupport::BufferedLogger)
  #Rails 2 and 3 support
  module ActiveSupport
    class BufferedLogger
      def add(severity, message = nil, progname = nil, &block)
        #rails 2 and 3.0
        if @level && self.respond_to?(:buffer)
          return if !@level.nil? && (@level > severity)
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
        else
          # rails 3.2.x 
          return if !level.nil? && (level > severity)
          message = (message || (block && block.call) || progname).to_s
          # If a newline is necessary then create a new message ending with a newline.
          # Ensures that the original message is not mutated.
          message = "#{message}\n" unless message[-1] == "\n"
          if (defined?(Imprint::Tracer)) && message && message.is_a?(String) && message.length > 1 && Imprint::Tracer.get_trace_id
            message = message.gsub("\n"," [trace_id=#{Imprint::Tracer.get_trace_id}]\n")
          end
          @log.add(severity, message, progname, &block)
        end
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
