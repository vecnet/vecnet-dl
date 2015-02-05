class UsersController < ApplicationController
  prepend_before_filter :find_user, :except => [:index, :search, :notifications_number]
  before_filter :authenticate_user!, only: [:edit, :update]

  with_themed_layout '1_column'

  def index
    sort_val = get_sort
    query = params[:uq].blank? ? nil : "%"+params[:uq].downcase+"%"
    if query.blank?
      @users = User.order(sort_val).page(params[:page]).per(10) if query.blank? 
    else
      @users = User.where("(uid like lower(?) OR username like lower(?))",query,query).order(sort_val).page(params[:page]).per(10)
    end
    logger.debug("Users are: #{@users.inspect}")
    hits=[]
    @users.each do |user|
      hits << {:uri => user.uid, :label => user.uid}
    end
    logger.debug("Hit are: #{hits.inspect}")
    render :json=>hits
  end

  # Display user profile
  def show
    if @user.respond_to? :profile_events
      @events = @user.profile_events(100)
    else
      @events = []
    end

  end

  # Display form for users to edit their profile information
  def edit
    @user = current_user
  end

  # Process changes from profile form
  def update
    find_user.update_attributes(params[:user])
    unless @user.save
      redirect_to edit_profile_path(@user), alert: @user.errors.full_messages
      return
    end
    Sufia.queue.push(UserEditProfileEventJob.new(find_user.user_key))
    redirect_to profile_path(@user), notice: "Your profile has been updated"
  end

  private
  def find_user
    @user = User.from_url_component(params[:uid])
    redirect_to root_path, alert: "User '#{params[:uid]}' does not exist" if @user.nil?
    @user
  end

  def get_sort
    sort = params[:sort].blank? ? "name" : params[:sort]
    sort_val = case sort
           when "name"  then "username"
           when "name desc"   then "username DESC"
           else sort
           end
    return sort_val
  end
end
