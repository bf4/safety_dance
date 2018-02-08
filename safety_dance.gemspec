
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "safety_dance/version"

Gem::Specification.new do |spec|
  spec.name          = "safety_dance"
  spec.version       = SafetyDance::VERSION
  spec.authors       = ["Benjamin Fleischer"]
  spec.email         = ["github@benjaminfleischer.com"]

  spec.summary       = %q{Response Objects pattern for resilient Ruby}
  spec.description   = %q{SafetyDance.new { dance! }.then { |result| leave_friends_behind(result) }.rescue { |error| not_friends_of_mine(error) }.value!}
  spec.homepage      = "https://github.com/bf4/safety_dance"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
