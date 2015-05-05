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
          if defined?(Imprint::Tracer)
            Imprint::Tracer.insert_trace_id_in_message(message, ActiveSupport::BufferedLogger::Severity.constants[severity])
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
          if defined?(Imprint::Tracer)
            Imprint::Tracer.insert_trace_id_in_message(message, ActiveSupport::BufferedLogger::Severity.constants[severity])
          end
          @log.add(severity, message, progname, &block)
        end
      end
    end
  end

end

if defined?(ActiveSupport::Logger::SimpleFormatter)
  #Rails 4 dev / upgraded apps
  class ActiveSupport::Logger::SimpleFormatter
    def call(severity, time, progname, message)
      message = (message || (block && block.call) || progname).to_s
      # If a newline is necessary then create a new message ending with a newline.
      # Ensures that the original message is not mutated.
      message = "#{message}\n" unless message[-1] == "\n"
      if defined?(Imprint::Tracer)
        Imprint::Tracer.insert_trace_id_in_message(message, severity)
      end
      message
    end
  end

  #Rails 4 production newly generated apps
  class Logger::Formatter
    def call(severity, time, progname, msg)
      message = msg2str(msg)
      message = "#{message}\n" unless message[-1] == "\n"
      if defined?(Imprint::Tracer)
        Imprint::Tracer.insert_trace_id_in_message(message, severity)
      end
      Format % [severity[0..0], format_datetime(time), $$, severity, progname, message]
    end
  end

end
