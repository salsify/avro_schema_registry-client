# frozen_string_literal: true

require 'avro_turf'
require 'avro_turf/confluent_schema_registry'
require 'avro-resolution_canonical_form'

module AvroSchemaRegistry
  class Client < AvroTurf::ConfluentSchemaRegistry

    def lookup_subject_schema(subject, schema)
      schema_object = if schema.is_a?(String)
                        Avro::Schema.parse(schema)
                      else
                        schema
                      end

      data = get("/subjects/#{subject}/fingerprints/#{schema_object.sha256_resolution_fingerprint.to_s(16)}")
      id = data.fetch('id')
      @logger.info("Found schema for subject `#{subject}`; id = #{id}")
      id
    end

    # Override register to first check if a schema is registered by fingerprint
    # Also, allow additional params to be passed to register.
    def register(subject, schema, **params)
      lookup_subject_schema(subject, schema)
    rescue Excon::Errors::NotFound
      register_without_lookup(subject, schema, **params)
    end

    def register_without_lookup(subject, schema, **params)
      data = post("/subjects/#{subject}/versions",
                  body: { schema: schema.to_s }.merge!(params).to_json)
      id = data.fetch('id')
      @logger.info("Registered schema for subject `#{subject}`; id = #{id}")
      id
    end

    # Override to add support for additional params
    def compatible?(subject, schema, version = 'latest', **params)
      data = post("/compatibility/subjects/#{subject}/versions/#{version}",
                  expects: [200, 404],
                  body: { schema: schema.to_s }.merge!(params).to_json)
      data.fetch('is_compatible', false) unless data.key?('error_code')
    end

    private

    # Excon caches a socket per thread and only resets the connection when a
    # StandardError escapes a request, so a non-StandardError interrupt --
    # Rack::Timeout::RequestTimeoutException subclasses Exception and arrives
    # via Thread#raise -- leaves a partially read socket in that cache. The next
    # request on the thread then reads the previous response and returns another
    # subject's schema id. `rescue` rather than `ensure` so that only an
    # abnormal, non-StandardError exit resets, leaving the paths Excon already
    # handles (including a completed response with an unexpected status)
    # untouched. A bare re-raise preserves the original exception and backtrace,
    # so a request timeout still terminates the request.
    def request(path, **options)
      super
    rescue Exception => e # rubocop:disable Lint/RescueException
      @connection.reset unless e.is_a?(StandardError)
      raise
    end
  end
end
