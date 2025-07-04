# frozen_string_literal: true

class Upgrade::FixNilFileSizeValues < ApplicationJob
  include JobIteration::Iteration
  unique :until_executed

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(ModelFile.unscoped.where(size: nil), cursor: cursor)
  end

  def each_iteration(modelfile)
    modelfile.attachment_attacher.refresh_metadata!
    modelfile.save(touch: false)
  rescue Shrine::FileNotFound
    Rails.logger.info("File not found during FixNilFileSizeValues upgrade job: #{modelfile.path_within_library}")
  end
end
