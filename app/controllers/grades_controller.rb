class GradesController < ApplicationController
  before_action :set_grade, only: %i[ show edit update destroy kardex ]
  # Precarga específica para PDF Kardex para evitar N+1 y acelerar render
  before_action :preload_kardex_data, only: %i[ kardex ]

  # GET /grades or /grades.json
  def index
    @grades = Grade.all
  end

  def kardex
    school = @grade.school
    user = @grade.user
    respond_to do |format|
      format.pdf do
        # Registrar la descarga en PaperTrail
        @grade.versions.create(event: 'Se generó Kardex')        
        title = 'Historia Académica'
        render pdf: "kardex-#{school.code}-#{user.ci}",
               locals: {grade: @grade},
               formats: [:html],
               page_size: 'letter',
               header: { html: { template: '/grades/kardex_title', formats: [:html], layout: false, locals: { title: title, school: school, user: user } } },
               footer: { center: "Página: [page] de [topage]", font_size: '10' },
               margin: { top: 56 },
               # Optimizaciones: evitar ejecutar JS y no bloquear por recursos que fallen al cargar
               disable_javascript: true,
               load_error_handling: 'ignore',
               load_media_error_handling: 'ignore'
      end
    end      
  end

  # GET /grades/1 or /grades/1.json
  def show
    @school = @grade.school
    @faculty = @school.faculty
    @user = @grade.user
    @academic_records = @grade.academic_records
    @enroll_academic_processes = @grade.enroll_academic_processes
    respond_to do |format|
      format.html
    end
  end

  # GET /grades/new
  def new
    @grade = Grade.new
  end

  # GET /grades/1/edit
  def edit
  end

  # POST /grades or /grades.json
  def create
    @grade = Grade.new(grade_params)

    respond_to do |format|
      if @grade.save
        format.html { redirect_to grade_url(@grade), notice: "Grade was successfully created." }
        format.json { render :show, status: :created, location: @grade }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @grade.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /grades/1 or /grades/1.json
  def update
    respond_to do |format|
      if @grade.update(grade_params)
        format.html { redirect_to grade_url(@grade), notice: "Grade was successfully updated." }
        format.json { render :show, status: :ok, location: @grade }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @grade.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /grades/1 or /grades/1.json
  def destroy
    @grade.destroy

    respond_to do |format|
      format.html { redirect_to grades_url, notice: "Grade was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_grade
      @grade = Grade.find(params[:id])
    end

    # Precargar asociaciones usadas en el PDF para evitar N+1
    def preload_kardex_data
      return unless action_name == 'kardex'
      @grade = Grade.includes(
        { student: :user },
        { study_plan: [:school, :subject_types] },
        { enroll_academic_processes: [
            { academic_process: { period: :period_type } },
            { academic_records: [
                :qualifications,
                { section: { course: :subject } }
              ] }
          ] }
      ).find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def grade_params
      params.require(:grade).permit(:student_id, :study_plan_id, :graduate_status, :admission_type_id, :registration_status, :efficiency, :weighted_average, :simple_average)
    end

end
