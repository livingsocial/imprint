# Imprint

Imprint helps track requests across multiple log lines or applications. It consists of a lightweight class and middleware to help set tracing ids.

It also has a file which can be used to bootstrap default rails logging to embedding the imprint `trace_id` on each line logged.

Supporting tracing between applications requires updating client calls between applications, at the moment we don't try to monkey patch any of that in and expect responsible clients to add the header manually as described in the Usage section below.

If you have seen [ActionDispatch::RequestId](http://api.rubyonrails.org/classes/ActionDispatch/RequestId.html). Imprint is basically a generic Rack version of that idea. It works with Rails 3, Sinatra, and Pure Rack. Beyond that it also provides some helpers and configuration around the trace_id usage.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'imprint'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install imprint
```

## Usage

After installing the gems and requiring them if needed.

To configure in a Rails 2, 3, or 4 application

edit `config/application.rb` and append the line below

```ruby
require 'imprint/rails_logger'
```

create or update your middleware configuration (for example: `config/initializers/middleware.rb`)

```ruby
require 'imprint'

Rails.application.config.middleware.insert_before Rails::Rack::Logger, Imprint::Middleware
```

If you are using any additional loggers that you wanted tagged that are not part of the normal Rails.logger you should update them as well. For example, we have some scribe logs:

```ruby
def log(message = nil, severity = :info)
  mirror_logger.add(parse_severity(severity), message) if mirror_logger
  log_raw(message, severity) do
    message = yield if block_given?
    # append imprint trace
    if (defined?(Imprint::Tracer.get_trace_id)) && message && message.is_a?(String) && message.length > 1 && Imprint::Tracer.get_trace_id.get_trace_id
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
end
```

## Params logging options

By default imprint will only log the query_params opposed to all params. This is because some of our apps don't filter logs well enough. If you are filtering correctly you might want more of the parameters logged. All params are still filtered by the `Rails.application.config.filter_parameters`.

There are three options:

* `FULL_PARAMS` log all params
* `QUERY_PARAMS` log query params only (default)
* `FULL_GET_PARAMS` log full params on get requests and query only on post requests

To change from the default send the config option `:param_level` to `Imprint.configure`. You most likely want to do this in your `environment.rb`

    Imprint.configure({
                   :param_level => Imprint::FULL_GET_PARAMS
                 })



## Optional Helpers

You can get a configurable log entrypoint for apps that allows for some intial logging on each request. This is intended to work well and be combined with lograge, but can be helpful on its own. To use the helpers follow the steps below.

edit `config/application.rb` and append the lines below, with whatever options make sense for your projects:

    require 'imprint/log_helpers'

    # we are using a blacklist on headers opposed to a whitelist
    HEADERS_TO_IGNORE = ['HTTP_COOKIE', 'HTTP_ACCEPT_ENCODING', 'HTTP_HOST', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_REAL_IP', 'HTTP_VERSION', 'HTTP_X_FORWARDED_PROTO', 'HTTP_HOST', 'HTTP_CONNECTION', 'HTTP_CACHE_CONTROL', 'HTTP_ACCEPT', 'HTTP_ACCEPT_ENCODING', 'HTTP_X_AKAMAI_EDGESCAPE', 'HTTP_AKAMAI_ORIGIN_HOP', 'HTTP_TE', 'HTTP_CLIENT_IP', 'HTTP_PRAGMA', 'HTTP_X_AKAMAI_CONFIG_LOG_DETAIL', 'HTTP_X_HTTPS', 'HTTP_X_REQUESTED_WITH', 'HTTP_VIA', 'HTTP_X_NEWRELIC_TRANSACTION', 'HTTP_AUTHORIZATION', 'HTTP_IF_MODIFIED_SINCE', 'HTTP_X_LS_MERCHANT_API_KEY', 'HTTP_X_CNECTION', 'HTTP_X_LIVINGSOCIAL_AUTH_TOKEN']
    Imprint.configure({
                   :log_filters => Rails.application.config.filter_parameters + ['some_other_token'],
                   :header_blacklist => HEADERS_TO_IGNORE,
                   :variables_to_append => ['viewer'],
                   :cookies_whitelist => ['living_social_user_id']
    })

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

## Background Job Support

We have a gateway wrapped about our Resque enqueue call. At this point I inject the trace_id. This makes it easy to ensure the job is queue with the params. So all failed jobs will include the trace_id

```ruby
options[:trace_id] ||= if (defined?(Imprint::Tracer)) && Imprint::Tracer.get_trace_id
  Imprint::Tracer.get_trace_id
else
  nil
end

Resque.enqueue(klazz, options)
```

Once it is on the queue, I want to log the ID but remove it from the params as some jobs work direclty with an expected set of params.

```ruby
def before_perform(*args)
	pluck_imprint_id
	#any other before filters
end

def pluck_imprint_id
  if defined?(Imprint::Tracer)
    existing_id = params.delete(:trace_id)
    Imprint::Tracer.set_trace_id(existing_id, {}) if existing_id
    true
  end
end
```

The process of adding support to other background processing should be pretty similar.

## Internal API Request Tracing (cross app tracing)

If you want to trace requests that go across multiple applications Imprint can help you out here as well. Basically the middleware only generates a new trace_id if the incoming requests don't have a special Imprint header `HTTP_IMPRINTID`

```ruby
existing_id = rack_env[Imprint::Tracer::TRACER_HEADER]
existing_id ||= "#{Time.now.to_i}_#{Imprint::Tracer.rand_trace_id}"
Imprint::Tracer.set_trace_id(existing_id, rack_env)
```

To trace any requests made by a external facing app to internal APIs just inject the current `trace_id` into the header of the api request. Here is an example from a client gem. First we isolated all the requests to a single gem request gateway method `http_get`. Then in this example we are using `RestClient` so we just add the header to the outgoing request.

```ruby
def self.http_get(url)
  if defined?(Imprint::Tracer) && Imprint::Tracer.get_trace_id
    RestClient.get(url, { Imprint::Tracer::TRACER_KEY => Imprint::Tracer.get_trace_id})
  else
    RestClient.get(url)
  end
end
```

## Notes / TODO

Looking at ZipKin, it tries to accomplish many of the same goals as Imprint. I think it would make sence to support the same headers and format so they could be compatible. Although the ZipKin service tracing isn't as useful to me as the full detailed splunk / elastic search logs.

* [ZipKin intro / docs](http://twitter.github.io/zipkin/index.html)
* [Railsconf ZipKin intro: Distributed Request Tracing](http://www.confreaks.com/videos/3326-railsconf-distributed-request-tracing) by [Kenneth Hoxworth (@hoxworth)](https://twitter.com/hoxworth)
* [ZipKin Header Formats](https://github.com/twitter/finagle/blob/master/finagle-http/src/main/scala/com/twitter/finagle/http/Codec.scala#L216)
* [Existing Ruby ZipKin Tracer](https://github.com/mszenher/zipkin-tracer)
* [Twitter Minimal Zipkin Tracer](https://github.com/twitter/zipkin/tree/04a755c29e6b2ff3bd99534bb95d760f112fda08/zipkin-gems/zipkin-tracer)
* [Docker ZipKin install for testing](https://github.com/itszero/docker-zipkin)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

See LICENSE.txt for details.
