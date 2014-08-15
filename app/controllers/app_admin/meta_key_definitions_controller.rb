class AppAdmin::MetaKeyDefinitionsController < AppAdmin::BaseController
  before_action :find_context

  def edit
    @meta_key_definition = @context.meta_key_definitions.find(params[:id])
  end

  def update
    @meta_key_definition = @context.meta_key_definitions.find(params[:id])
    @meta_key_definition.update(meta_key_definition_params)

    redirect_to edit_app_admin_context_url(@context), flash: {success: 'The meta key definition has been updated'}
  rescue => e
    redirect_to edit_app_admin_context_url(@context), flash: {error: e.message}
  end

  def new
    @meta_key_definition = MetaKeyDefinition.new
    @meta_key_definition.context = @context
  end

  def create
    @context.meta_key_definitions << MetaKeyDefinition.create(meta_key_definition_params)

    redirect_to edit_app_admin_context_url(@context), flash: {success: "A new meta key definition has been created"}
  rescue => e
    redirect_to edit_app_admin_context_url(@context), flash: {error: e.message}
  end

  def destroy
    find_meta_key_definition
    @context.meta_key_definitions.delete(@meta_key_definition)

    redirect_to edit_app_admin_context_url(@context), flash: {
      success: "The meta key definition has been removed from the <strong>#{@context.id}</strong> meta context".html_safe
    }
  rescue => e
    redirect_to edit_app_admin_context_url(@context), flash: {error: e.message}
  end

  def move_up
    find_context
    find_meta_key_definition

    @meta_key_definition.move_up

    redirect_to edit_app_admin_context_url(@context), flash: {
      success: "The position of meta key definition has been updated."
    }
  rescue => e
    redirect_to edit_app_admin_context_url(@context), flash: {
      error: e.to_s
    }
  end

  def move_down
    find_context
    find_meta_key_definition

    @meta_key_definition.move_down

    redirect_to edit_app_admin_context_url(@context), flash: {
      success: "The position of meta key definition has been updated."
    }
  rescue => e
    redirect_to edit_app_admin_context_url(@context), flash: {
      error: e.to_s
    }
  end

  private

  def meta_key_definition_params
    params.require(:meta_key_definition).permit!
  end

  def find_context
    @context = Context.find(params[:context_id])
  end

  def find_meta_key_definition
    @meta_key_definition = MetaKeyDefinition.find(params[:id])
  end
end
