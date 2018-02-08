RSpec.describe SafetyDance do

  def some_action_that_succeeds(msg); msg; end
  def some_action_that_fails(msg); raise msg; end

  it "returns a result object" do
    result = SafetyDance.new { some_action_that_succeeds(:success) }
    expect(result).to be_a(SafetyDance)
  end

  specify "inspecting a result object shows its value" do
    result = SafetyDance.new { some_action_that_succeeds(:success) }
    hex_id = format("%x", result.object_id)
    expect(result.to_s).to eq("#<SafetyDance:0x#{hex_id} value: :success>")
    expect(result.inspect).to eq("#<SafetyDance:0x#{hex_id} value: :success>")
  end

  specify "inspecting a result object shows its error" do
    result = SafetyDance.new { some_action_that_fails("omg") }
    hex_id = format("%x", result.object_id)
    expect(result.to_s).to eq("#<SafetyDance:0x#{hex_id} error: #<RuntimeError: omg>>")
    expect(result.inspect).to eq("#<SafetyDance:0x#{hex_id} error: #<RuntimeError: omg>>")
  end

  specify "a successful result is ok?" do
    result = SafetyDance.new { some_action_that_succeeds(:success) }
    expect(result).to be_ok
  end

  specify "a failed result is not ok?" do
    result = SafetyDance.new { some_action_that_fails("failed") }
    expect(result).not_to be_ok
  end

  specify "SafetyDance#value returns the value of the successful operation" do
    result = SafetyDance.new { some_action_that_succeeds(:success) }
      .value {|error| "action failed with error #{error}" }
    expect(result).to eq(:success)
  end

  specify "SafetyDance#value yields the error to the block on failed operation" do
    result = SafetyDance.new { some_action_that_fails("fail") }
      .value {|error| "action failed with error #{error}" }
    expect(result).to eq("action failed with error fail")
  end

  specify "SafetyDance#value! returns the value of the successful operation" do
    result = SafetyDance.new { some_action_that_succeeds(:success) }
      .value!
    expect(result).to eq(:success)
  end

  specify "SafetyDance#value! raises the error" do
    expect {
      SafetyDance.new { some_action_that_fails("fail") }.value!
    }.to raise_error(RuntimeError) {|e|
      expect(e.message).to eq("fail")
    }
  end

  specify "SafetyDance#then is executed when the previous result is ok" do
    result = SafetyDance.new { some_action_that_succeeds(:success) }
    .then { some_action_that_succeeds(:another_success) }
    .value {|error| "I am handling #{error}" }
    expect(result).to eq(:another_success)
  end

  specify "SafetyDance#then returns the first failed result at the end of a result chain" do
    result = SafetyDance.new { some_action_that_fails("first failure") }
      .then { some_action_that_fails("never reached failure") }
      .then { some_action_that_succeeds(:never_reached_success) }
      .then { some_action_that_fails("another never reached failure") }
      .value {|error| "I am handling #{error}" }
    expect(result).to eq("I am handling first failure")
  end

  specify "SafetyDance#rescue allows recovery from an error" do
    result = SafetyDance.new { some_action_that_fails("fail") }
      .rescue {|error| some_action_that_succeeds("Recovered from '#{error}'") }
    expect(result).to be_ok
    expect(result.value!).to eq("Recovered from 'fail'")
  end

  specify "SafetyDance#rescue is executed when the previous result is an error" do
    result = SafetyDance.new { some_action_that_succeeds("success") }
      .rescue {|error| some_action_that_succeeds("Not executed after success: '#{error}'") }
      .then { some_action_that_fails("failure") }
      .rescue {|error| some_action_that_succeeds("Recovered from '#{error}'") }
    expect(result).to be_ok
    expect(result.value!).to eq("Recovered from 'failure'")
  end

  specify "SafetyDance#rescue can itself fail and be rescued" do
    result = SafetyDance.new { some_action_that_fails("failure") }
      .rescue {|error| some_action_that_fails("Recover of '#{error}' failed") }
      .then { some_action_that_succeeds("unreached success") }
      .then { some_action_that_fails("unreached failure") }
      .rescue {|error| some_action_that_succeeds("Recovered from '#{error}'") }
    expect(result).to be_ok
    expect(result.value!).to eq("Recovered from 'Recover of 'failure' failed'")
  end

  specify "SafetyDance#rescue can no-op by returning the yielded error" do
    result = SafetyDance.new { some_action_that_fails("failure is passed through") }
      .rescue {|error|
        case error
        when RuntimeError then error
        else some_action_that_succeeds("not reached")
        end
      }
      .then { some_action_that_succeeds("unreached success") }
      .then { some_action_that_fails("unreached failure") }
    expect(result).not_to be_ok
    hex_id = format("%x", result.object_id)
    expect(result.to_s).to eq("#<SafetyDance:0x#{hex_id} error: #<RuntimeError: failure is passed through>>")
  end
end
