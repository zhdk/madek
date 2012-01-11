# -*- encoding : utf-8 -*-
class Admin::MediaSetsController < Admin::AdminController
  
  before_filter :pre_load

  def index
    @sets = Media::Set.all
  end

  def new
    @set = Media::Set.new
    respond_to do |format|
      format.js
    end
  end

  def create
    type = params[:media_set].delete(:type)
    set = type.constantize.create(:user => current_user)
    set.update_attributes(params[:media_set])
    redirect_to admin_media_sets_path
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    if params[:individual_contexts] and @set.respond_to? :individual_contexts
      @set.individual_contexts = MetaContext.find(params[:individual_contexts])
    end
    
    @set.update_attributes(params[:media_set])
    
    unless params[:new_manager_user_id].blank?
      user = User.find(params[:new_manager_user_id])
      Permission.assign_manage_to(user, @set, !!params[:with_media_entries])
    end
    
    redirect_to admin_media_sets_path
  end

  def destroy
    @set.destroy if @set.media_entries.empty?
    redirect_to admin_media_sets_path
  end

#####################################################

  def featured
    @set = Media::Set.featured_set || Media::Set.new(:user => current_user)
    if request.post?
      if @set.new_record?
        @set.save
        @set.default_permission.set_actions({:view => true})
        Media::Set.featured_set = @set
      end
      @set.child_sets.delete_all
      @set.child_sets << Media::Set.find(params[:children]) unless params[:children].blank?
    end
  end

#####################################################

  private

  def pre_load
      params[:media_set_id] ||= params[:id]
      @set = Media::Set.find(params[:media_set_id]) unless params[:media_set_id].blank?
  end
  
end
