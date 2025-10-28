# frozen_string_literal: true

class Components::LinkList < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  register_value_helper :policy

  def initialize(links:, icons: true)
    @links = links
    @icons = icons
  end

  def view_template
    return if @links.empty?
    ul class: "list-unstyled" do
      @links.each do |link|
        if link.valid?
          li do
            Icon(icon: "link-45deg") if @icons
            whitespace
            link_to t("sites.%{site}" % {site: link.site}, default: "%{site}" % {site: link.site}), link.url, rel: "noreferrer"
            if link.deserializer.present? && policy(link.linkable).sync?
              whitespace
              link_to({action: "sync", id: link.linkable, link: link.id}, {method: :post}) do
                Icon(icon: "arrow-repeat", label: t("components.link_list.sync"))
              end
              Icon(icon: "exclamation-triangle-fill") if link.problems.exists?
            end
          end
        end
      end
    end
  end
end
