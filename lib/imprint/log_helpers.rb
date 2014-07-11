module Imprint
  module LogHelpers

    # Not relying on default rails logging, we more often use lograge.
    # We still want to log incoming params safely, which lograge doesn't include
    # this does the same sensative param filtering as rails defaults
    # It also allows for logging headers and cookies
    def log_entrypoint
      raise "you must call Imprint.configuration and configure the gem before using LogHelpers" if Imprint.configuration.nil?
      log_filter = ActionDispatch::Http::ParameterFilter.new(Imprint.configuration[:log_filters] || Rails.application.config.filter_parameters)
      # I should probably switch this to be a whitelist as well, or support both white and black lists for both cookies and headers
      header_blacklist = Imprint.configuration[:header_blacklist] || []
      cookies_whitelist = Imprint.configuration[:cookies_whitelist] || []
      param_level = Imprint.configuration[:param_level] || Imprint::QUERY_PARAMS

      http_request_headers = request.headers.select{|header_name, header_value| header_name.match("^HTTP.*") && !header_blacklist.include?(header_name) }
      data_append = "headers: "
      if http_request_headers.respond_to?(:each_pair)
        http_request_headers.each_pair{|k,v| data_append << " #{k}=\"#{v}\"" }
      else
        http_request_headers.each{|el| data_append << " #{el.first}=\"#{el.last}\"" }
      end

      data_append << " params: "
      if param_level==Imprint::FULL_PARAMS
        set_full_params(log_filter, data_append)
      elsif param_level==Imprint::FULL_GET_PARAMS
        if request.get?
          set_full_params(log_filter, data_append)
        else
          set_query_params(log_filter, data_append)
        end
      else
        set_query_params(log_filter, data_append)
      end

      cookies_whitelist.each do |cookie_key|
                         cookie_val = cookies[cookie_key] ? cookies[cookie_key] : 'nil'
                         data_append << " #{cookie_key}=\"#{cookie_val}\""
                       end

      logger.info "Started request_method=#{request.method.inspect} request_url=\"#{request.path}\" request_time=\"#{Time.now.to_default_s}\" request_ip=#{request.remote_ip.inspect} #{data_append}"
    rescue
      logger.error "error logging log_entrypoint for request"
    end

    def set_full_params(log_filter, data_append)
      log_filter.filter(request.parameters).except('action', 'controller').each_pair{|k,v| data_append << " #{k}=\"#{v}\"" }
    end

    def set_query_params(log_filter, data_append)
      log_filter.filter(request.query_parameters).each_pair{|k,v| data_append << " #{k}=\"#{v}\"" }
    end

  end
end
