module Imprint
  module LogHelpers

    # Not relying on default rails logging, more often using lograge
    # Still want to log incoming params safely, which lograge doesn't include
    # this does the same sensative param filtering as rails defaults
    def log_entrypoint
      raise "you must call Imprint.configuration and configure the gem before using LogHelpers" if Imprint.configuration.nil?
      log_filter = ActionDispatch::Http::ParameterFilter.new(Imprint.configuration[:log_filters] || Rails.application.config.filter_parameters)
      header_blacklist = Imprint.configuration[:header_blacklist] || []
      cookies_whitelist = Imprint.configuration[:cookies_whitelist] || []

      http_request_headers = request.headers.select{|header_name, header_value| header_name.match("^HTTP.*") && !header_blacklist.include?(header_name) }
      data_append = "headers: "
      if http_request_headers.respond_to?(:each_pair)
        http_request_headers.each_pair{|k,v| data_append << " #{k}=\"#{v}\"" }
      else
        http_request_headers.each{|el| data_append << " #{el.first}=\"#{el.last}\"" }
      end

      data_append << " params: "
      log_filter.filter(request.query_parameters).each_pair{|k,v| data_append << " #{k}=\"#{v}\"" }
      
      cookies_whitelist.each do |cookie_key|
                         cookie_val = cookies[cookie_key] ? cookies[cookie_key] : 'nil'
                         data_append << " #{cookie_key}=\"#{cookie_val}\""
                       end

      logger.info "Started request_method=#{request.method.inspect} request_url=\"#{request.filtered_path}\" at request_time=\"#{Time.now.to_default_s}\" request_ip=#{request.remote_ip.inspect} #{data_append}"
    rescue
      logger.error "error logging log_entrypoint for request"
    end

  end
end
