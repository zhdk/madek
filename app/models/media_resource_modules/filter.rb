# -*- encoding : utf-8 -*-

module MediaResourceModules
  module Filter

    KEYS = [ :accessible_action, :collection_id, :favorites, :group_id, :ids,
             :media_file,:media_files, :media_set_id, :meta_data, :not_by_user_id,
             :permissions, :public, :search, :type, :user_id,
             :query, :context_ids, :media_resources, :permission_presets ] 

    def self.included(base)
      base.class_eval do
        extend(ClassMethods)
      end
    end

    module ClassMethods
      def get_filter_params params
        params.select do |k,v| 
          KEYS.include?(k.to_sym) 
        end.delete_if {|k,v| v.blank?}.deep_symbolize_keys
      end

      # returns a chainable collection of media_resources
      # when current_user argument is not provided, the permissions are not considered
      def filter(current_user, filter_opts)
        filter_opts = filter_opts.delete_if {|k,v| v.blank?}.deep_symbolize_keys
        raise "invalid option" unless filter_opts.is_a?(Hash) 

        ############################################################
        filter_opts[:ids] = by_collection(filter_opts[:collection_id]) if current_user and filter_opts[:collection_id]
        ############################################################
        
        resources = if current_user and filter_opts[:favorites] == "true"
          current_user.favorites
        elsif filter_opts[:media_set_id]
          # hacketihack media_set_id kann auch zu einem FilterSet gehören
          MediaResource.where(type: ['MediaSet','FilterSet']).find(filter_opts[:media_set_id])\
            .included_resources_accessible_by_user(current_user,:view)
        else
          self
        end

        resources = case filter_opts[:type]
          when "sets"
            resources.where(type: ["MediaSet","FilterSet"])
          when "media_sets"
            resources.media_sets
          when "media_entries"
            resources.media_entries
          when "media_entry_incompletes"
            resources.where(:type => "MediaEntryIncomplete")
          else
            types = ["MediaEntry", "MediaSet", "FilterSet"]
            types << "MediaEntryIncomplete" if filter_opts[:ids]
            resources.where(:type => types)
        end

        resources = resources.accessible_by_user(current_user, (filter_opts[:accessible_action] or :view)) if current_user

        ############################################################
      
        if media_files_filter = filter_opts[:media_files]
          media_files_filter.each do |column,h|
            value =h[:ids].first # we can simplify here, since there can be only one extension/type
            resources = resources.media_entries. # only media entries can have media file
              joins(:media_file).
              where(:media_files => {column => value})
          end
        end

        ############################################################

        if filter_opts[:ids]
          existing_ids = Array(filter_opts[:ids]).map{|id| MediaResource.some_id_to_uuid(id)}.compact
          resources = resources.where(id: existing_ids)
        end

        resources = resources.text_search(filter_opts[:search]) unless filter_opts[:search].blank?

        ############################################################
        
        resources = resources.accessible_by_group(filter_opts[:group_id],:view) if filter_opts[:group_id]

        resources = resources.where(:user_id => filter_opts[:user_id]) if filter_opts[:user_id]

        # FIXME use presets and :manage permission
        resources = resources.not_by_user(filter_opts[:not_by_user_id]) if filter_opts[:not_by_user_id]

        resources = resources.filter_public(filter_opts[:public]) if filter_opts[:public]

        resources = resources.filter_permission_presets(resources, filter_opts[:permission_presets]) if filter_opts[:permission_presets]

        resources = resources.filter_permissions(resources,current_user, filter_opts[:permissions]) if current_user and filter_opts[:permissions]

        ############################################################

        resources = resources.filter_media_resources(resources,filter_opts[:media_resources]) if filter_opts[:media_resources]

        resources = resources.filter_meta_data(resources, filter_opts[:meta_data]) if filter_opts[:meta_data]

        resources = resources.filter_media_file(filter_opts[:media_file]) if filter_opts[:media_file] and filter_opts[:media_file][:content_type]

        resources = resources.filter_uploaded_by(filter_opts[:uploader_id]) if filter_opts[:uploader_id]

        resources = resources.filter_contexts(resources,filter_opts[:context_ids]) if filter_opts[:context_ids]

        resources
      end


      def filter_public(filter)
        case filter
          when "true"
            where(:view => true)
          when "false"
            where(:view => false)
        end
      end

      def filter_permission_presets(resources, filter)
        id = filter[:ids]
        view = filter[:category][:view] || false
        download = filter[:category][:download] || false
        edit = filter[:category][:edit] || false
        manage = filter[:category][:manage] || false
        resources.accessible_by_group_with_permissions(id, [view, download, edit, manage])
      end

      def filter_permissions(resources, current_user, filter)
        filter.each_pair do |k,v|
          v[:ids].each do |id|
            resources = case k
              when :owner
                resources.where(:user_id => id)
              when :group
                resources.accessible_by_group(id,:view)
              when :scope
                case id.to_sym
                  when :mine
                    resources.where(:user_id => current_user)
                  when :entrusted
                    resources.entrusted_to_user(current_user,:view)
                  when :public
                    resources.filter_public("true")
                end
            end
          end
        end
        resources
      end
      
      def filter_media_resources(resources, filter)
        filter.each_pair do |k,v|
          v[:ids].each do |id|
            case id
              when "MediaEntry"
                resources = resources.where("media_resources.id IN (#{resources.where(:type => "MediaEntry").select("media_resources.id").to_sql})")
              when "MediaSet"
                resources = resources.where("media_resources.id IN (#{resources.where(:type => "MediaSet").select("media_resources.id").to_sql})")
              when "FilterSet"
                resources = resources.where("media_resources.id IN (#{resources.where(:type => "FilterSet").select("media_resources.id").to_sql})")
            end
          end
        end
        resources
      end

      def filter_meta_data(resources, filter)
        filter.each_pair do |k,v|
          # this is AND implementation
          v[:ids].each do |id|
            # OPTIMIZE resource.joins(etc...) directly intersecting multiple criteria doesn't work, then we use subqueries
            # FIXME switch based on the meta_key.meta_datum_object_type 
            sub = case k
              when :keywords
                s = unscoped.joins(:meta_data).
                         joins("INNER JOIN keywords ON keywords.meta_datum_id = meta_data.id")
                s = s.where(:keywords => {:keyword_term_id => id}) unless id == "any"
                s
              when :"institutional affiliation"
                s = unscoped.joins(:meta_data).
                         joins("INNER JOIN meta_data_institutional_groups ON meta_data_institutional_groups.meta_datum_id = meta_data.id")
                s = s.where(:meta_data_institutional_groups => {:institutional_group_id => id}) unless id == "any"
                s
              when :"uploaded by"
                s = unscoped.
                  joins(:meta_data => :meta_key).
                  joins("INNER JOIN meta_data_users ON meta_data.id = meta_data_users.meta_datum_id").
                  where(:meta_keys => {id: "uploaded by"},
                        :meta_data_users => {:user_id => id})
                s
              else
                # OPTIMIZE accept also directly meta_key_id ?? 
                s = unscoped.joins(:meta_data => :meta_key).
                         joins("INNER JOIN meta_data_meta_terms ON meta_data_meta_terms.meta_datum_id = meta_data.id").
                         where(:meta_keys => {id: k, :meta_datum_object_type => "MetaDatumMetaTerms"})
                s = s.where(:meta_data_meta_terms => {:meta_term_id => id}) unless id == "any"
                s
            end
            # NOTE this doesn't work because is overwriting the statements:
            # resources = resources.where(:id => sub)
            resources = resources.where("media_resources.id IN (#{sub.select("media_resources.id").to_sql})")
          end
        end
        resources
      end

      def filter_media_file(options)
        sql = media_entries.joins("RIGHT JOIN media_files ON media_resources.id = media_files.media_entry_id")
      
        options[:content_type].each do |x|
          sql = sql.where("media_files.content_type ilike ?", "%#{x}%")
        end if options[:content_type]
        
        [:width, :height].each do |x|
          if options[x] and not options[x][:value].blank?
            operator = case options[x][:operator]
              when "gt"
                ">"
              when "lt"
                "<"
              else
                "="
            end
            sql = sql.where("media_files.#{x} #{operator} ?", options[x][:value])
          end
        end
    
        unless options[:orientation].blank?
          operator = if options[:orientation].size == 2
            "="
          else
            case options[:orientation].to_i
              when 0
                "<"
              when 1
                ">"
            end
          end
          sql = sql.where("media_files.height #{operator} media_files.width")
        end
    
        sql    
      end

      def filter_contexts(resources,names)
        sub = unscoped.joins(:meta_data => {:meta_key => :meta_key_definitions})
                      .where(:meta_key_definitions => {:context_id => names})
                      .joins("INNER JOIN media_resource_arcs ON media_resource_arcs.child_id = media_resources.id")
                      .joins("INNER JOIN media_sets_contexts ON media_sets_contexts.media_set_id = media_resource_arcs.parent_id")
                      .where(:media_sets_contexts => {:context_id => names})
                      .uniq
        resources.where(:id => sub)
      end
      
    end

  end
end



