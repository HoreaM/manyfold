module CaberObject
  extend ActiveSupport::Concern
  include Caber::Object

  included do
    can_grant_permissions_to User
    can_grant_permissions_to Role

    attr_writer :owner
    attr_writer :permission_preset
    accepts_nested_attributes_for :caber_relations, reject_if: :all_blank, allow_destroy: true

    before_validation :ensure_permission_preset_precedence

    before_create :set_default_permission_preset
    after_commit :set_permissions_from_preset
    after_create_commit :set_owner

    before_update -> { @was_private = !public? }
  end

  def public?
    return false unless caber_ready?
    Pundit::PolicyFinder.new(self.class).policy.new(nil, self).show?
  end

  def private?
    caber_relations.where(subject_type: "Role").or(caber_relations.where(subject: nil)).none?
  end

  def just_became_public?
    public? && @was_private
  end

  def set_default_permission_preset
    @permission_preset ||= SiteSettings.default_viewer_role
  end

  def set_permissions_from_preset
    case @permission_preset&.to_sym
    when :public
      grant_permission_to("view", nil)
      revoke_permission("view", Role.find_or_create_by(name: "member"))
    when :member
      revoke_all_permissions(nil)
      grant_permission_to("view", Role.find_or_create_by(name: "member"))
    when :private
      Caber::Relation.where(object: self, permission: ["preview", "view", "edit"]).destroy_all # rubocop:disable Pundit/UsePolicyScope
    end
    # Clear attribute so we don't pollute later operations on the same object
    @permission_preset = nil
  end

  def set_owner
    # Set owner if not already set
    if permitted_users.with_permission("own").empty?
      o = @owner || SiteSettings.default_user
      grant_permission_to("own", o) if o
    end
  end

  def will_be_public?
    return false unless caber_ready?
    @permission_preset == "public" || caber_relations.find { |it| it.subject.nil? }
  end

  def matching_permission_preset
    if caber_relations.count == 1 && caber_relations.where(permission: "own").one?
      "private"
    elsif caber_relations.count == 2 && caber_relations.where(permission: "view", subject: Role.find_by!(name: "member")).one?
      "member"
    elsif caber_relations.count == 2 && caber_relations.where(permission: "view", subject: nil).one?
      "public"
    else
      ""
    end
  end

  private

  def caber_ready?
    ActiveRecord::Base.connection.data_source_exists? "caber_relations"
  end

  def ensure_permission_preset_precedence
    self.caber_relations_attributes = [] if @permission_preset.present?
  end
end
