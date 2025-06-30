class UserMailer < ApplicationMailer
  default from: 'SOPORTE COES-FAU <soporte@coesfau.com>'
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.welcome.subject
  #
  def welcome user
    mail(to: user.email_desc, subject: "¡Bienvenido a Coes!")
  end

  def general user, msg
    @msg = msg
    mail(to: user.email_desc, subject: "¡Correo General de Coes!")
  end  

  def enroll_confirmation(id)
    enroll_academic_process = EnrollAcademicProcess.find id
    user = enroll_academic_process.user
    escuela = enroll_academic_process.school
    @sections = enroll_academic_process.sections

    @escuela_name = escuela.name
    @periodo_name = enroll_academic_process.period.name
    @nombre = user.nick_name
    @genero = user.genero
    mail(to: user.email_desc, subject: "¡Confirmación de inscripción en #{@escuela_name} para el Período #{@periodo_name} COES-FAU!")
    
  end

  def large_export(user_id, file_name, objects, schema)
    user = User.find user_id
    xlsx = ExcelConverter.new(objects, schema).to_xlsx
    attachment = Base64.encode64(xlsx)
    attachments["Users.xlsx"] = {mime_type: Mime[:xlsx], content: attachment, encoding: 'base64'}
    mail(to: user.email_desc, subject: "¡Reporte largo solicitado: #{file_name}!")
  end

end
