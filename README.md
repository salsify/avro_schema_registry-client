# AvroSchemaRegistry::Client

Client for the [avro-schema-registry](https://github.com/salsify/avro-schema-registry)
app.

This client extends [AvroTurf::ConfluentSchemaRegistry](https://github.com/dasch/avro_turf)
to support [extensions](https://github.com/salsify/avro-schema-registry#extensions)
provided by avro-schema-registry

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'avro_schema_registry-client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install avro_schema_registry-client

## Usage

Create a client:

```ruby
client = AvroSchemaRegistry::Client.new(registry_url, logger: logger)
```

Create a client that caches the responses for requests to fetch or register
an `Avro::Schema`:

```ruby
cached_client = AvroSchemaRegistry::CachedClient.new(
  AvroSchemaRegistry::Client.new(registry_url, logger: logger)
)
```

### Fake Server

This gem also provides a fake avro-schema-registry server that can be used in
tests. This fake server depends on sinatra, which must be explicitly added
as a dependency:

```ruby
require 'avro_schema_registry/test/fake_server'

# before hook with rspec
before do
  WebMock.stub_request(:any, /^#{registry_url}/).to_rack(AvroSchemaRegistry::FakeServer)
  AvroSchemaRegistry::FakeServer.clear
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/salsify/avro_schema_registry-client.## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

