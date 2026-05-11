# frozen_string_literal: true

class Upgrade::RemoveDuplicateCollectionRelationsJob < ApplicationJob
  def perform
    duplicates = CollectionsModel.group("model_id", "collection_id").count.select { |ids, count| count > 1 }
    duplicates.each do |ids, count|
      CollectionsModel.where(model_id: ids[0], collection_id: ids[1]).limit(count - 1).each { |x| x.destroy }
    end
  end
end
