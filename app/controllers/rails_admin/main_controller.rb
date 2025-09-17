# frozen_string_literal: true

module RailsAdmin
  class MainController < RailsAdmin::ApplicationController
    include ActionView::Helpers::TextHelper
    include RailsAdmin::MainHelper
    include RailsAdmin::ApplicationHelper

    before_action :set_current_env
    before_action :set_current_period
    before_action :check_for_cancel

    
    def bulk_action
      get_model
      process(params[:bulk_action]) if params[:bulk_action].in?(RailsAdmin::Config::Actions.all(:bulkable, controller: self, abstract_model: @abstract_model).collect(&:route_fragment))
    end
    
    def list_entries(model_config = @model_config, auth_scope_key = :index, additional_scope = get_association_scope_from_params, pagination = !(params[:associated_collection] || params[:all] || params[:bulk_ids]))
      scope = model_config.scope
      auth_scope = @authorization_adapter&.query(auth_scope_key, model_config.abstract_model)
      
      
      if !(current_admin.desarrollador?)
        
        if (@abstract_model.to_s.eql? 'Departament' and session[:env_type].eql? 'Departament') or (@abstract_model.to_s.eql? 'School' and session[:env_type].eql? 'School')          
          scope = scope.where(id: session[:env_ids]) 
        else
          # p "     Controller: #{controller_name} | Action: #{action_name} | @abstract_model: #{@abstract_model} | model_config.abstract_model: #{model_config.abstract_model}      ".center(2000, "$")
          if @abstract_model.to_s.eql? 'AcademicProcess' and model_config.abstract_model.to_s.eql? 'Period' and action_name.eql? 'new'
            schoolables = ['Subject', 'Teacher', 'StudyPlan', 'Departament', 'EnrollAcademicProcess', 'PaymentReport', 'Grade', 'Area', 'Section', 'Course', 'AcademicRecord']
          else
            schoolables = ['Subject', 'Teacher', 'StudyPlan', 'Departament', 'AcademicProcess', 'EnrollAcademicProcess', 'PaymentReport', 'Grade', 'Area', 'Section', 'Course', 'AcademicRecord']
          end
          schoolables.delete 'Teacher' if (session[:env_type]&.to_s.eql? 'School' and session[:env_ids].include? 11)
          departamentables = ['Teacher', 'Area', 'Section']
          if session[:env_type]&.to_s.eql? 'Departament'
            if departamentables.include? @abstract_model.to_s

              scope = (@abstract_model.to_s.eql? 'Section') ? scope.joins(:departament).where('departaments.id': session[:env_ids]) : scope.joins(:departaments).where('departaments.id': session[:env_ids])
            else
              school_ids = Departament.where(id: session[:env_ids]).map(&:school_id).uniq
              if @abstract_model.to_s.eql? 'Student'
                scope = scope.joins(:schools).where('schools.id': school_ids)
              elsif schoolables.include? @abstract_model.to_s and schoolables.include? model_config.abstract_model.to_s
                scope = scope.joins(:school).where('schools.id': school_ids) 
              end
            end
          else
            if @abstract_model.to_s.eql? 'Student' #and model_config.abstract_model.to_s.eql? 'Student'
              if model_config.abstract_model.to_s.eql? 'StudyPlan'
                # p "  IF: Estoy aquí después  #{model_config.abstract_model.to_s}".center(500, '#')
                scope = scope.joins(:school).where('schools.id': session[:env_ids]) 
              elsif !model_config.abstract_model.to_s.eql? 'AdmissionType'
                scope = scope.joins(:schools).where('schools.id': session[:env_ids]) 
                # p "  Else: Estoy aquí después  #{model_config.abstract_model.to_s}".center(500, '#')
              end

            elsif schoolables.include? @abstract_model.to_s and schoolables.include? model_config.abstract_model.to_s
              scope = scope.joins(:school).where('schools.id': session[:env_ids])
            elsif (schoolables << 'School').include? @abstract_model.to_s and (schoolables << 'School').include? model_config.abstract_model.to_s
              scope = scope.joins(:school).where('schools.id': [])
            end
          end

        end
      else
        scope = scope.joins(:school) if @abstract_model.to_s.eql? 'EnrollAcademicProcess' or @abstract_model.to_s.eql? 'AcademicRecord' or @abstract_model.to_s.eql? 'Section' or @abstract_model.to_s.eql? 'Course'
      end

      if session[:period_name].present?
        case @abstract_model.to_s
        when 'Section'
          scope = scope.joins(:period).where('periods.name': session[:period_name])
        when 'EnrollAcademicProcess'
          scope = scope.joins(:period).where('periods.name': session[:period_name])
        when 'Course'
          scope = scope.joins(:period).where('periods.name': session[:period_name])
        when 'AcademicRecord'
          scope = scope.joins(:period).where('periods.name': session[:period_name])
        end
      end


      scope = scope.merge(auth_scope) if auth_scope
      scope = scope.instance_eval(&additional_scope) if additional_scope
      get_collection(model_config, scope, pagination)
    end

    def current_admin
        current_user.admin if logged_as_admin?
    end
    def logged_as_admin?
        current_user&.admin? and session[:rol].eql? 'admin'
    end

    def set_current_env
      if current_admin
        if !(current_admin.desarrollador?)
          session[:env_type] = current_admin.env_auths.map(&:env_authorizable_type).first
          session[:env_ids] = current_admin.env_auths.map(&:env_authorizable_id)
        end
      end
    end    

  private

    def set_current_period
      session[:period_name] ||= current_user.admin.periods&.first&.name
    end

    def action_missing(name, *_args)
      action = RailsAdmin::Config::Actions.find(name.to_sym)
      raise AbstractController::ActionNotFound.new("The action '#{name}' could not be found for #{self.class.name}") unless action

      get_model unless action.root?
      get_object if action.member?
      @authorization_adapter.try(:authorize, action.authorization_key, @abstract_model, @object)
      @action = action.with({controller: self, abstract_model: @abstract_model, object: @object})
      raise(ActionNotAllowed) unless @action.enabled?

      @page_name = wording_for(:title)

      instance_eval(&@action.controller)
    end

    def method_missing(name, *args, &block)
      action = RailsAdmin::Config::Actions.find(name.to_sym)
      if action
        action_missing name, *args, &block
      else
        super
      end
    end

    def respond_to_missing?(sym, include_private)
      if RailsAdmin::Config::Actions.find(sym)
        true
      else
        super
      end
    end

    def back_or_index
      allowed_return_to?(params[:return_to].to_s) ? params[:return_to] : index_path
    end

    def allowed_return_to?(url)
      url != request.fullpath && url.start_with?(request.base_url, '/') && !url.start_with?('//')
    end

    def get_sort_hash(model_config)
      field = model_config.list.fields.detect { |f| f.name.to_s == params[:sort] }
      # If no sort param, default to the `sort_by` specified in the list config
      field ||= model_config.list.possible_fields.detect { |f| f.name == model_config.list.sort_by.try(:to_sym) }

      column =
        if field.nil? || field.sortable == false # use default sort, asked field does not exist or is not sortable
          model_config.list.sort_by
        else
          field.sort_column
          # Filtrar por período actual para los modelos indicados
          # if @current_period.present? and !scope.nil?
          #   case @abstract_model.to_s
          #   when 'Section'
          #     scope = scope.where('periods.id': @current_period.id)
          #   when 'EnrollAcademicProcess'
          #     scope = scope.where('periods.id': @current_period.id)
          #   when 'Course'
          #     scope = scope.where('periods.id': @current_period.id)
          #   when 'AcademicRecord'
          #     scope = scope.where('periods.id': @current_period.id)
          #   end
          # end

        end

      params[:sort_reverse] ||= 'false'
      {sort: column, sort_reverse: (params[:sort_reverse] == (field&.sort_reverse&.to_s || 'true'))}
    end

    def redirect_to_on_success
      notice = I18n.t('admin.flash.successful', name: @model_config.label, action: I18n.t("admin.actions.#{@action.key}.done"))
      if params[:_add_another]
        redirect_to new_path(return_to: params[:return_to]), flash: {success: notice}
      elsif params[:_add_edit]
        redirect_to edit_path(id: @object.id, return_to: params[:return_to]), flash: {success: notice}
      else
        redirect_to back_or_index, flash: {success: notice}
      end
    end

    def visible_fields(action, model_config = @model_config)
      model_config.send(action).with(controller: self, view: view_context, object: @object).visible_fields
    end

    def sanitize_params_for!(action, model_config = @model_config, target_params = params[@abstract_model.param_key])
      return unless target_params.present?

      fields = visible_fields(action, model_config)
      allowed_methods = fields.collect(&:allowed_methods).flatten.uniq.collect(&:to_s) << 'id' << '_destroy'
      fields.each { |field| field.parse_input(target_params) }
      target_params.slice!(*allowed_methods)
      target_params.permit! if target_params.respond_to?(:permit!)
      fields.select(&:nested_form).each do |association|
        children = target_params[association.method_name]
        children_params =
          if association.multiple?
            if children.is_a?(Hash)
              children.values
            elsif children.is_a?(Array)
              children
            else
              []
            end
          else
            [children].compact
          end
        (children_params || []).each do |children_param|
          sanitize_params_for!(:nested, association.associated_model_config, children_param)
        end
      end
    end

    def handle_save_error(whereto = :new)
      flash.now[:error] = I18n.t('admin.flash.error', name: @model_config.label, action: I18n.t("admin.actions.#{@action.key}.done").html_safe).html_safe
      flash.now[:error] += %(<br>- #{@object.errors.full_messages.join('<br>- ')}).html_safe

      respond_to do |format|
        format.html { render whereto, status: :not_acceptable }
        format.js   { render whereto, layout: 'rails_admin/modal', status: :not_acceptable, content_type: Mime[:html].to_s }
      end
    end

    def check_for_cancel
      return unless params[:_continue] || (params[:bulk_action] && !params[:bulk_ids])

      redirect_to(back_or_index, notice: I18n.t('admin.flash.noaction'))
    end

    def get_collection(model_config, scope, pagination)
      section = @action.key == :export ? model_config.export : model_config.list
      eager_loads = section.fields.flat_map(&:eager_load_values)
      options = {}
      options = options.merge(page: (params[Kaminari.config.param_name] || 1).to_i, per: (params[:per] || model_config.list.items_per_page)) if pagination
      options = options.merge(include: eager_loads) unless eager_loads.blank?
      options = options.merge(get_sort_hash(model_config))
      options = options.merge(query: params[:query]) if params[:query].present?
      options = options.merge(filters: params[:f]) if params[:f].present?
      options = options.merge(bulk_ids: params[:bulk_ids]) if params[:bulk_ids]
      model_config.abstract_model.all(options, scope)
    end

    def get_association_scope_from_params
      return nil unless params[:associated_collection].present?

      source_abstract_model = RailsAdmin::AbstractModel.new(to_model_name(params[:source_abstract_model]))
      source_model_config = source_abstract_model.config
      source_object = source_abstract_model.get(params[:source_object_id])
      action = params[:current_action].in?(%w[create update]) ? params[:current_action] : 'edit'
      @association = source_model_config.send(action).fields.detect { |f| f.name == params[:associated_collection].to_sym }.with(controller: self, object: source_object)
      @association.associated_collection_scope
    end
  end
end
