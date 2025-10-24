module ApplicationHelper
  def site_name(default: translate("application.title"))
    SiteSettings.site_name.presence || default
  end

  def site_tagline
    SiteSettings.site_tagline.presence || t("application.tagline")
  end

  def site_icon
    SiteSettings.site_icon.presence || "roundel.svg"
  end

  def icon(icon, label, id: nil, effect: nil)
    render Components::Icon.new(icon: icon, label: label, id: id, effect: effect)
  end

  def icon_for(klass)
    case klass.name
    when "Creator"
      "person"
    when "Collection"
      "collection"
    when "Library"
      "boxes"
    when "Model"
      "box"
    when "ModelFile"
      "file"
    when "User"
      "person"
    end
  end

  def markdownify(text)
    Kramdown::Document.new(
      sanitize(text),
      header_offset: 2,
      input: "GFM"
    ).to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def card(style, title = nil, options = {}, &content)
    id = options[:id] || "card-#{SecureRandom.hex(4)}"
    card_class = ["card", "mb-4", options[:class]].join(" ")
    if options[:skip_link]
      skiplink = skip_link(options[:skip_link][:target], options[:skip_link][:text])
      card_class += " skip-link-container"
    end
    tag.div class: card_class do
      safe_join([
        if title.present?
          tag.div(class: "card-header text-white bg-#{style}") do
            options[:collapse] ?
              safe_join([
                title,
                tag.span(icon("arrows-expand", t("general.expand")), class: "float-end d-#{options[:collapse]}-none"),
                tag.a(
                  nil,
                  class: "link-unstyled stretched-link d-#{options[:collapse]}-none",
                  "data-bs-toggle": "collapse",
                  "data-bs-target": "##{id}",
                  "aria-expanded": false,
                  "aria-controls": id
                )
              ]) :
              title
          end
        end,
        skiplink,
        tag.div(class: "card-body #{"collapse d-#{options[:collapse]}-block" if options[:collapse]}", id: id) do
          tag.div class: "card-text" do
            yield
          end
        end
      ].compact)
    end
  end

  def text_input_row(form, name, options = {})
    safe_join([
      content_tag(:div) do
        form.label(name, options[:label])
      end,
      content_tag(:div) do
        safe_join [
          form.text_field(name, {class: "form-control"}.merge(options)),
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ])
  end

  def password_input_row(form, name, options = {})
    field_options = {class: "form-control"}.merge(options)
    if options[:strength_meter]
      field_options["data-controller"] = "zxcvbn"
      field_options["data-action"] = "input->zxcvbn#onInput"
    end
    safe_join([
      content_tag(:div) do
        form.label(name, options[:label])
      end,
      content_tag(:div) do
        safe_join [
          form.password_field(name, field_options),
          (if options[:strength_meter]
             content_tag(:div, class: "progress") do
               content_tag(:div, nil, class: "progress-bar w-0 zxcvbn-meter", "data-zxcvbn-min-score": Devise.min_password_score)
             end
           end),
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ])
  end

  def url_input_row(form, name, options = {})
    safe_join([
      content_tag(:div) do
        form.label(name, options[:label])
      end,
      content_tag(:div) do
        safe_join [
          form.url_field(name, {class: "form-control"}.merge(options)),
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ])
  end

  def rich_text_input_row(form, name, options = {})
    safe_join([
      content_tag(:div) do
        form.label(name, options[:label])
      end,
      content_tag(:div) do
        safe_join [
          form.text_area(name, {class: "form-control g-col-auto"}.merge(options)),
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ])
  end

  def checkbox_input_row(form, name, options = {})
    safe_join([
      content_tag(:div) do
        form.label(name, options[:label])
      end,
      content_tag(:div) do
        content_tag(:div, class: "form-switch") do
          safe_join [
            form.check_box(name, options.merge(class: "form-check-input form-check-inline")),
            errors_for(form.object, name),
            (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
          ].compact
        end
      end
    ])
  end

  def select_input_row(form, name, select_options, options = {})
    safe_join([
      content_tag(:div) do
        form.label(name, options[:label])
      end,
      content_tag(:div) do
        safe_join [
          content_tag(:div, class: "input-group") do
            safe_join [
              form.select(name, select_options, options.compact, {data: {controller: "searchable-select"}, class: "form-control g-col-auto form-select #{"is-invalid" if form.object&.errors&.include?(name) && !form.object.errors[name].empty?}"}),
              (link_to(options[:button][:label], options[:button][:path], class: "btn btn-outline-secondary g-col-auto") if options[:button])
            ]
          end,
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ])
  end

  def collection_select_input_row(form, name, collection, value_method, text_method, options = {})
    safe_join([
      content_tag(:div) do
        form.label(name, options[:label])
      end,
      content_tag(:div) do
        safe_join [
          content_tag(:div, class: "input-group") do
            safe_join [
              form.collection_select(:"#{name}_id", collection, value_method, text_method, options.compact, {data: {controller: "searchable-select"}, class: "form-control g-col-auto form-select #{"is-invalid" if form.object&.errors&.include?(name) && !form.object.errors[name].empty?}"}),
              (link_to(options[:button][:label], options[:button][:path], class: "btn btn-outline-secondary g-col-auto") if options[:button])
            ]
          end,
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ])
  end

  def file_input_row(form, name, options = {})
    safe_join([
      content_tag(:div) do
        form.label(name, options[:label])
      end,
      content_tag(:div) do
        safe_join [
          content_tag(:div, class: "input-group") do
            safe_join [
              form.file_field(name, class: "form-control"),
              options[:remove] ? form.check_box(:"remove_#{name}", class: "btn-check", autocomplete: "off") : nil,
              options[:remove] ? form.label(:"remove_#{name}", icon("trash", options[:remove_label]), class: "btn btn-outline-danger") : nil
            ].compact
          end,
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ])
  end

  def nav_link(ico, text, path, options = {})
    link_to(
      safe_join(
        [
          content_tag(:span, icon(ico, options[:title].presence || text), class: options[:icon_style]),
          content_tag(:span, text, class: options[:text_style])
        ],
        " "
      ),
      path,
      class: options[:style] || safe_join(["nav-link", (current_page?(path) ? "active" : "")], " "),
      method: options[:method],
      nofollow: options[:nofollow],
      "aria-label": options[:aria_label]
    )
  end

  def errors_for(record, attribute)
    return if record.nil? || attribute.nil?
    return unless record.errors.include? attribute
    content_tag(:div,
      record.errors.full_messages_for(attribute).join("; "),
      class: "invalid-feedback d-block")
  end

  def skip_link(target, text)
    content_tag :div, class: "container-fluid skip-link text-bg-success p-2" do
      link_to text, "##{target}", class: "text-reset"
    end
  end

  def translate_with_locale_wrapper(key, **options)
    translate(key, **options) do |str, _key|
      str&.locale ? content_tag(:span, lang: str.locale) { sanitize str } : str
    end
  end
  alias_method :t, :translate_with_locale_wrapper

  def pagination_settings
    current_user&.pagination_settings || SiteSettings::UserDefaults::PAGINATION
  end

  def tag_cloud_settings
    current_user&.tag_cloud_settings || SiteSettings::UserDefaults::TAG_CLOUD.merge(heatmap: false)
  end

  def renderer_settings
    current_user&.renderer_settings || SiteSettings::UserDefaults::RENDERER
  end

  def file_list_settings
    current_user&.file_list_settings || SiteSettings::UserDefaults::FILE_LIST
  end

  def problem_settings
    current_user&.problem_settings || Problem::DEFAULT_SEVERITIES
  end

  def random_password
    (SecureRandom.base64(32) + "!0aB").chars.shuffle.join
  end

  def server_indicator(object, full_address: false)
    actor = object.respond_to?(:federails_actor) ? object.federails_actor : object
    return if !SiteSettings.federation_enabled? || actor.local?
    link_to actor.profile_url, class: "link-primary link-underline-opacity-0 link-underline-opacity-100-hover" do
      safe_join([
        "⁂",
        full_address ? actor.at_address : actor.server
      ], " ")
    end
  end

  def oembed_params
    params.permit(:maxwidth, :maxheight)
  end

  def render_component_collection(component, param, collection, kwargs = {})
    safe_join(collection.map { |it| render component.new(**{param => it}.merge(kwargs)) }, " ")
  end

  def indexable_select_options(object)
    current = object.inherited_indexable? ? translate("application_helper.indexable_select_options.yes") : translate("application_helper.indexable_select_options.no")
    options_for_select(
      [
        [translate("application_helper.indexable_select_options.inherit", inherited: current), "inherit"],
        [translate("application_helper.indexable_select_options.always_no"), "no"],
        [translate("application_helper.indexable_select_options.always_yes"), "yes"]
      ],
      selected: object&.indexable || "inherit"
    )
  end

  def ai_indexable_select_options(object)
    current = object.inherited_ai_indexable? ? translate("application_helper.indexable_select_options.yes") : translate("application_helper.indexable_select_options.no")
    options_for_select(
      [
        [translate("application_helper.ai_indexable_select_options.inherit", inherited: current), "inherit"],
        [translate("application_helper.ai_indexable_select_options.always_no"), "no"],
        [translate("application_helper.ai_indexable_select_options.always_yes"), "yes"]
      ],
      selected: object&.ai_indexable || "inherit"
    )
  end
end
