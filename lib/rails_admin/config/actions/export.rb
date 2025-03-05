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

        # register_instance_option :controller do
        #   proc do
        #     format = params[:json] && :json || params[:csv] && :csv || params[:xml] && :xml
        #     if format
        #       request.format = format
        #       @schema = HashHelper.symbolize(params[:schema].slice(:except, :include, :methods, :only).permit!.to_h) if params[:schema] # to_json and to_xml expect symbols for keys AND values.
        #       @objects = list_entries(@model_config, :export)
        #       index
        #     else
        #       render @action.template_name
        #     end
        #   end
        # end


        register_instance_option :controller do
          proc do
            format = params[:json] && :json || params[:csv] && :csv || params[:xml] && :xml
            if format
              request.format = format

              @schema = HashHelper.symbolize(params[:schema].slice(:except, :include, :methods, :only).permit!.to_h) if params[:schema] # to_json and to_xml expect symbols for keys AND values.
              @objects = list_entries(@model_config, :export)
              
              if false #request.format.json? || request.format.xml?

                p "  request.format: <#{request.format}>  ".center(1000, '@')
                p "  JSON: <#{request.format.json?}>  ".center(1000, 'J')
                p "  XML: <#{request.format.xml?}>  ".center(1000, 'X')
                p "  CSV: <#{request.format.csv?}>  ".center(1000, 'C')
                # index
              else
                begin

                  params[:csv_options][:encoding_to] = 'utf-8' 
                  params[:csv_options][:generator][:col_sep] = ';' 


                  unless @model_config.list.scopes.empty?
                    if params[:scope].blank?
                      @objects = @objects.send(@model_config.list.scopes.first) unless @model_config.list.scopes.first.nil?
                    elsif @model_config.list.scopes.collect(&:to_s).include?(params[:scope])
                      @objects = @objects.send(params[:scope].to_sym)
                    end
                  end

                  header, encoding, output = CSVConverter.new(@objects, @schema).to_csv(params[:csv_options].permit!.to_h)

                  
                  response.headers.delete('Content-Length')
                  # response.headers['Content-Type'] = "text/event-stream;charset=#{encoding}; #{'header=present' if header}"
                  response.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                  response.headers['Cache-Control'] = 'no-cache'
                  response.headers['X-Accel-Buffering'] = 'no'
                  response.headers['ETag'] = '0'
                  aux = "Reporte Coes - #{I18n.t("activerecord.models.#{params[:model_name]}.other")&.titleize} #{DateTime.now.strftime('%d-%m-%Y_%I:%M%P')}.xlsx"
                  response.headers['Content-Disposition'] = "attachment; filename=\"#{aux}\""

                  xls_adapter = XlsAdapter.new(output)
                  
                  # send_data xls_stream.read,
                  #           type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  #           filename: aux

                  response.stream.write xls_adapter.to_xls.read
                ensure
                  response.stream.close
                end
              end
            else
              render @action.template_name
            end
          end
        end


        # register_instance_option :controller do
        #   proc do

        #     begin
        #       format = params[:json] && :json || params[:csv] && :csv || params[:xml] && :xml
        #       if format
        #         response.headers.delete('Content-Length')
        #         response.headers['Cache-Control'] = 'no-cache'
        #         response.headers['X-Accel-Buffering'] = 'no'
        #         response.headers['Content-Type'] = 'text/event-stream'
        #         response.headers['ETag'] = '0'
        #         response.headers['Last-Modified'] = '0'
        #         aux = "Reporte Coes #{I18n.t("activerecord.models.#{params[:model_name]}.other")&.titleize} #{DateTime.now.strftime('%d-%m-%Y_%I:%M%P')}.xls"
        #         response.headers['Content-Disposition'] = "attachment; filename=#{aux}"
        #         request.format = format
        #         @schema = HashHelper.symbolize(params[:schema].slice(:except, :include, :methods, :only).permit!.to_h) if params[:schema] # to_json and to_xml expect symbols for keys AND values.
        #         @objects = list_entries(@model_config, :export)

        #         unless @model_config.list.scopes.empty?
        #           if params[:scope].blank?
        #             @objects = @objects.send(@model_config.list.scopes.first) unless @model_config.list.scopes.first.nil?
        #           elsif @model_config.list.scopes.collect(&:to_s).include?(params[:scope])
        #             @objects = @objects.send(params[:scope].to_sym)
        #           end
        #         end


        #         header, encoding, output = CSVConverter.new(@objects, @schema).to_csv(params[:csv_options].permit!.to_h)
                
        #         response.stream.write output
                
        #       end
        #     ensure
        #       response.stream.close
        #     end
        #   end
        # end


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