module FederailsCommon
  extend ActiveSupport::Concern
  include Federails::ActorEntity

  def actor
    act = Federails::Actor.find_by(entity: self)
    if act.nil?
      act = create_actor
      reload
    end
    act
  end
end
