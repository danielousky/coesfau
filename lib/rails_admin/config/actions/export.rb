# frozen_string_literal: true
# require 'rails_admin/config/actions'
# require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class Export < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        # include ActionController::Live
        
        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          %i[get post]
        end


        register_instance_option :controller do
          proc do
            # format = params[:json] && :json || params[:csv] && :csv || params[:xml] && :xml
            if request.post?
              request.format = :xlsx

              @schema = HashHelper.symbolize(params[:schema].slice(:except, :include, :methods, :only).permit!.to_h) if params[:schema] # to_json and to_xml expect symbols for keys AND values.
              @objects = list_entries(@model_config, :export)
              
              begin

                unless @model_config.list.scopes.empty?
                  if params[:scope].blank?
                    @objects = @objects.send(@model_config.list.scopes.first) unless @model_config.list.scopes.first.nil?
                  elsif @model_config.list.scopes.collect(&:to_s).include?(params[:scope])
                    @objects = @objects.send(params[:scope].to_sym)
                  end
                end

                if false #@objects.count > 300 and @schema[:include]&.count > 3
                  # POTENCIAL PROBLEMA:

                  # The code enqueues a LargeExportJob background job with @objects as an argument. 
                  # If @objects is an ActiveRecord relation or a large dataset, passing it directly to a background job can cause serialization issues or excessive memory usage. 
                  # It is generally safer to pass only IDs or query parameters to background jobs and re-fetch the records within the job itself.

                  # LargeExportJob.perform_later(_current_user.id, params[:model_name], @objects, @schema )
                  flash[:notice] = "La exportación ha comenzado, sin embargo la generación de la solicitud es de alta complejidad y requiere de mayor tiempo. Su solicitud será enviada por correo cuando esté lista."
                  redirect_to "/admin/#{params[:model_name]}"
                else

                  response.headers.delete('Content-Length')
                  response.headers['Cache-Control'] = 'no-cache'
                  response.headers['Content-Type'] = "text/event-stream;charset=utf-8;application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                  response.headers['X-Accel-Buffering'] = 'no'
                  response.headers['ETag'] = '0'
                  response.headers['Last-Modified'] = '0'
                  aux = "Reporte Coes - #{I18n.t("activerecord.models.#{params[:model_name]}.other")&.titleize} #{DateTime.now.strftime('%d-%m-%Y_%I:%M%P')}.xlsx"
                  response.headers['Content-Disposition'] = "attachment; filename=#{aux}"

                  response.stream.write ExcelConverter.new(@objects, @schema).to_xlsx
                end
                  
                
              ensure
                response.stream.close
              end
              
            else
              render @action.template_name
            end
          end
        end

        register_instance_option :bulkable? do
          true
        end

        register_instance_option :link_icon do
          'fas fa-file-export'
        end
      end
    end
  end
end