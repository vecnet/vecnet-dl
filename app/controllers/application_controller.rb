require 'CGI'
require 'time'
require 'pub_ticket'
require Curate::Engine.root.join('app/controllers/application_controller')
class ApplicationController < ActionController::Base

  before_filter :decode_user_if_pubtkt_present

  helper_method :current_user, :user_signed_in?, :user_login_url, :user_logout_url

  # If there is a valid pubtkt, create a user object
  # If there is not a valid pubtkt, destroy the user object
  # We don't raise any authentication errors here.
  def decode_user_if_pubtkt_present
    @current_user = nil
    ticket = cookies[:auth_pubtkt]
    if ticket.present?
      # cache pubticket? to reduce parsing and crypto checking
      logger.debug "Found Pub Ticket: #{ticket}"
      pt = ::PubTicket.new(CGI.unescape(ticket))
      if pt.signature_valid?(Rails.configuration.pubtkt_public_key)
        logger.debug "Pubtkt: Signature valid"
        if pt.check_correctness(request.ip, Time.now) == :correct
          logger.debug "Pubtkt: is correct"
          logger.debug "Pubtkt = #{pt.inspect}"
          @current_user = User.find_by_uid(pt.uid)
          if @current_user.nil?
            @current_user = User.new(uid: pt.uid, email: "#{pt.uid}@nd.edu")
            # just until the user table gets migrated
            @current_user.reset_password_token = pt.signature
            @current_user.save!
          end
          logger.debug "Current user: #{@current_user.inspect}"
          #@current_user.groups = pt.tokens.split(',')
        end
      end
    else
      logger.debug "No Pub Ticket"
    end
  end

  def current_user
    @current_user
  end

  def user_signed_in?
    current_user != nil
  end

  def user_login_url(back=nil)
    back = root_path unless back
    redirect_params = { back: back }
    "#{Rails.configuration.pubtkt_login_url}?#{redirect_params.to_query}"
  end

  alias_method :user_logout_url, :user_login_url
end
