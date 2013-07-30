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
      pt = ::PubTicket.new(ticket)  # Rails has already URL unescaped `ticket`
      if pt.signature_valid?(Rails.configuration.pubtkt_public_key)
        logger.debug "Pubtkt: Signature valid"
        if pt.ticket_valid?(request.remote_ip, Time.now)
          @current_user = User.find_or_create_from_pubtkt(pt)
        end
      end
    end
  end

  # provide the "devise API" for 'user'

  def current_user
    @current_user
  end

  def user_signed_in?
    current_user != nil
  end

  def authenticate_user!(opts={})
    throw(:warden, opts) unless user_signed_in?
  end

  def user_session
    current_user && session
  end

  # path helpers, since pubtkt passes the return url as a parameter

  def user_login_url(back=nil)
    back = root_path unless back
    redirect_params = { back: back }
    "#{Rails.configuration.pubtkt_login_url}?#{redirect_params.to_query}"
  end

  alias_method :user_logout_url, :user_login_url
end
