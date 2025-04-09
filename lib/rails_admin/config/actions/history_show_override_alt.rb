module RailsAdmin
    module Config
      module Actions
        class HistoryShow < RailsAdmin::Config::Actions::Base
          RailsAdmin::Config::Actions.register(self)
  
          register_instance_option :authorization_key do
            :history
          end
  
          register_instance_option :member do
            true
          end
  
          register_instance_option :route_fragment do
            'history'
          end
  
          register_instance_option :controller do
            proc do
              @page_name = t("admin.actions.history_show.menu")
              @abstract_model = RailsAdmin.config(params[:model_name].camelize).abstract_model
              # @abstract_model = params[:model_name].camelize.constantize#.find params[:id]

              
              begin
                @object = @abstract_model.get(params[:id])
                # @object = @abstract_model.find(params[:id])
                
                # Obtener todas las versiones para este objeto
                @versions = @object.versions.order('created_at DESC').page(params[:page] || 1).per(20)
                
                # Enriquecer cada versión con información adicional
                @versions.each do |version|
                  # Obtener el usuario que realizó la acción
                  if version.whodunnit.present?
                    version.instance_variable_set(:@user, User.find_by(id: version.whodunnit))
                  end
                  
                  # Determinar si es una auto-modificación (usuario modificando su propio perfil)
                  if version.item_type == 'User' && version.item_id.to_s == version.whodunnit
                    version.instance_variable_set(:@self_action, true)
                  end
                  
                  # Procesar los cambios para una mejor visualización
                  if version.object_changes.present?
                    begin
                      changes = YAML.safe_load(version.object_changes, [Time])
                      processed_changes = {}
                      
                      changes.each do |key, values|
                        # Manejar casos especiales
                        if key == 'updated_at' || key == 'created_at'
                          # Formatear fechas
                          if values.is_a?(Array) && values.size == 2
                            values = values.map { |v| v.nil? ? nil : v.strftime('%Y-%m-%d %H:%M:%S') }
                          end
                        elsif key.end_with?('_id') && values.is_a?(Array) && values.size == 2
                          # Intentar obtener nombres para las claves foráneas
                          related_model = key.gsub(/_id$/, '').classify
                          if Object.const_defined?(related_model)
                            model_class = related_model.constantize
                            values = values.map do |v|
                              if v.nil?
                                nil
                              else
                                related_obj = model_class.find_by(id: v)
                                related_obj ? "#{v} (#{related_obj.try(:name) || related_obj.try(:title) || related_obj.try(:email) || 'Sin nombre'})" : v
                              end
                            end
                          end
                        end
                        
                        processed_changes[key] = values
                      end
                      
                      version.instance_variable_set(:@processed_changes, processed_changes)
                    rescue => e
                      # Si hay un error al procesar los cambios, guardar el error
                      version.instance_variable_set(:@changes_error, e.message)
                    end
                  end
                end
                
                # Obtener estadísticas adicionales
                @stats = {
                  total_changes: @object.versions.count,
                  creation_date: @object.versions.reverse.find { |v| v.event == 'create' }&.created_at,
                  last_update: @object.versions.first&.created_at,
                  users: User.where(id: @object.versions.map(&:whodunnit).compact.uniq)
                }
                
                render @action.template_name
              rescue ActiveRecord::RecordNotFound
                flash[:error] = t("admin.flash.object_not_found", model: @abstract_model.pretty_name, id: params[:id])
                redirect_to index_path
              end
            end
          end

          register_instance_option :template_name do
            'history_show'
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
  
  