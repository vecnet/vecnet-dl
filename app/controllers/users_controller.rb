# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class UsersController < ApplicationController
  prepend_before_filter :find_user, :except => [:index, :search, :notifications_number]
  before_filter :authenticate_user!, only: [:edit, :update, :follow, :unfollow, :toggle_trophy]
  before_filter :user_is_current_user, only: [:edit, :update, :toggle_trophy]
  def index
    sort_val = get_sort
    query = params[:uq].blank? ? nil : "%"+params[:uq].downcase+"%"
    if query.blank?
      @users = User.order(sort_val).page(params[:page]).per(10) if query.blank? 
    else
      @users = User.where("(login like lower(?) OR display_name like lower(?))",query,query).order(sort_val).page(params[:page]).per(10)
    end
  end

  # Display user profile
  def show

  end

  # Display form for users to edit their profile information
  def edit
    @user = current_user
  end

  # Process changes from profile form
  def update
    find_user.update_attributes(params[:user])
    unless @user.save
      redirect_to edit_user_path(find_user), alert: @user.errors.full_messages
      return
    end
    Sufia.queue.push(UserEditProfileEventJob.new(find_user.user_key))
    redirect_to user_path(@user.id), notice: "Your profile has been updated"
  end

  private
  def find_user
    @user ||= User.find(params[:id])
    redirect_to root_path, alert: "User '#{params[:id]}' does not exist" if @user.nil?
    @user
  end

  def get_sort
    sort = params[:sort].blank? ? "name" : params[:sort]
    sort_val = case sort
           when "name"  then "display_name"
           when "name desc"   then "display_name DESC"
           else sort
           end
    return sort_val
  end
end
