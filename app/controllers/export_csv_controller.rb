class ExportCsvController < ActionController::Base
  include ActionController::Live

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    5.times {
      response.stream.write "Hola Mundo\n"
      sleep 4
    }
  ensure
    response.stream.close
  end


  def academic_records
    # require 'xlsxtream'
    begin
      entity = params[:model_name].camelize.constantize.find (params[:id])

      model = entity.class.name.underscore
      model_titulo = "#{I18n.t("activerecord.models.#{model}.one")&.titleize}"
      aux = "Reporte Coes - Registros - #{model_titulo} #{DateTime.now.strftime('%d-%m-%Y_%I:%M%P')}.csv"
      response.headers.delete('Content-Length')
      response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = '0'
      response.headers['Content-Type'] = "text/event-stream;charset='utf-8';header=present"
      response.headers['X-Accel-Buffering'] = 'no'
      response.headers['ETag'] = '0'
      response.headers['Last-Modified'] = '0'
      response.headers['Content-Disposition'] = "attachment; filename=#{aux}"    

      a = AcademicRecord.header_for_report #['#', 'CI', 'NOMBRES', 'APELLIDOS', 'ESCUELA', 'CATEDRA','CÓDIGO ASIG', 'NOMBRE ASIG','PERIODO','SECCIÓN','ESTADO']
      
      entity.academic_records.includes(:section, :user, :period, :subject, :area).find_each(batch_size: 500).with_index do |academic_record, i|
        response.stream.write "#{a.join(';')}\n" if (i.eql? 0) 
        response.stream.write "#{i+1}; #{academic_record.values_for_report.join(';')}\n"
      end

      # Ojo: Versión incompleta con xlsx
      # io = StringIO.new
      # xlsx = Xlsxtream::Workbook.new(io)
      
      # xlsx.add_worksheet(name: "Registros Académicos de #{model_titulo}") do |sheet|
      #   ActiveRecord::Base.connection.uncached do
      #     @object.academic_records.includes(:section, :user, :period, :subject, :area).find_each(batch_size: 500) do |academic_record|
      #       response.stream.write sheet.add_row(academic_record.valuse_for_report)
      #     end
      #   end
      # end

    rescue Exception => e
      flash[:success] = "No se pudo generar el archivo: #{e}" 
      redirect_back fallback_location: '/admin'
    ensure
      response.stream.close
    end
  end

  def enroll_academic_processes
    begin
      # entity = params[:model_name].camelize.constantize.find (params[:id])

      entity = AcademicProcess.find 10


      cod = entity.name
      cod ||= entity.code
      cod ||= entity.id
      model = entity.class.name.underscore
      model_titulo = "#{I18n.t("activerecord.models.#{model}.one")&.titleize}"
      aux = "Reporte Coes - Inscritos - #{model_titulo} #{cod} #{DateTime.now.strftime('%d-%m-%Y_%I:%M%P')}.csv"
      response.headers.delete('Content-Length')
      response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = '0'
      response.headers['Content-Type'] = "text/event-stream;charset='utf-8';header=present"
      response.headers['X-Accel-Buffering'] = 'no'
      response.headers['ETag'] = '0'
      response.headers['Last-Modified'] = '0'
      response.headers['Content-Disposition'] = "attachment; filename=#{aux}"    

      a = EnrollAcademicProcess.header_for_report #['#', 'CI', 'NOMBRES', 'APELLIDOS','ESCUELA','PERIODO','ESTADO INSCRIP','ESTADO PERMANENCIA','REPORTE PAGO']
      
      entity.enroll_academic_processes.includes(:user, :grade, :academic_process, :payment_reports).find_each(batch_size: 500).with_index do |enroll_academic_process, i|
        response.stream.write "#{a.join(';')}\n" if (i.eql? 0) 
        response.stream.write "#{i+1}; #{enroll_academic_process.values_for_report.join(';')}\n"
      end

    rescue Exception => e
      flash[:success] = "No se pudo generar el archivo: #{e}" 
      redirect_back fallback_location: '/admin'
    ensure
      response.stream.close
    end
  end


end