# -*- encoding : utf-8 -*-
#

class ApplicationController < ActionController::Base
  #FE# before_filter { headers['Access-Control-Allow-Origin'] = '*' }

  ################
  # Error Classes like <http://www.ruby-doc.org/core-2.1.2/Exception.html>
  
  class Error < StandardError # Generic App Error (500)
  end
  rescue_from Error, with: :error_application

  class UserUnauthorizedError < Error # User has not authorized (401 Unauthorized)
  end
  rescue_from UserUnauthorizedError, with: :error_user_unauthorized
  
  class UserForbiddenError < Error # User has insufficent right (403 Forbidden)
  end
  rescue_from UserForbiddenError, with: :error_user_forbidden

  class UnprocessableEntityError < Error # Unprocessable entity(422)
  end
  rescue_from UnprocessableEntityError, with: :error_unprocessable_entity

  class NotAllowedError < Error # Not allowed(405)
  end
  rescue_from NotAllowedError, with: :error_not_allowed

  ################
  
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  unless Rails.env.development?
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  end

  def record_not_found exception
    render "not_found",  :status => :not_found, locals: {exception: exception}
  end



##############################################
# Authentication


  before_filter :load_app_settings
  before_filter :set_gettext_locale, :login_required, :except => [:login, :login_successful, :logout, :login_and_return_here] # TODO :help

  helper_method :current_user, :logged_in? 

  def logged_in?
    !!current_user
  end

  def current_user
    @current_user ||= login_from_session
  end


########################################################

  def load_app_settings
    @app_settings = AppSettings.first
  end

########################################################
# Admin Authentication 

  def authenticate_admin_user!
    unless current_user and current_user.is_admin?
      flash[:error] = "Sie sind kein Administrator."
      redirect_to root_path
    else
      true
    end
  end


  def set_gettext_locale
    locale_symbol = "de_CH".to_sym
    if params[:locale]
      session[:locale] = params[:locale]
      locale_symbol = params[:locale].to_sym
    end
    if session[:locale]
      locale_symbol = session[:locale].to_sym
    end
    I18n.locale = locale_symbol

    if Rails.env.development?
      FastGettext.reload! 
      Po2json.create 
    end
  end

##############################################

  def root
    if logged_in? and not current_user.is_guest?
      if @already_redirected
        # do nothing
      elsif session[:return_to]
        redirect_back_or_default('/')
      else
        flash.keep
        redirect_to my_dashboard_path
      end
    else
      @teaser_set = MediaSet.find @app_settings.teaser_set_id
      @teaser_set_included_resources = @teaser_set.child_media_resources.accessible_by_user(current_user,:view).shuffle if @teaser_set
      @featured_set = MediaSet.find @app_settings.featured_set_id
      @featured_set_children = @featured_set.child_media_resources.accessible_by_user(current_user,:view).ordered_by(:updated_at).limit(6) if @featured_set
      @catalog_set = MediaSet.find @app_settings.catalog_set_id 
      @catalog_set_categories = @catalog_set.categories.accessible_by_user(current_user,:view).limit(3) if @catalog_set
      @latest_media_entries = MediaResource.media_entries.accessible_by_user(current_user,:view).ordered_by(:created_at).limit(12)
    end
  end

  def help
  end

  def login_and_return_here
    store_location URI::parse(request.referrer).request_uri
    redirect_to login_path
  end

##############################################

  private

  ################ error handling: ################
  
  # TODO: redirect vs. status code (non-JSON) – how to correctly?

  def error_application    # handles 'Error'
    msg = "Entschuldigung, ein allgemeiner Fehler ist aufgetreten." 
    respond_to do |format|
      format.html { flash[:error] = msg ; redirect_back_or_root }
      format.json { render :json => {error: msg}, status: 500}
    end
  end
  
  def error_user_unauthorized # handles 'UserUnauthorizedError'
    store_location
    msg = "Bitte melden Sie sich an." 
    respond_to do |format|
      format.html { flash[:error] = msg ; redirect_back_or_root }
      format.json { render :json => {error: msg}, status: :forbidden}
    end
  end
  
  def error_user_forbidden # handles 'UserForbiddenError'
    msg = "Sie haben nicht die notwendige Zugriffsberechtigung." 
    respond_to do |format|
      format.html { flash[:error] = msg ; redirect_back_or_root }
      format.json { render :json => {error: msg}, status: :not_authorized}
    end
  end

  def error_unprocessable_entity # handles 'UnprocessableEntityError'
    msg = "Unprocessable entity error message." 
    respond_to do |format|
      format.html { flash[:error] = msg ; redirect_back_or_root }
      format.json { render :json => {error: msg}, status: :unprocessable_entity}
    end
  end

  def error_not_allowed # handles 'NotAllowedError'
    msg = "Not allowed error message." 
    respond_to do |format|
      format.html { flash[:error] = msg ; redirect_back_or_root }
      format.json { render :json => {error: msg}, status: :not_allowed}
    end
  end
  
  ################ other private methods: ################

  def login_required
    unless logged_in?
      store_location
      raise UserUnauthorizedError
    end
  end

  def current_user=(new_user)
    session[:user_id] = new_user ? new_user.id : nil
    @current_user = new_user || false
  end

  def login_from_session
    user = nil

    if session[:user_id]


      begin
        self.current_user = user = User.find_by_id(session[:user_id])
      rescue Exception => e
        reset_session
        Rails.logger.error e
      end

      if (not (expires_at= session[:expires_at])) or (expires_at < Time.now)
        reset_session
        current_user = user = nil
      end

      # expire the session if the pw has been reset
      # see also SessionsController/sign_in
      if (not user) or (not (pw_sig= session[:pw_sig])) \
          or (pw_sig != Digest::SHA1.base64digest(user.password_digest))
        reset_session
        current_user = user = nil
      end

      return nil unless user

      self.current_user.act_as_uberadmin = session[:act_as_uberadmin]
      
      # TODO: contrast_mode: cookie to session bool

      # request format can be nil!
      if not (request[:controller] == "media_resources" and request[:action] == "image") and (request.format and request.format.to_sym != :json)
        # sorry for the mess, i just stacked on top of the pile! o_O
        # don't run this check when user decides on the usage_terms
        unless request[:controller] == "users" and %w(usage_terms_reject usage_terms_accept).include? request[:action]
          check_usage_terms_accepted
        end
      end

    elsif request.format.to_sym == :json or
          (request[:controller] == "media_resources" and request[:action] == "image") or 
          (request[:controller] == "media_resources" and request[:action] == "show") or
          (request[:controller] == "media_resources" and request[:action] == "index") or
          (request[:controller] == "media_resources" and request[:action] == "browse") or
          (request[:controller] == "explore") or 
          (request[:controller] == "download") or 
          (request[:controller] == "application" and request[:action] == "root") or 
          (request[:controller] == "media_entries" and request[:action] == "show") or
          (request[:controller] == "media_entries" and request[:action] == "parents") or
          (request[:controller] == "media_entries" and request[:action] == "relations") or
          (request[:controller] == "media_entries" and request[:action] == "context_group") or
          (request[:controller] == "media_entries" and request[:action] == "more_data") or
          (request[:controller] == "custom_urls" and request[:action] == "index") or
          (request[:controller] == "media_sets" and request[:action] == "show") or 
          (request[:controller] == "media_sets" and request[:action] == "parents") or
          (request[:controller] == "media_sets" and request[:action] == "relations") or
          (request[:controller] == "media_sets" and request[:action] == "vocabulary") or
          (request[:controller] == "filter_sets" and request[:action] == "show") or
          (request[:controller] == "keywords" and request[:action] == "index") or
          (request[:controller] == "previews" and request[:action] == "show") or 
          (request[:controller] == "contexts") or
          (request[:controller] == "search")
      @current_user = user = User.new

    end
    user
  end

  def check_usage_terms_accepted
    return if request[:action].to_sym == :usage_terms # OPTIMIZE
    unless current_user.usage_terms_accepted?
      redirect_to usage_terms_user_path(current_user)
      @already_redirected = true # OPTIMIZE prevent DoubleRenderError
    end
  end

  def store_location(path = nil)
    session[:return_to] = path ? path : request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
  
  def redirect_back_or_root
    unless (request.env["HTTP_REFERER"].blank?) or (request.env["HTTP_REFERER"] != request.env["REQUEST_URI"])
      redirect_to :back
    else
      redirect_to root_url # _url not_path so it also works wrt http(s)
    end
  end

  def do_not_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

end
