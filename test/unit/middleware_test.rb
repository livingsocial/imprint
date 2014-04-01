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
    assert_not_nil ::Imprint::Middleware.get_trace_id
    assert ::Imprint::Middleware.get_trace_id!='-1'
  end

  private

  def fake_app
    @app ||= lambda { |env| [200, {'Content-Type' => 'text/plain'}, env['PATH_INFO']] }
  end

end
