module ManyfoldApi::V0
  class LinkSerializer < ApplicationSerializer
    def serialize
      {
        url: @object.url,
        text: @object.text
      }.compact
    end

    def self.schema
      LinkDeserializer.schema
    end
  end
end
