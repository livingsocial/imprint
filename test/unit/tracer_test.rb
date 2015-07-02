require File.expand_path('../../test_helper', __FILE__)

class TracerTest < Minitest::Test

  should "set trace id" do
    fake_trace = "tracer"
    Imprint::Tracer.set_trace_id(fake_trace, fake_rack_env)
    assert_equal fake_trace, Imprint::Tracer.get_trace_id
  end

  should "set trace timestamp" do
    fake_trace = "tracer"
    Timecop.freeze do
      test_time = Time.now.utc
      Imprint::Tracer.set_trace_id(fake_trace, fake_rack_env)
      # timecop has a bug with millisec time on osx
      # this makes the check ignore millisec
      assert !!Imprint::Tracer.get_trace_timestamp.to_s.match(/#{test_time.strftime("%Y-%m-%dT%H:%M:%S")}/)
    end
  end

  should "get trace id defaults" do
    assert_equal Imprint::Tracer::TRACE_ID_DEFAULT, Imprint::Tracer.get_trace_id
    Imprint::Tracer.set_trace_id("fake_trace", fake_rack_env)
    refute_nil Imprint::Tracer.get_trace_id
    Imprint::Tracer.set_trace_id(nil, fake_rack_env)
    assert_equal Imprint::Tracer::TRACE_ID_DEFAULT, Imprint::Tracer.get_trace_id
  end

  should "get trace timestamp defaults" do
    Timecop.freeze do
      test_time = Time.now.utc
      # timecop has a bug with millisec time on osx
      # this makes the check ignore millisec
      assert !!Imprint::Tracer.get_trace_timestamp.to_s.match(/#{test_time.strftime("%Y-%m-%dT%H:%M:%S")}/)
    end
  end
  
  should "generate rand trace id" do
    trace_id = Imprint::Tracer.rand_trace_id
    refute_nil trace_id
    assert_equal 36, trace_id.length
    assert trace_id.match(/[a-f0-9\-]/)
  end

  protected

  def fake_rack_env
    {}
  end

end
