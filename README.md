# Imprint

Imprint helps track requests across multiple log lines or applications. It
consists of a lightweight class and middleware to help set tracing ids.

It also has a file which can be used to bootstrap default rails logging to
embedding the imprint `trace_id` on each line logged.

Supporting tracing between applications requires updating client calls between
applications, at the moment we don't try to monkey patch any of that in and
expect responsible clients to add the header manually as described in the Usage
section below.

If you have seen
[ActionDispatch::RequestId](http://api.rubyonrails.org/classes/ActionDispatch/RequestId.html).
Imprint is basically a generic Rack version of that idea. It works with Rails 3,
Sinatra, and Pure Rack. Beyond that it also provides some helpers and
configuration around the trace_id usage.

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
	Imprint::Tracer.insert_trace_id_in_message(message) if defined?(Imprint::Tracer)
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
## Why, and How

Large systems that are composed of multiple communicating, cooperating parts can
be difficult to understand.  The idea of Imprint is that it is very useful to
assign a unique identifier to each *top-level*, *initiating* event that starts a
series of operations within your system, and have that identifier propagated
throughout the entire system, and attached to relevant diagnostic information
(especially log messages).  If a system is consistent about doing this, it
becomes easy to trace or visualize *all* of the actions that are taken as a part
of processing some request or event, or as side effects.  That can be extremely
useful for diagnosing bugs, finding bottlenecks, documenting intrusions, or
simply understanding the structure of a large complex system.

Imprint calls these identifiers *trace ids*.

Initiating events are, technically, anything that takes place in your system
that does not already have a trace id associated with it.  Typically, they
include:

* Initial browser requests from users (internal or external) using web
  applications
* Cron jobs or other scheduled jobs that initiate periodic processing
* API requests that come from integration partners

Imprint and tools like it should log all initiating events; that is, they
should log each time that they assign a new trace id to a request or event
that does not already have one.  If you see initiating events where you do not
expect them, that might just mean that part of your system is not propagating
existing trace ids properly as it sends messages or calls other services.
However, it might indicate an attempt to penetrate your system in an
unauthorized way.  It is a good idea to catalog the known initiating events in
your system, and set up some kind of monitoring to notice and alert you of
unexpected ones.

Request tracing across a complex system can't be accomplished just by a single
Ruby gem.  It requires cooperation from all of the applications, services,  and
components of the system.  The rest of this section documents how Imprint works
and what it expects from the other parts of the system, to help you implement
request tracing across all of the parts of your system, even if they are not
Rails applications or even written in Ruby.

### What Imprint Does

Here's what Imprint actually does. You should implement similar functionality
for parts of your system that are not written in Ruby, or are not Rails
applications.

1. Imprint patches the Rails logger so that *all* log messages incorporate the
   trace id if one is in effect when the message is logged.  Each line of the
   log messages ends like this: "&nbsp;[trace_id=1411414337_pDLsqp]".
2. Immediately upon receipt of each new request, Imprint checks to see whether
   the request came with an attached trace id, by checking for the presence
   of an `::Imprint::Tracer::TRACER_HEADER` ("HTTP_TRACE_ID") HTTP header. If
   present, that trace id is kept as the trace id of the current request.
3. If no trace id was included with the request, a new trace id is assigned.
   The new trace id consists of an integer timestamp (the number of seconds
   since the Unix epoch) plus a random string of six upper- and lowercase
   ASCII letters, separated by an underscore (e.g., "1411414337_pDLsqp").
   Then it logs an initiating event
   ("Initiated trace.&nbsp;[trace_id=1411414337_pDLsqp]").
4. Once a trace id has been found or generated, it is placed where every part
   of the application that participates in the current request has access to
   it (a variable scoped to the current thread, accessed via
   `::Imprint::Tracer::get_trace_id`).

### What Cooperating Applications and Components Should Do

Imprint is just part of the total solution; applications and services have
responsibilities as well.

1. Either use Imprint (if you're building a Rails app) or implement equivalent
   functionality in your app.
2. Any HTTP requests, Resque jobs, Kafka messages, or anything else that
   involves a different application or service in processing the request
   should be passed the trace id, either in the HTTP header or in an envelope
   field or something similar with the name `::Imprint::Tracer::TRACER_KEY`
   ("trace_id").  (See "Threading Considerations" below if your app employs
   concurrency in request processing.)

### Threading Considerations

In request tracing, it's crucial that the trace id is associated with
*everything* that is done because of the initiating event.  This means that
every part of an application or component must have access to the current trace
id, even if they are in different threads or processes than the one that
initially recorded the trace id.

The Rails architecture makes this easy. From the time a Rails app receives a
request, all of the processing for that request takes place in a single thread.
So Imprint puts the trace id in a variable scoped to the current thread.

However, many applications or frameworks employ concurrency during the
processing of a single request.  Such systems need to ensure that the other
threads (or processes, perhaps) that participate also know the trace id of
what they're working on.

If the initial thread simply spawns new threads to do part of the work, it
might work to simply use something like Java's `InheritableThreadLocal`.

More typically, though, parts of the work will be farmed out to worker threads
(actors, for example) that already exist in a pool and handle work for many
requests during their lifetime. In such cases, the messages or task
descriptions that are sent to those workers should include the trace id
associated with that work, and the workers should ensure that the appropriate
trace id is included in all of their processes.

So, in short: each such worker thread should be treated as if it were a
separate service: it should receive a trace id with each work request, attach
that trace id to all log messages that are part of that work request, and
propagate it in any other service or work requests that it sends. The exception
is that it should be considered an error if those internal worker threads
receive a request without a trace id; it's not reasonable for that to be an
initiating event.

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
