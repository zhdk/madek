# -*- encoding : utf-8 -*-
class UsersController < ApplicationController

  def index 
    query = params[:query]
    exclude_group_id = params[:exclude_group_id]
    users = Person.hacky_search(query).map(&:user).compact
    if exclude_group_id
      group = Group.find(exclude_group_id)
      users -= group.users
    end
    render json: view_context.json_for(users)
end

  def show
    # TODO refactor from ApplicationController#root
    redirect_to media_resources_path(:user_id => params[:id])
  end

  def keywords

  end
  
  def contrast_mode
    current_user.update_attributes! contrast_mode: params[:contrast_mode]
    redirect_to :back # TODO: check if always correct
  end

#####################################################

  def usage_terms
    @usage_term = UsageTerm.current    
  end

  def usage_terms_accept
    current_user.usage_terms_accepted!
    redirect_to root_path
  end

  def usage_terms_reject
    reset_session
    redirect_to root_path, flash: {error: "Das Akzeptieren der Nutzungsbedingungen ist Vorraussetzung für die Nutzung des Medienarchivs."}
  end

end
