require "rails_helper"

RSpec.describe DataPackage::LinkDeserializer do
  context "when parsing a Data Package" do
    subject(:deserializer) { described_class.new(object) }

    let(:output) { deserializer.deserialize }
    let(:object) do
      {
        "path" => "http://example.com",
        "text" => "anchor text"
      }
    end

    it "parses url" do
      expect(output[:url]).to eq "http://example.com"
    end

    it "parses text" do
      expect(output[:text]).to eq "anchor text"
    end
  end
end
