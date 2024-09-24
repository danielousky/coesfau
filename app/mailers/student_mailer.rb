class StudentMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.welcome.subject
  # 

  def preinscrito(enroll_academic_process)
    @subjects = enroll_academic_process.subjects
    @school = enroll_academic_process.school
    @period = enroll_academic_process.academic_process
    @user = enroll_academic_process.user
    mail(to: @user.email, subject: "¡Preinscripción Exitosa en #{@school.short_name} para el Período #{@period.name} COES! ")    
    
  end

end
