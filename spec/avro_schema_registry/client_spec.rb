require 'logger'

describe AvroSchemaRegistry::Client do
  let(:registry_url) { 'https://registry.example.com' }
  let(:logger) { Logger.new(StringIO.new) }
  let(:subject_name) { 'some-subject' }
  let(:schema) do
    {
      type: 'record',
      name: 'person',
      fields: [
        { name: 'name', type: 'string', default: 'unknown' }
      ]
    }.to_json
  end
  let(:avro_schema) { Avro::Schema.parse(schema) }
  let(:registry) { described_class.new(registry_url, logger: logger) }

  before do
    WebMock.stub_request(:any, /^#{registry_url}/).to_rack(AvroSchemaRegistry::FakeServer)
    AvroSchemaRegistry::FakeServer.clear
  end

  describe "#register" do
    it "allows registration of an Avro JSON schema" do
      id = registry.register(subject_name, schema)
      expect(registry.fetch(id)).to eq(avro_schema.to_s)
    end

    it "allows the registration of an Avro::Schema" do
      id = registry.register(subject_name, avro_schema)
      expect(registry.fetch(id)).to eq(avro_schema.to_s)
    end

    it "makes a request to check if the schema exists before attempting to register" do
      id = registry.register(subject_name, avro_schema)
      allow(registry).to receive(:post)
      expect(registry.register(subject_name, avro_schema)).to eq(id)
      expect(registry).not_to have_received(:post)
    end

    it "allows compatibility parameters to be specified" do
      id = registry.register(subject_name, avro_schema,
                             with_compatibility: 'NONE', after_compatibility: 'FULL')
      expect(registry.fetch(id)).to eq(avro_schema.to_s)
    end

    context "when the check prior to registration raises an error other than NotFound" do
      before do
        allow(registry).to receive(:get).and_raise(Excon::Errors::InternalServerError.new('error'))
      end

      it "raises the error" do
        expect do
          registry.register(subject_name, schema)
        end.to raise_error(Excon::Errors::InternalServerError)
      end
    end
  end

  describe "#register_without_lookup" do
    it "allows registration of an Avro JSON schema" do
      id = registry.register_without_lookup(subject_name, schema)
      expect(registry.fetch(id)).to eq(avro_schema.to_s)
    end

    it "allows the registration of an Avro::Schema" do
      id = registry.register_without_lookup(subject_name, avro_schema)
      expect(registry.fetch(id)).to eq(avro_schema.to_s)
    end

    it "does not makes a request to lookup the schema before attempting to register" do
      id = registry.register_without_lookup(subject_name, avro_schema)
      allow(registry).to receive(:post).and_return('id' => id)
      expect(registry.register_without_lookup(subject_name, avro_schema)).to eq(id)
      expect(registry).to have_received(:post)
    end

    it "allows compatibility parameters to be specified" do
      id = registry.register_without_lookup(subject_name, avro_schema,
                                            with_compatibility: 'NONE', after_compatibility: 'FULL')
      expect(registry.fetch(id)).to eq(avro_schema.to_s)
    end
  end

  describe "#register_and_lookup" do
    it "allows registration of an Avro JSON schema" do
      id = registry.register_and_lookup(subject_name, schema)
      expect(registry.fetch(id)).to eq(avro_schema.to_s)
    end

    it "allows the registration of an Avro::Schema" do
      id = registry.register_and_lookup(subject_name, avro_schema)
      expect(registry.fetch(id)).to eq(avro_schema.to_s)
    end

    it "makes a request to check if the schema exists after attempting to register" do
      allow(registry).to receive(:get).and_call_original
      registry.register_and_lookup(subject_name, avro_schema)
      expect(registry).to have_received(:get)
    end

    it "allows compatibility parameters to be specified" do
      id = registry.register_and_lookup(subject_name, avro_schema,
                                        with_compatibility: 'NONE', after_compatibility: 'FULL')
      expect(registry.fetch(id)).to eq(avro_schema.to_s)
    end
  end

  describe "#lookup_subject_schema" do
    context "when the schema does not exist" do
      it "raises an error" do
        expect do
          registry.lookup_subject_schema(subject_name, schema)
        end.to raise_error(Excon::Errors::NotFound)
      end
    end

    context "with a previously registered schema" do
      let!(:id) { registry.register(subject_name, schema) }

      it "allows lookup using an Avro JSON schema" do
        expect(registry.lookup_subject_schema(subject_name, schema)).to eq(id)
      end

      it "allows lookup using an Avro::Schema object" do
        expect(registry.lookup_subject_schema(subject_name, avro_schema)).to eq(id)
      end
    end
  end

  describe "#compatible?" do
    let(:compatibility) { 'BACKWARD' }

    before do
      # The fake schema registry does not support the compatibility endpoint
      WebMock.stub_request(
        :post,
        "#{registry_url}/compatibility/subjects/#{subject_name}/versions/latest"
      ).with(body: { schema: schema, with_compatibility: compatibility }.to_json)
        .to_return(status: 200, body: { is_compatible: true }.to_json)
    end

    it "allows additional parameters to be specified" do
      expect(registry.compatible?(subject_name,
                                  schema,
                                  'latest',
                                  with_compatibility: compatibility)).to eq(true)
    end
  end
end
