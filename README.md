# SafetyDance

A Response Object pattern for resilient Ruby code.

Example:

```ruby
SafetyDance.new { dance! }.
  then { |result| leave_friends_behind(!result) }.
  rescue { |error| not_friends_of_mine(error) }.
  value!
```

Strongly inspired by [John Nunemaker's 'Resilience in Ruby: Handling Failure'](https://johnnunemaker.com/resilience-in-ruby/)
post, and the implementation of [Github::Result]( https://github.com/github/github-ds/blob/fbda5389711edfb4c10b6c6bad19311dfcb1bac1/lib/github/result.rb).

Quoting the post:

> By putting a response object in between the caller and the call to get the data:

> - we always return the same object, avoiding `nil` and retaining duck typing.
> - we now have a place to add more context about the failure if necessary, which we did not have with `nil`.
> - we have a single place to update rescued exceptions if a new one pops up.
> - we have a nice place for instrumentation and circuit breakers in the future.
> - we avoid needing `begin` and `rescue` all over and instead can use conditionals or whatever makes sense.
> - we give the caller the ability to handle different failures differently (Conn refused vs Timeout vs Rate limited, etc.).

> The key to me including *a layer on top* that bakes in the resiliency,
> making it easy for callers to do the right thing in the face of failure.
> Using response objects can definitely help with that.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'safety_dance'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install safety_dance

Or just copy the relevant code into your project somewhere, such as this minimal implementation:

```ruby
class Result
  def initialize
    @value = yield
    @error = nil
  rescue => e
    @error = e
  end

  def ok?
    @error.nil?
  end

  def value!
    if ok?
      @value
    else
      raise @error
    end
  end

  def rescue
    return self if ok?
    Result.new { yield(@error) }
  end
end
```

## Usage

Start with passing a block to `SafetyDance.new`, and continue with the available API.

### Instance methods

| method call |  returns  |
|------------ | --------- |
| ok?         | true if value when no error else false
| value!      | value if no error else raises error
| error       | the rescued error


### Instance chain methods

| method call | call conditions  | yields          | returns  |
|------------ |----------------- |---------------- |--------- |
| then        |  ok?             | return value    | instance |
| rescue      |  error           | rescued error   | instance |

## Development

1. Check out the repo.
2. Run `bin/setup` to install dependencies.
3. Run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bf4/safety_dance.

This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SafetyDance project’s codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bf4/safety_dance/blob/master/CODE_OF_CONDUCT.md).
