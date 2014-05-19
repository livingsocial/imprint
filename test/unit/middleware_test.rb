require File.expand_path('../test_helper', File.dirname(__FILE__))

class MiddlewareTest < Test::Unit::TestCase

  should "call app" do
    request = Rack::MockRequest.env_for("/anything.json")
    middleware = Imprint::Middleware.new(fake_app)
    results = middleware.call(request)
    assert_equal "/anything.json", results.last
  end

  should 'pass all rack lint checks' do
    app = Rack::Lint.new(Imprint::Middleware.new(fake_app))
    env = Rack::MockRequest.env_for('/hello')
    app.call(env)
  end

  should "set trace_id before calling app" do
    request = Rack::MockRequest.env_for("/anything.json")
    middleware = Imprint::Middleware.new(fake_app)
    results = middleware.call(request)
    assert_equal "/anything.json", results.last
    assert_not_nil ::Imprint::Tracer.get_trace_id
    assert ::Imprint::Tracer.get_trace_id!='-1'
  end

  should "set trace_id from rails request_id" do
    request = Rack::MockRequest.env_for("/anything.json", {"action_dispatch.request_id" => 'existing_id' })
    middleware = Imprint::Middleware.new(fake_app)
    results = middleware.call(request)
    assert_equal "/anything.json", results.last
    assert_not_nil ::Imprint::Tracer.get_trace_id
    assert ::Imprint::Tracer.get_trace_id=='existing_id'
  end

  should "set trace_id from passed in imprint header" do
    request = Rack::MockRequest.env_for("/anything.json", {"HTTP_IMPRINTID" => 'existing_trace_id' })
    middleware = Imprint::Middleware.new(fake_app)
    results = middleware.call(request)
    assert_equal "/anything.json", results.last
    assert_not_nil ::Imprint::Tracer.get_trace_id
    assert ::Imprint::Tracer.get_trace_id=='existing_trace_id'
  end

  private

  def fake_app
    @app ||= lambda { |env| [200, {'Content-Type' => 'text/plain'}, env['PATH_INFO']] }
  end

end
