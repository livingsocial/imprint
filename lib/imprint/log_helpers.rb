module Imprint
  module LogHelpers

    # Not relying on default rails logging, more often using lograge
    # Still want to log incoming params safely, which lograge doesn't include
    # this does the same sensative param filtering as rails defaults
    # it also allows injecting some other variables useful for tracing logs
    def log_entrypoint
      raise "you must call Imprint.configuration and configure the gem before using LogHelpers" if Imprint.configuration.nil?
      log_filter = ActionDispatch::Http::ParameterFilter.new(Imprint.configuration[:log_filters] || Rails.application.config.filter_parameters)
      header_blacklist = Imprint.configuration[:header_blacklist] || []
      variables_to_append = Imprint.configuration[:variables_to_append] || []
      cookies_whitelist = Imprint.configuration[:cookies_whitelist] || []

      http_request_headers = request.headers.select{|header_name, header_value| header_name.match("^HTTP.*") && !header_blacklist.include?(header_name) }
      data_append = "headers: "
      http_request_headers.each_pair{|k,v| data_append << " #{k}=\"#{v}\"" }

      data_append << " params: "
      log_filter.filter(params).each_pair{|k,v| data_append << " #{k}=\"#{v}\"" }
      
      variables_to_append.each do |var|
                           var_val = self.instance_variable_get("@#{var}".to_sym).try(:id)
                           var_val ||= 'nil'
                           data_append << " #{var}_id=\"#{var_val}\""
                         end
      
      cookies_whitelist.each do |cookie_key|
                         cookie_val = cookies[cookie_key] ? cookies[cookie_key] : 'nil'
                         data_append << " #{cookie_key}=\"#{cookie_val}\""
                       end

      logger.info "Started request_method=#{request.method.inspect} request_url=\"#{request.url.inspect}\" at request_time=\"#{Time.now.to_default_s}\" request_ip=#{request.remote_ip.inspect} #{data_append}"
    rescue
      logger.error "error logging log_entrypoint for request"
    end

  end
end
