require 'avro_turf/cached_confluent_schema_registry'

module AvroSchemaRegistry
  class CachedClient < AvroTurf::CachedConfluentSchemaRegistry

    # delegate additional method to upstream
    def lookup_subject_schema(subject, schema)
      @upstream.lookup_subject_schema(subject, schema)
    end
  end
end
