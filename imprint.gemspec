# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'imprint/version'

Gem::Specification.new do |spec|
  spec.name          = "imprint"
  spec.version       = Imprint::VERSION
  spec.authors       = ["Dan Mayer"]
  spec.email         = ["dan.mayer@livingsocial.com"]
  spec.description   = %q{A gem to help improve logging. Focused on request tracing and cross app tracing.}
  spec.summary       = %q{A gem to help improve logging. Focused on request tracing and cross app tracing.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "mocha", "~> 0.14.0"
  spec.add_development_dependency "shoulda"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "simplecov"
end
