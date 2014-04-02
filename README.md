# Imprint

Imprint helps track requests across multiple log lines or applications. It consists of a lightweight class and middleware to help set tracing ids.

It also has a file which can be used to bootstrap default rails logging to embedding the imprint `trace_id` on each line logged. 

Supporting tracing between applications requires updating client calls between applications, at the moment we don't try to monkey patch any of that in and expect responsible clients to add the header manually as described in the Usage section below.

## Installation

Add this line to your application's Gemfile:

    gem 'imprint'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install imprint


## Usage

After installing the gems and requiring them if needed.

To configure in a Rails 3 or 4 application

edit `config/application.rb` and append the line below

    require 'imprint/rails_logger'
    
create or update your middleware configuration (for example: `config/initializers/middleware.rb`)

	```ruby
	require 'imprint'
    
    Rails.application.config.middleware.insert_before Rails::Rack::Logger, Imprint::Middleware
	```
	
If you are using any additional loggers that you wanted tagged that are not part of the normal Rails.logger you should update them as well. For example, we have some scribe logs:

    def log(message = nil, severity = :info)
      mirror_logger.add(parse_severity(severity), message) if mirror_logger
      log_raw(message, severity) do
        message = yield if block_given?
        # append imprint trace
        if (defined?(Imprint::Middleware.get_trace_id)) && message && message.is_a?(String) && message.length > 1 && Imprint::Middleware.get_trace_id.get_trace_id.to_s != '-1'
          message = "#{message}\n" unless message[-1] == "\n"
          message = message.gsub("\n"," [trace_id=#{Imprint::Middleware.get_trace_id}]\n")
        end
        format = []
        format << Time.now.to_f
        format << @host
        format << $$
        format << format_severity(severity)
        format << "app_name"
        format << message
        format.flatten.join("\t")
      end

## Example Queries

These queries should work in Kibana/ElasticSearch, Splunk, or other log solutions. We may need to support different output formatters in the future depending on how various logging systems handle default field extraction.

First query to find a group of requests you are particularly interested in, perhaps all errors on an app:

    source="app_name" error status=500

From the results find a specific request that caused the error and use the trace_id to dig in futher, by crafting a query with the trace_id.

Find all log lines in a particular app related to a single request:

    source="app_name" "trace_id=1396448370_wdeYND"

Find all long lines related to a single request across apps:

    "trace_id=1396448370_wdeYND"
    
Since the trace_id is appended to all log lines during the duration of the request, any `logger.info`, `logger.error`, or other log output is easy to track back to the initial request information, params, headers, or other system logged information such as if the request was successfully authorize and by whom.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License 

See LICENSE.txt for details.