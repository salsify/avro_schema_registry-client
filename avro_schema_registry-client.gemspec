# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'avro_schema_registry/version'

Gem::Specification.new do |spec|
  spec.name          = 'avro_schema_registry-client'
  spec.version       = AvroSchemaRegistry::VERSION
  spec.authors       = ['Salsify, Inc']
  spec.email         = ['engineering@salsify.com']

  spec.summary       = 'Client for the avro-schema-registry app'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/salsify/avro_schema_registry-client'

  spec.license       = 'MIT'

  # Set 'allowed_push_post' to control where this gem can be published.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
    spec.metadata['rubygems_mfa_required'] = 'true'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'overcommit'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'salsify_rubocop', '~> 1.27.1'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock'
  # For AvroSchemaRegistry::FakeServer
  spec.add_development_dependency 'sinatra'

  spec.add_runtime_dependency 'avro-resolution_canonical_form', '>= 0.2.0'
  spec.add_runtime_dependency 'avro_turf', '>= 0.8.0'
end
