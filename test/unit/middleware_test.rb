require File.expand_path('../../test_helper', __FILE__)

class MiddlewareTest < Minitest::Test

  def setup
    @logger = Minitest::Mock.new
    Imprint::Middleware.logger = @logger
  end

  def teardown
    Imprint::Middleware.logger = nil
    @logger.verify
  end

  should "call app" do
    request = Rack::MockRequest.env_for("/anything.json")
    middleware = Imprint::Middleware.new(fake_app)
    @logger.expect(:info, nil) { true }
    results = middleware.call(request)
    assert_equal "/anything.json", results.last
  end

  should 'pass all rack lint checks' do
    app = Rack::Lint.new(Imprint::Middleware.new(fake_app))
    env = Rack::MockRequest.env_for('/hello')
    @logger.expect(:info, nil) { true }
    app.call(env)
  end

  should "set trace_id before calling app" do
    request = Rack::MockRequest.env_for("/anything.json")
    middleware = Imprint::Middleware.new(fake_app)
    @logger.expect(:info, nil) {|x| x=~ /trace_status=initiated/ }

    results = middleware.call(request)
    assert_equal "/anything.json", results.last
    assert ::Imprint::Tracer.get_trace_id != ::Imprint::Tracer::TRACE_ID_DEFAULT
  end

  should "set trace_id from rails request_id" do
    request = Rack::MockRequest.env_for("/anything.json", {"action_dispatch.request_id" => 'existing_id' })
    middleware = Imprint::Middleware.new(fake_app)
    results = middleware.call(request)
    assert_equal "/anything.json", results.last
    refute_nil ::Imprint::Tracer.get_trace_id
    assert_equal 'existing_id', ::Imprint::Tracer.get_trace_id
  end

  should "set trace_id from passed in imprint header" do
    request = Rack::MockRequest.env_for("/anything.json", {"HTTP_IMPRINTID" => 'existing_trace_id' })
    middleware = Imprint::Middleware.new(fake_app)
    results = middleware.call(request)
    assert_equal "/anything.json", results.last
    refute_nil ::Imprint::Tracer.get_trace_id
    assert_equal 'existing_trace_id', ::Imprint::Tracer.get_trace_id
  end

  private

  def fake_app
    @app ||= lambda { |env| [200, {'Content-Type' => 'text/plain'}, env['PATH_INFO']] }
  end

end
