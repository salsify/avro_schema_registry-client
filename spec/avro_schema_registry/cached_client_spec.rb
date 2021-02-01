# frozen_string_literal: true

describe AvroSchemaRegistry::CachedClient do
  let(:upstream) { instance_double(AvroSchemaRegistry::Client) }

  describe "#lookup_subject_schema" do
    let(:subject_name) { 'subject_name' }
    let(:schema) { { type: :record, name: :exmaple, fields: [] }.to_json }
    let(:result) { { 'id' => 123 } }

    subject(:client) { described_class.new(upstream) }

    before do
      allow(upstream).to receive(:lookup_subject_schema).and_return(result)
    end

    it "delegates the method to the upstream client", :aggregate_failures do
      expect(client.lookup_subject_schema(subject_name, schema)).to equal(result)
      expect(upstream).to have_received(:lookup_subject_schema).with(subject_name, schema)
    end
  end
end
