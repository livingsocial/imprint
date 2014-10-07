require File.expand_path('../test_helper', File.dirname(__FILE__))

class TracerTest < Minitest::Test

  should "set trace id" do
    fake_trace = "tracer"
    Imprint::Tracer.set_trace_id(fake_trace, fake_rack_env)
    assert_equal fake_trace, Imprint::Tracer.get_trace_id
  end

  should "get trace id defaults" do
    refute_nil Imprint::Tracer.get_trace_id
    Imprint::Tracer.set_trace_id(nil, fake_rack_env)
    assert_equal nil, Imprint::Tracer.get_trace_id
  end

  should "generate rand trace id" do
    trace_id = Imprint::Tracer.rand_trace_id
    refute_nil trace_id
    assert_equal 6, trace_id.length
    assert trace_id.match(/[A-Za-z]/)
  end

  protected

  def fake_rack_env
    {}
  end

end
