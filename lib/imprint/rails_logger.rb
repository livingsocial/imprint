module ActiveSupport
  class BufferedLogger
    def add(severity, message = nil, progname = nil, &block)
      return if @level > severity
      message = (message || (block && block.call) || progname).to_s
      # If a newline is necessary then create a new message ending with a newline.
      # Ensures that the original message is not mutated.
      message = "#{message}\n" unless message[-1] == "\n"
      if (defined?(Imprint::Middleware)) && message && message.is_a?(String) && message.length > 1 && Imprint::Middleware.get_trace_id.to_s != '-1'
        message = message.gsub("\n"," [trace_id=#{Imprint::Middleware.get_trace_id}]\n")
      end
      buffer << message
      auto_flush
      message
    end
  end
end
