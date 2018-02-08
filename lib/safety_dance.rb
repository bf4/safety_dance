require "safety_dance/version"

# Generic 'Result' object for declarative result success/failure/cascade handling.
#
# Usage:
#
#   def some_action_that_succeeds(msg); msg; end
#   def some_action_that_fails(msg); raise msg; end
#
#   SafetyDance.new { some_action_that_succeeds(:success) } #=> SafetyDance
#
#   SafetyDance.new { some_action_that_succeeds(:success) }
#     .value {|error| "action failed with error #{error}" } #=> :success
#
#   SafetyDance.new { some_action_that_fails("fail")}
#     .value {|error| "action failed with error #{error}" } #=> "action failed with error 'RuntimeError fail'"
#
#   SafetyDance.new { some_action_that_succeeds(:success) }
#     .then { some_action_that_succeeds(:another_success }
#     .value {|error| "I am handling #{error}" } # => :another_success
#
#   SafetyDance.new { some_action_that_fails("fail1") }
#     .then { some_action_that_fails("fail2") }
#     .then { some_action_that_succeeds(:another_success }
#     .then { some_action_that_fails("fail3") }
#     .value {|error| "I am handling #{error}" } # I am handling 'RuntimeError fail1'"
#
# Result object pattern is from https://johnnunemaker.com/resilience-in-ruby/
# e.g. https://github.com/github/github-ds/blob/fbda5389711edfb4c10b6c6bad19311dfcb1bac1/lib/github/result.rb
class SafetyDance
  def initialize
    @value = yield
    @error = nil
  rescue => e
    @error = e
  end

  def ok?
    @error.nil?
  end

  def to_s
    if ok?
      "#<SafetyDance:0x%x value: %s>" % [object_id, @value.inspect]
    else
      "#<SafetyDance:0x%x error: %s>" % [object_id, @error.inspect]
    end
  end

  alias_method :inspect, :to_s

  def error
    @error
  end

  def value
    unless block_given?
      fail ArgumentError, "must provide a block to SafetyDance#value to be invoked in case of error"
    end
    if ok?
      @value
    else
      yield @error
    end
  end

  def value!
    if ok?
      @value
    else
      raise @error
    end
  end

  def then
    return self if !ok?
    SafetyDance.new { yield(@value) }
  end

  def then_tap
    self.then do |value|
      yield value
      value
    end
  end

  def rescue
    return self if ok?
    result = SafetyDance.new { yield(@error) }
    if result.ok? && result.value! == @error
      self
    else
      result
    end
  end

  def self.error(e)
    result = allocate
    result.instance_variable_set(:@error, e)
    result
  end
end
