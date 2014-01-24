#require Curate::Engine.root.join('app/controllers/application_controller')
class ApplicationController < ActionController::Base

  include Blacklight::Controller
  include CurateController

  before_filter :decode_user_if_pubtkt_present

  self.theme = 'vecnet'

  layout 'hydra-head'

  protect_from_forgery

  def show_action_bar?
    true
  end
  helper_method :show_action_bar?

  def show_breadcrumbs?
    false
  end
  helper_method :show_breadcrumbs?

  def show_site_search?
    true
  end
  helper_method :show_site_search?

  helper_method :current_user, :user_signed_in?, :user_login_url, :user_logout_url

  def decode_user_if_pubtkt_present
    # use authenticate instead of authenticate! since we
    # do not raise an error if there is a problem with the pubtkt.
    # in that case we make the current user nil
    request.env['warden'].authenticate(:pubtkt)
    @current_user = request.env['warden'].user.nil? ? nil : request.env['warden'].user.uid
  end

  # provide the "devise API" for 'user'

  def current_user
    return User.find_by_uid(@current_user) unless @current_user.nil?
    nil
  end

  def user_signed_in?
    current_user != nil
  end

  def authenticate_user!(opts={})
    throw(:warden, opts) unless user_signed_in?
  end

  def user_session
    current_user.uid && session
  end

  # path helpers, since pubtkt passes the return url as a parameter

  def user_login_url(back=nil)
    back = root_path unless back
    redirect_params = { back: back }
    #logger.debug("######User login url: #{Rails.configuration.inspect}, Rails Config class:#{Rails.configuration.class}######")
    if Rails.configuration.respond_to?(:pubtkt_login_url)
    #  logger.debug "#######returns #{Rails.configuration.pubtkt_login_url}#######"
      return Rails.configuration.pubtkt_login_url
    end
    nil
  end

  def user_logout_url
    if Rails.configuration.respond_to?(:pubtkt_logout_url)
      return Rails.configuration.pubtkt_logout_url
    end
    nil
  end

  protected
  def agreed_to_terms_of_service!
    return false unless current_user
    return current_user
  end
end
