# frozen_string_literal: true

require 'avro_turf/test/fake_confluent_schema_registry_server'
require 'avro-resolution_canonical_form'

module AvroSchemaRegistry
  class FakeServer < FakeConfluentSchemaRegistryServer
    get '/subjects/:subject/fingerprints/:fingerprint' do
      subject = params[:subject]
      halt(404, SCHEMA_NOT_FOUND) unless SUBJECTS[DEFAULT_CONTEXT]&.key?(subject)

      fingerprint = params[:fingerprint]
      fingerprint = fingerprint.to_i.to_s(16) if /^\d+$/.match?(fingerprint)

      schema_id = SCHEMAS[DEFAULT_CONTEXT].find_index do |schema|
        Avro::Schema.parse(schema).sha256_resolution_fingerprint.to_s(16) == fingerprint
      end

      halt(404, SCHEMA_NOT_FOUND) unless schema_id && SUBJECTS.dig(DEFAULT_CONTEXT, subject)&.include?(schema_id)

      { id: schema_id }.to_json
    end
  end
end
