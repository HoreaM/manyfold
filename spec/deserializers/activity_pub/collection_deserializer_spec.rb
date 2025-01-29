require "rails_helper"

RSpec.describe ActivityPub::CollectionDeserializer do
  context "when parsing an ActivityStreams representation" do
    subject(:deserializer) { described_class.new(actor) }

    let(:actor) { create(:actor) }
    let(:output) { deserializer.deserialize }

    it_behaves_like "GenericDeserializer"
  end
end
