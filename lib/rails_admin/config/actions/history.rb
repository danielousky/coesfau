# frozen_string_literal: true
require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class HistoryIndex < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          %i[get post]
        end

        register_instance_option :authorization_key do
          :history
        end

        register_instance_option :route_fragment do
          'history'
        end        


        register_instance_option :controller do
          proc do
            @page_name = t("admin.actions.history_index.menu")
            
            # Get the user parameter if provided
            # Rails.logger.debug "  params: <#{params}>  ".center(1000, '@')
            # @user_id = params[:user_id]
            
            
            @model = params[:model_name] if params[:model_name]

            # Find the user if user_id is provided
            # @user = @user_id.present? ? User.find(@user_id) : nil
            
            @general_history = false
            
            # Get all users for the dropdown
            
            # Get versions based on user filter
            if params[:model_name]
              # Get versions where this user is the whodunnit (actions performed by user)
              #PaperTrail::Version.where(whodunnit: @user.id.to_s)
              
              # Get versions where this user is the subject (actions performed on user)
              model_as_subject = PaperTrail::Version.where(item_type: params[:model_name].camelize).order('created_at DESC')
              
              # Combine both sets of versions
              # @versions = model_as_subject (model_actions + model_as_subject).uniq.sort_by(&:created_at).reverse
              @versions = PaperTrail::Version.where(item_type: params[:model_name].camelize).order('created_at DESC')
            else
              # If no user selected, show all versions
              @general_history = true
              @versions = PaperTrail::Version.order('created_at DESC')
            end
            
            # Pagination
            @versions = Kaminari.paginate_array(@versions) if !@general_history
            @versions = @versions.page(params[:page] || 1).per(20)
            
            render @action.template_name
          end
        end

        register_instance_option :template_name do
          :history
        end
        
        register_instance_option :link_icon do
          'icon-book'
        end

        register_instance_option :visible? do
          authorized?
        end
      end
    end
  end
end

