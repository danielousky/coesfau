class EnrollmentDaysController < ApplicationController
  before_action :logged_as_admin?
  before_action :set_enrollment_day, only: %i[ destroy export ]

  # GET /enrollment_days or /enrollment_days.json
  def index
    @enrollment_days = EnrollmentDay.all
  end

  # GET /enrollment_days/1 or /enrollment_days/1.json
  def show
  end

  # GET /enrollment_days/new
  def new
    @enrollment_day = EnrollmentDay.new
  end

  def send_email_enrollment_day
    
  end

  def export
    respond_to do |format|
      format.xls {send_data @enrollment_day.own_grades_to_csv, filename: "#{@enrollment_day.name_to_file}.xls"}
    end
  end

  # GET /enrollment_days/1/edit
  # def edit
  # end

  # POST /enrollment_days or /enrollment_days.json
  def create
    @enrollment_day = EnrollmentDay.new(enrollment_day_params)

    # selected_date = Date.strptime(enrollment_day_params[:start], '%Y-%m-%d %I:%M:00')
    # @enrollment_day.start = selected_date

    if @enrollment_day.save

      flash[:success] = 'Jornada de inscripción por cita horaria creada con éxito.'

      total_updated = 0
      academic_process = @enrollment_day.academic_process
      total_timeslots = @enrollment_day.total_timeslots
      grades_by_timeslot = @enrollment_day.grades_by_timeslot-1
      duration_slot_time = @enrollment_day.slot_duration_minutes

      for a in 0..(total_timeslots-1) do

        appointment_time = @enrollment_day.start+(a*@enrollment_day.slot_duration_minutes).minutes

        total_updated += academic_process.update_grades_enrollment_day @enrollment_day.over_academic_process_id, grades_by_timeslot, appointment_time, duration_slot_time

      end

      rest = @enrollment_day.mod_to_grades

      if rest > 0
        appointment_time = @enrollment_day.start+(total_timeslots*@enrollment_day.slot_duration_minutes).minutes

        total_updated += academic_process.update_grades_enrollment_day @enrollment_day.over_academic_process_id, rest-1, appointment_time, duration_slot_time

      end

      flash[:success] += ". Se generaron #{total_updated} citas"
    else
      flash[:danger] = @enrollment_day.errors.full_messages.to_sentence
    end
    redirect_to "/admin/academic_process/#{@enrollment_day.academic_process.id}/enrollment_day"

  end

  # PATCH/PUT /enrollment_days/1 or /enrollment_days/1.json
  # def update
  #   respond_to do |format|

  #     if @enrollment_day.update(enrollment_day_params)
  #       format.html { redirect_to enrollment_day_url(@enrollment_day), notice: "Enrollment day was successfully updated." }
  #       format.json { render :show, status: :ok, location: @enrollment_day }
  #     else
  #       format.html { render :edit, status: :unprocessable_entity }
  #       format.json { render json: @enrollment_day.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  def destroy_all
    flash[:info] = 'Eliminadas todas las Citas Horarias' if EnrollmentDay.destroy_all
    redirect_back fallback_location: '/admin/academic_process'
  end

  # DELETE /enrollment_days/1 or /enrollment_days/1.json
  def destroy
    academic_process_id = @enrollment_day.academic_process_id
    @enrollment_day.destroy

    respond_to do |format|
      format.html { redirect_to "/admin/academic_process/#{academic_process_id}/enrollment_day", notice: "Jornadas de Inscripción por Cita Horaria eliminada con éxito. Todos sus respectivas citas horarias fueron limpiadas " }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_enrollment_day
      @enrollment_day = EnrollmentDay.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def enrollment_day_params
      params.require(:enrollment_day).permit(:academic_process_id, :start, :total_duration_hours, :max_grades, :slot_duration_minutes, :over_academic_process_id)
    end
end
