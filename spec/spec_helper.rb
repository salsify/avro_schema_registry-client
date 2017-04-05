$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'avro_schema_registry-client'

require 'webmock/rspec'
require 'avro_schema_registry/test/fake_server'
