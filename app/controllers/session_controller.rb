class SessionController < ApplicationController
  attr_accessor :code
  skip_before_filter :set_foursquare_user, :only => [:error]

  def callback
    code = params[:code]
    unless code
      redirect_to :action => :new
      return
    end
    if (params[:error] == "access_denied")
      redirect_to :action => :new
      return
    end
    if code
      # set up new oauth2 client, get token
      begin
        token  = oauth_client.auth_code.get_token(code, :redirect_uri => Settings.callback_url)
        logger.error "Token: #{token.inspect}"
        cookies.permanent.signed[:access_token] = token.token
      rescue OAuth2::Error => e
        flash[:notice] = "Login Failure: " + e.message
      end
    end

    logger.error "Confirm Token: #{cookies.signed[:access_token]}"
    # Now that we have an access token, let's see if we have a user for this person:
    foursquare = Foursquare2::Client.new(:oauth_token => cookies.signed[:access_token], :connection_middleware => [Faraday::Response::Logger, FaradayMiddleware::Instrumentation], :api_version => '20140107')

    foursquare_user = foursquare.user('self')
    user = User.find_by_uid(foursquare_user.id)

    if user
      @current_user = user
      # TODO: token will be going byebye soon
      @current_user[:token] = cookies[:access_token]
      # let's clear their user cache, it seems to be causing problems:
      @current_user.user_cache = nil
      @current_user.cached_at = nil
      @current_user.save
    else
      @current_user = User.create(
         :uid => foursquare_user.id,
         :name => "#{foursquare_user.firstName} #{foursquare_user.lastName}".strip,
         :enabled => true)
    end

    redirect_to :controller => :explorer, :action => :explore
  end

  def new
    if !@current_user && cookies.signed[:access_token]
      # Now that we have an access token, let's see if we have a user for this person:
      foursquare = Foursquare2::Client.new(:oauth_token => cookies.signed[:access_token], :connection_middleware => [Faraday::Response::Logger, FaradayMiddleware::Instrumentation], :api_version => '20140107')

      foursquare_user = foursquare.user('self')
      @current_user = User.find_by_uid(foursquare_user.id)
    end

    if @current_user
      redirect_to :controller => :explorer, :action => :explore
      return
    end

    @authorize_url = oauth_client.auth_code.authorize_url(:redirect_uri => Settings.callback_url)
  end

  def not_allowed
  end

  def error
  end

  def logout
    cookies.signed[:access_token] = nil
    redirect_to :action => :new
  end

  private

  def oauth_client
    client = OAuth2::Client.new(
        Settings.app_id,
        Settings.app_secret,
        :authorize_url => "/oauth2/authorize",
        :token_url => "/oauth2/access_token",
        :site => 'https://foursquare.com')
  end

end
