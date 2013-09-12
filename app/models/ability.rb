class Ability
  include Hydra::Ability
  def custom_permissions
    if current_user.admin?
      can [:edit, :update, :destroy], String
      can [:edit, :update, :destroy], ActiveFedora::Base
      can :edit, SolrDocument
      can :read, String
      can :read, ActiveFedora::Base
      can :read, SolrDocument
      can :manage, :all
    else
      super
    end
  end
end