class Scan::Model::ParseMetadataJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(model_id)
    model = Model.find(model_id)
    return if model.remote?
    options = {
      # Some things are preserved if already set
      creator: model.creator,
      collection: model.collection,
      preview_file: model.preview_file
    }.compact
    # Set preview file
    options.reverse_merge! identify_preview_file(model)
    # Set path template attributes
    options.reverse_merge! attributes_from_path_template(model.path)
    # Build combined tag list
    tag_list =
      model.tag_list +
      tags_from_directory_name(model.path) +
      tags_from_path_template(model.path)
    # Load from datapackage
    if (datapackage_content = model.datapackage_content)
      data = DataPackage::ModelDeserializer.new(datapackage_content).deserialize
      # match creator
      creator_data = data.delete(:creator)
      if creator_data
        data[:creator] = creator_data[:id] ? Creator.find(creator_data.delete(:id)) :
          find_or_create_from_path_component(Creator, creator_data[:name])
        data[:creator].update(creator_data)
      end
      # match collection
      collection_data = data.delete(:collection)
      if collection_data
        data[:collection] = collection_data[:id] ? Collection.find(collection_data.delete(:id)) :
          find_or_create_from_path_component(Collection, collection_data[:name])
        data[:collection].update(collection_data)
      end
      # match preview file
      data[:preview_file] = model.model_files.find_by(filename: data[:preview_file])
      # Set file data
      data.delete(:model_files)&.each do |file|
        model.model_files.find_by(filename: file.delete(:filename))&.update(file)
      end
      # Merge in to main lists
      tag_list.concat data.delete(:tag_list) if data.key?(:tag_list)
      options.merge! data
    end
    # Make sure links are unique
    options[:links_attributes]&.filter! { |it| model.links.map(&:url).exclude?(it[:url]) }
    # Filter stop words
    options[:tag_list] = remove_stop_words(tag_list.uniq)
    # Store new metadata
    model.update!(options.compact)
  end

  private

  def identify_preview_file(model)
    {
      preview_file: model.model_files.min_by { |it| preview_priority(it) }
    }
  end

  def preview_priority(file)
    return 0 if file.is_image?
    return 1 if file.is_renderable?
    100
  end

  def tags_from_directory_name(path)
    return [] unless SiteSettings.model_tags_tag_model_directory_name
    File.split(path).last.split(/[\W_+-]/).filter { |it| it.length > 1 }
  end

  def attributes_from_path_template(path)
    return {} unless SiteSettings.parse_metadata_from_path && SiteSettings.model_path_template
    components = PathParserService.new(SiteSettings.model_path_template, path).call
    {
      creator: find_or_create_from_path_component(Creator, components[:creator]),
      collection: find_or_create_from_path_component(Collection, components[:collection]),
      name: to_human_name(components[:model_name])
    }.compact
  end

  def tags_from_path_template(path)
    return [] unless SiteSettings.parse_metadata_from_path && SiteSettings.model_path_template
    components = PathParserService.new(SiteSettings.model_path_template, path).call
    tags = components[:tags] ? components[:tags].map { |tag| tag.titleize.downcase } : []
    tags.delete("@untagged")
    tags
  end

  def remove_stop_words(words)
    return words if !SiteSettings.model_tags_filter_stop_words
    stopword_filter = Stopwords::Snowball::Filter.new(
      SiteSettings.model_tags_stop_words_locale,
      SiteSettings.model_tags_custom_stop_words
    )
    stopword_filter.filter(words)
  end

  def find_or_create_from_path_component(klass, path_component)
    return unless path_component
    klass.find_by(slug: path_component) ||
      klass.create_with(slug: path_component.parameterize).find_or_create_by(
        name: to_human_name(path_component)
      )
  end

  def to_human_name(str)
    str&.humanize&.tr("+", " ")&.careful_titleize
  end
end
