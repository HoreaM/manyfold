module DataPackage
  class LinkSerializer < BaseSerializer
    def serialize
      {
        path: @object.url,
        text: @object.text
      }.compact
    end
  end
end
