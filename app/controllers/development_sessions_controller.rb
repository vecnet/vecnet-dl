class DevelopmentSessionsController < ApplicationController

  def new
  end

  def create
    private_key = false
    if private_key
      pt = PubTicket.new('')
      pt.uid = params[:uid]
      pt.clientip = params[:ip]
      pt.valid_until = params[:validuntil]
      pt.tokens = params[:tokens]
      pt.generate_signature( private_key )
      cookies[:auth_pubtkt] = CGI.escape(pt.ticket)
      redirect_to params[:back], :notice => "Logged in!"
    else
      flash.now.alert = "Private Key not set!"
      render "new"
    end
  end

  def destroy
    cookies[:auth_pubtkt] = nil
    redirect_to root_url, :notice => "Logged out!"
  end
end
