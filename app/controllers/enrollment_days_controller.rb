class EnrollmentDaysController < ApplicationController
  before_action :set_enrollment_day, only: %i[ destroy ]

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

  # GET /enrollment_days/1/edit
  # def edit
  # end

  # POST /enrollment_days or /enrollment_days.json
  def create
    @enrollment_day = EnrollmentDay.new(enrollment_day_params)

    # selected_date = Date.strptime(enrollment_day_params[:start], '%Y-%m-%d %I:%M:00')
    # @enrollment_day.start = selected_date

    if @enrollment_day.save

      flash[:success] = 'Jornada de Inscripción por Cita Horaria Creada con Éxito'
      academic_proccess = @enrollment_day.academic_process

      total_timeslots = @enrollment_day.total_timeslots
      grades_by_timeslot = @enrollment_day.grades_by_timeslot
      total_updted = 0
      for a in 0..(total_timeslots-1) do
        limitado = academic_proccess.readys_to_enrollment_day

        limitado[0..grades_by_timeslot-1].each{|gr| total_updted += 1 if gr.update(appointment_time: @enrollment_day.start+(a*@enrollment_day.slot_duration_minutes).minutes, duration_slot_time: @enrollment_day.slot_duration_minutes)}

      end

    else
      flash[:danger] = @enrollment_day.errors.full_messages.to_sentence
    end
    redirect_to "/admin/academic_process/#{@enrollment_day.academic_process.id}"

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

  # DELETE /enrollment_days/1 or /enrollment_days/1.json
  def destroy
    academic_proccess_id = @enrollment_day.academic_process_id
    @enrollment_day.destroy

    respond_to do |format|
      format.html { redirect_to "/admin/academic_process/#{academic_proccess_id}", notice: "Jornadas de Inscripción por Cita Horaria eliminada con éxito. Todos sus respectivas citas horarias fueron limpiadas " }
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
      params.require(:enrollment_day).permit(:academic_process_id, :start, :total_duration_hours, :max_grades, :slot_duration_minutes)
    end
end
