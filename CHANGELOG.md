# avro_schema_registry-client

## v0.6.1
- Reset the Excon connection when a non-`StandardError` exception interrupts a
  registry request, so that a partially read socket is not reused by the next
  request on the same thread.

## v0.6.0
- Update `avro_turf` dependency to >= 1.20.1
- Remove `sinatra` development dependency (no longer needed as `avro_turf` 1.20.1+ uses a custom Rack-based implementation)

## v0.5.0
- Require Ruby 2.7+

## v0.4.0
- Require Ruby 2.5+.
- Add support for Ruby 3.0.

## v0.3.0
- Require `avro-resolution_canonical_form` v0.2.0 or later to use
  `avro-patches`.

## v0.2.0
- Add `register_without_lookup` method to `AvroSchemaRegistry::Client`.

## v0.1.0
- Initial version
