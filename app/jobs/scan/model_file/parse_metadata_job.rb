class Scan::ModelFile::ParseMetadataJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(file_id)
    file = ModelFile.find(file_id)
    # Try to guess if the file is presupported
    if !(
      file.path_within_library.split(/[[:punct:]]|[[:space:]]/).map(&:downcase) & ModelFile::SUPPORT_KEYWORDS
    ).empty?
      file.update!(presupported: true)
    end
    # Queue up deeper analysis job
    file.analyse_later
  end
end
