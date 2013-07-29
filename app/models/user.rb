class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Connects this user object to Sufia behaviors.
  include Sufia::User

  delegate :can?, :cannot?, :to => :ability

  # Setup accessible (or protected) attributes for your model
  #attr_accessible :email, :remember_me, :username#, :password
  attr_accessible :email, :username, :password, :password_confirmation, :display_name
  attr_accessible :uid

  def self.find_by_uid(uid)
    User.where(uid: uid).limit(1).first
  end

  #attr_accessor :password

  #def password_required?; false; end
  #def email_required?; false; end

  def display_name
    username
  end

  def self.audituser
    User.find_by_user_key(audituser_key) || User.create!(Devise.authentication_keys.first => audituser_key)
  end

  def self.audituser_key
    'curate_nd_audituser'
  end

  def self.batchuser
    User.find_by_user_key(batchuser_key) || User.create!(Devise.authentication_keys.first => batchuser_key)
  end

  def self.batchuser_key
    'curate_nd_batchuser'
  end

  def agree_to_terms_of_service!
    update_column(:agreed_to_terms_of_service, true)
  end

  # Override Hydra methods that assume Devise is present
  def user_key
    uid
  end

  def self.find_by_user_key(key)
    find_by_uid(key)
  end


  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  #delegating groups to roles since there is no difference between roles and groups yet
  def groups
    roles
  end

  def roles
    #Need to remove registered from roles since it is not a valid user role
    RoleMapper.roles(self)- ["registered"]
  end

  def admin?
    self.admin
  end

  def admin!
    update_column(:admin, true)
  end
end
