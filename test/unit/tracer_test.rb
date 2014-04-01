require File.expand_path('../test_helper', File.dirname(__FILE__))

class TracerTest < Test::Unit::TestCase

  should "set trace id" do
    fake_trace = "tracer"
    Imprint::Tracer.set_trace_id(fake_trace)
    assert_equal fake_trace, Imprint::Tracer.get_trace_id
  end

  should "get trace id defaults" do
    assert_not_nil Imprint::Tracer.get_trace_id
  end

  should "generate rand trace id" do
    trace_id = Imprint::Tracer.rand_trace_id
    assert_not_nil trace_id
    assert_equal 6, trace_id.length
    assert trace_id.match(/[A-Za-z]/)
  end

end
