# -*- encoding : utf-8 -*-
class MediaEntriesController < ApplicationController

  before_filter do
    # TODO test; useful for will_paginate and forwarding links; refactor to application_controller?
    params.delete_if {|k,v| v.blank? }

    if [:edit_multiple, :update_multiple, :remove_multiple].include? request[:action].to_sym
      begin
        if !params[:media_set_id].blank?
          action = case request[:action].to_sym
            when :remove_multiple
              :edit
          end
          @media_set = MediaSet.accessible_by_user(current_user, action).find(params[:media_set_id])
        elsif !params[:media_entry_ids].blank?
          selected_ids = params[:media_entry_ids].split(",").map{|e| e.to_i }
          action = case request[:action].to_sym
            when :edit_multiple, :update_multiple
              :edit
            when :remove_multiple
              :view
          end
          @media_entries = MediaEntry.accessible_by_user(current_user, action).find(selected_ids)
        else
          flash[:error] = "Sie haben keine Medieneinträge ausgewählt."
          redirect_to :back
        end
      rescue
        not_authorized!
      end

    else

      @user = User.find(params[:user_id]) unless params[:user_id].blank?
      @context = MetaContext.find(params[:context_id]) unless params[:context_id].blank?
      @media_set = (@user? @user.media_sets : MediaSet).find(params[:media_set_id]) unless params[:media_set_id].blank? # TODO shallow
  
      unless (params[:media_entry_id] ||= params[:id] || params[:media_entry_ids]).blank?
        action = case request[:action].to_sym
          when :show, :map, :browse, :media_sets
            :view
          when :update, :edit_tms, :to_snapshot
            :edit
        end
  
        begin
          @media_entry =  if @media_set
                            @media_set.media_entries.accessible_by_user(current_user, action).find(params[:media_entry_id])
                          elsif @user
                            @user.media_entries.accessible_by_user(current_user, action).find(params[:media_entry_id])
                          # TODO if @user and @media_set ??
                          else
                            MediaResource.media_entries_or_media_entry_incompletes.accessible_by_user(current_user, action).find(params[:media_entry_id])
                          end
        rescue
          not_authorized!
        end
      end
    end

  end

#####################################################

  def show
    respond_to do |format|
      format.html
      format.xml { render :xml=> @media_entry.to_xml(:include => {:meta_data => {:include => :meta_key}} ) }
    end
  end
  
  def map
    meta_data = @media_entry.media_file.meta_data
    @lat = meta_data["GPS:GPSLatitude"]
    @lng = meta_data["GPS:GPSLongitude"]

    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def browse
    # TODO merge with index
    @viewable_ids = MediaEntry.accessible_by_user(current_user).pluck(:id)
  end
  
#####################################################

  def edit_tms
    not_authorized! and return unless current_user.groups.is_member?("Expert")
  end

  def to_snapshot
    not_authorized! and return unless current_user.groups.is_member?("Expert")
    @media_entry.to_snapshot(current_user)
    redirect_to @media_entry
  end

#####################################################

  ##
  # Manage parent media sets from a specific media entry.
  # 
  # @url [POST] /media_entries/media_sets?[arguments]
  # @url [DELETE] /media_entries/media_sets?[arguments]
  # 
  # @argument [parent_media_set_ids] array The ids of the parent media sets to remove/add
  # @argument [media_entry_ids] array The ids of the entries that have to be added to the sets given as "parent_media_set_ids"
  #
  # @example_request
  #   {"parent_media_set_ids": [1,2,3], "media_entry_ids": [5,6,7]}
  #
  # @request_field [Array] media_set_ids The ids of the parent media sets to remove/add  
  #
  # @example_response
  #   [{"id":407},{"id":406}]
  # 
  # @response_field [Integer] id The id of a removed or an added parent set 
  # 
  def media_sets(parent_media_set_ids = params[:parent_media_set_ids])
    parent_media_sets = MediaSet.accessible_by_user(current_user, :edit).where(:id => parent_media_set_ids.map(&:to_i))

    parent_media_sets.each do |media_set|
      if request.post?
        media_set.media_entries << @media_entry
      else
        media_set.media_entries.delete(@media_entry)
      end
    end
    
    respond_to do |format|
      format.json {
        render :partial => "media_resources/index", :formats => [:json], :handlers => [:rjson], :locals => {:media_resources => parent_media_sets}
      }
    end
  end

  # TODO refactor to KeywordsController#index
  def keywords
#old#
##select *, count(*) from keywords group by term_id;
##select *, count(*) from keywords where user_id = 159123 group by term_id;
##select *, count(*) from keywords where exists (select * from keywords as t2 where t2.term_id = keywords.term_id AND t2.user_id = 159123) group by term_id;

    # FIXME all fetch keywords associated to media_resources I can see ??   
    @all_keywords = Keyword.select("*, COUNT(*) AS q").group(:meta_term_id).order("q DESC")
    @my_keywords = Keyword.select("*, COUNT(*) AS q").where(:user_id => current_user).group(:meta_term_id).order("q DESC")
    
#old#
##SELECT t1.*, COUNT(*) AS q, t2.user_id AS u FROM `keywords` AS t1 LEFT JOIN keywords AS t2 ON t1.term_id = t2.term_id AND t2.user_id = 159123 GROUP BY t1.term_id ORDER BY q DESC;
#    @keywords = Keyword.select("keywords.*, COUNT(*) AS q, t2.user_id AS u").
#                joins("LEFT JOIN keywords AS t2 ON keywords.term_id = t2.term_id AND t2.user_id = #{current_user.id}").
#                group(:meta_term_id)

##SELECT *, COUNT(*) AS q, (SELECT user_id FROM keywords AS t2 WHERE t2.term_id = keywords.term_id AND t2.user_id = 159123 LIMIT 1) AS u FROM `keywords` GROUP BY term_id ORDER BY q DESC;
#    @keywords = Keyword.select("*, COUNT(*) AS q, (SELECT user_id FROM keywords AS t2 WHERE t2.term_id = keywords.term_id AND t2.user_id = #{current_user.id} LIMIT 1) AS u").
#                group(:meta_term_id).order("q DESC")
##SELECT *, COUNT(*) AS q, exists (SELECT * FROM keywords AS t2 WHERE t2.term_id = keywords.term_id AND t2.user_id = 159123) AS u FROM `keywords` GROUP BY term_id ORDER BY q DESC;
#    @keywords = Keyword.select("*, COUNT(*) AS q, exists (SELECT * FROM keywords AS t2 WHERE t2.term_id = keywords.term_id AND t2.user_id = #{current_user.id}) AS u").
#                group(:meta_term_id).order("q DESC")
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
#####################################################
# BATCH actions

  def remove_multiple
    @media_set.media_entries.delete(@media_entries)
    flash[:notice] = "Die Medieneinträge wurden aus dem Set gelöscht."
    redirect_to media_set_url(@media_set)
  end
  
  def edit_multiple
    labels = ["title", "author", "uploaded at", "uploaded by", "keywords", "copyright notice", "portrayed object dates"]
    # custom hash for jQuery json templates
    @info_to_json = @media_entries.map do |me|
      core_info = Hash.new
      labels.each do |label|
        core_info[label.gsub(' ', '_')] = ""
      end
      me.meta_data.get_for_labels(labels).each do |md|
        core_info[md.meta_key.label.gsub(' ', '_')] = md.to_s
      end
      me.attributes.merge!(core_info)
    end.to_json
  end
  
  def update_multiple
    @media_entries.each do |media_entry|
      if media_entry.update_attributes(params[:resource], current_user)
        flash[:notice] = "Die Änderungen wurden gespeichert." # TODO appending success message and resource reference (id, title)
      else
        flash[:error] = "Die Änderungen wurden nicht gespeichert." # TODO appending success message and resource reference (id, title)
      end
    end
    
    redirect_back_or_default(media_resources_path)
  end
  
end
