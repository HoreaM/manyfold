module DefaultViewPermissions
  extend ActiveSupport::Concern

  included do
    after_create :assign_default_view_permissions
  end

  def assign_default_view_permissions
    # Grant local view access by default
    grant_permission_to("viewer", Role.find_or_create_by(name: :viewer))
    # Set default owner
    owner = SiteSettings.default_user
    grant_permission_to("owner", owner) if owner
  end
end
