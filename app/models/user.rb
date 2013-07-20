class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Connects this user object to Sufia behaviors.
  include Sufia::User

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  delegate :can?, :cannot?, :to => :ability

  Devise.add_module(:http_header_authenticatable,
                    :strategy => true,
                    #:controller => :sessions,
                    :model => 'devise/models/http_header_authenticatable')
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  # Setup accessible (or protected) attributes for your model
  #attr_accessible :email, :remember_me, :username#, :password
  attr_accessible :email, :username, :password, :password_confirmation, :display_name


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
    'vecnet_audituser'
  end

  def self.batchuser
    User.find_by_user_key(batchuser_key) || User.create!(Devise.authentication_keys.first => batchuser_key, password: Devise.friendly_token[0,20])
  end

  def self.batchuser_key
    'vecnet_batchuser@example.com'
  end

  def agree_to_terms_of_service!
    update_column(:agreed_to_terms_of_service, true)
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
