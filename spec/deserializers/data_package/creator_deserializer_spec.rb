require "rails_helper"

RSpec.describe DataPackage::CreatorDeserializer do
  context "when parsing a Data Package" do
    subject(:deserializer) { described_class.new(object) }

    let(:output) { deserializer.deserialize }

    context "with a valid creator linked to this server" do
      let(:creator) { create(:creator) }
      let(:object) do
        {
          "title" => creator.name,
          "path" => "http://localhost:3214/creators/#{creator.to_param}",
          "roles" => ["creator"]
        }
      end

      it "parses name" do
        expect(output[:name]).to eq creator.name
      end

      it "matches creator ID" do
        expect(output[:id]).to eq creator.id
      end
    end

    context "with a valid creator hosted elsewhere" do
      let(:object) do
        {
          "title" => "Bruce Wayne",
          "path" => "http://example.com/bruce-wayne",
          "roles" => ["creator"]
        }
      end

      it "parses name" do
        expect(output[:name]).to eq "Bruce Wayne"
      end

      it "extracts links" do
        expect(output[:links_attributes]).to include({
          url: "http://example.com/bruce-wayne"
        })
      end
    end

    context "with a non-creator contributor" do
      let(:object) do
        {
          "title" => "Contributor Name",
          "path" => "http://localhost:3214/creators/creator-name",
          "roles" => ["contributor"]
        }
      end

      it "ignores item" do
        expect(output).to be_nil
      end
    end
  end
end
