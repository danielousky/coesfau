class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit


  # around_action :set_session_data

  helper_method :logged_as_teacher_or_admin?, :logged_as_teacher?, :logged_as_student?, :logged_as_admin?, :current_admin, :current_teacher, :current_student, :current_academic_process#, :set_current_course

  # def set_session_data
  #   Course.session_academic_process_id = session[:academic_process_id]
  #   yield
  #   Course.session_academic_process_id = nil
  # end

  #AUTHORIZES TO:

  def autho_to action_name, clazz
    current_user&.admin&.authorized_to action_name, clazz
  end


  def models_list
    aux = ActiveRecord::Base.connection.tables-['schema_migrations', 'ar_internal_metadata'].map{|model| model.capitalize.singularize.camelize}
    return aux
  end

  # CURRENT USERS BY TYPE
  def current_admin
    current_user.admin if logged_as_admin?
  end

  def current_student
    current_user.student if logged_as_student?    
  end

  def current_teacher
    current_user.teacher if logged_as_teacher?
  end

  # IS LOGGED BY
  def logged_as_teacher_or_admin?
    logged_as_teacher? or logged_as_admin?
  end

  def logged_as_teacher?
    !current_user.nil? and !current_user.teacher.nil? and session[:rol].eql? 'teacher'
  end

  def logged_as_student?
    # !current_user.nil? and !current_user.student.nil? and session[:rol].eql? 'student'
    (session[:rol].eql? 'student') and current_user&.student
  end

  def logged_as_admin?
    !current_user.nil? and !current_user.admin.nil? and session[:rol].eql? 'admin'
  end

  def current_schools
    if current_admin
      env = current_admin.env_authorizable
      if env.is_a? Faculty
        env.schools
      elsif env.is_a? School
        School.where(id: env.id)
      end
    end    
  end

  def set_session_id_if_multirols
    session[:rol] = params[:rol] if (params[:rol] and current_user)
  end 


  def after_sign_in_path_for(resource)
    # session[:academic_process_id] = AcademicProcess.first.id

    if (current_user and !current_user.updated_password?)
      edit_password_user_path(current_user)
    else
      rols = []
      rols << :admin if current_user.admin
      rols << :student if current_user.student
      rols << :teacher if current_user.teacher
      if rols.count > 1
        pages_multirols_path(roles: rols)
      elsif current_user.admin?
        session[:rol] = 'admin'
        rails_admin_path
      elsif current_user.student?
        session[:rol] = 'student'
        student_session_dashboard_path
      elsif current_user.teacher?
        session[:rol] = 'teacher'
        teacher_session_dashboard_path
      else
        flash[:warning] = "No posee un rol asignado. Por favor diríjase a la Administración para cambiar dicha situación"
        root_path 
      end
    end
  end

  def authenticate_teacher!
    if !logged_as_teacher?
      reset_session
      flash[:danger] = "Debe iniciar sesión como Profesor"  
      redirect_to root_path
    end
  end

  def authenticate_student!
    if !logged_as_student?
      reset_session
      flash[:danger] = "Debe iniciar sesión como Estudiante"  
      redirect_to root_path
    end
  end

  def authenticate_student_or_teacher!
    if !(logged_as_student? or logged_as_teacher?)
      reset_session
      flash[:danger] = "Debe iniciar sesión como Estudiante o Profesor"  
      redirect_to root_path      
    end
  end

  def administrator_filter
		unless session[:administrador_id]
			reset_session
			flash[:danger] = "Debe iniciar sesión como Administrador"  
			redirect_to root_path
			return false
		end
	end

  def log_filter
		unless session[:usuario_ci]
			reset_session
			flash[:danger] = "Debe iniciar sesión"
			redirect_to root_path
			return false
		end
	end

  def authorized_filter
		accion = (!(controller_name.eql? 'secciones') and (action_name.eql? 'show')) ? 'index' : action_name
		funcion = Restringida.where(controlador: controller_name, accion: accion).first

		if funcion and current_usuario and (current_admin and !current_admin.maestros?) and not(current_usuario.autorizado?(controller_name, accion))
			msg = 'No posee los privilegios para ejecutar la acción solicitada'
			respond_to do |format|
				format.html do 
					flash[:danger] = msg
					redirect_back fallback_location: index2_secciones_path
				end
				format.json {render json: {data: msg, status: :success, type: :error} }
			end
		end
	end

end
