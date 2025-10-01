# frozen_string_literal: true
# require 'rails_admin/config/actions'
# require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class Export < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        include ActionController::Live
        
        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          %i[get post]
        end


        register_instance_option :controller do
          proc do
            format = params[:xlsx] && :xlsx || params[:csv] && :csv

            p "  Export format: #{format}    ".center(1000, 'C')
            # export_method = format == :csv ? :to_csv_streaming : :to_xlsx_streaming
            if request.post?
              request.format = format

              @schema = HashHelper.symbolize(params[:schema].slice(:except, :include, :methods, :only).permit!.to_h) if params[:schema]
              @objects = list_entries(@model_config, :export)

              begin
                unless @model_config.list.scopes.empty?
                  if params[:scope].blank?
                    @objects = @objects.send(@model_config.list.scopes.first) unless @model_config.list.scopes.first.nil?
                  elsif @model_config.list.scopes.collect(&:to_s).include?(params[:scope])
                    @objects = @objects.send(params[:scope].to_sym)
                  end
                end

                response.headers.delete('Content-Length')
                response.headers['Cache-Control'] = 'no-cache'
                response.headers['X-Accel-Buffering'] = 'no'
                response.headers['ETag'] = '0'
                response.headers['Last-Modified'] = '0'
                response.headers['Connection'] = 'keep-alive'

                aux = "Reporte Coes - #{I18n.t("activerecord.models.#{params[:model_name]}.other")&.titleize} #{DateTime.now.strftime('%d-%m-%Y_%I:%M%P')}"
                excel_converter = ExcelConverter.new(@objects, @schema)
                total_count = @objects.count

                Rails.logger.info "Iniciando exportación de #{total_count} registros"

                if format.to_sym == :csv
                  p "  Exporting to CSV format...    ".center(1000, 'C')
                  response.headers['Content-Type'] = "text/csv; charset=utf-8"
                  response.headers['Content-Disposition'] = "attachment; filename=\"#{aux}.csv\""
                  excel_converter.to_csv_streaming(response.stream)
                else
                  response.headers['Content-Type'] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                  response.headers['Content-Disposition'] = "attachment; filename=\"#{aux}.xlsx\""
                  excel_converter.to_xlsx_streaming(response.stream)
                end

                Rails.logger.info "Exportación completada"

              rescue => e
                Rails.logger.error "Error en exportación: #{e.message}"
                Rails.logger.error e.backtrace.join("\n")
                response.stream.write("Error en la exportación: #{e.message}")
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