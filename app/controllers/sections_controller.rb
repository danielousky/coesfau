class SectionsController < ApplicationController
  before_action :set_section, only: %i[ show update export change]

  layout 'logged'

  # GET /sections or /sections.json
  def index
    @sections = Section.all
  end

  def export
    respond_to do |format|
      format.xls {send_file @section.excel_list, filename: "Listado_Sec_#{@section.name_to_file}.xls", disposition: 'inline'}
    end
  end

  def bulk_delete

    if Section.where(id: params[:bulk_ids]).destroy_all
      flash[:info] = 'Secciones Eliminadas'
    else
      flash[:danger] = 'Error al intentar eliminar las secciones'
    end

    redirect_back fallback_location: root_path
  end

  # GET /sections/1 or /sections/1.json
  def show
    if current_admin or (current_teacher and @section.teacher and @section.teacher_id.eql? current_teacher.id)
      respond_to do |format|
        format.html
        format.pdf do
          top = 72
          # top += 10 if @section.subject&.name&.length > 52
          render pdf: "acta_#{@section.number_acta}", template: "sections/acta", locals: {section: @section}, formats: [:html], page_size: 'letter', header: {html: {template: '/sections/acta_header', formats: [:html], layout: false, locals: {school: @section.school, section: @section}}}, footer: {html: {template: '/sections/signatures', formats: [:html]}}, margin: {top: top, bottom: 68}#, dpi: 150
        end
      end
    else
      flash[:warning] = 'Sección no asignada'
      redirect_back fallback_location: root_path
    end
  end

  # GET /sections/new
  # def new
  #   @section = Section.new
  # end

  # GET /sections/1/edit
  # def edit
  # end

  # POST /sections or /sections.json
  def create
    @section = Section.new(section_params)

    respond_to do |format|
      if @section.save
        # @section.schedules.create(section_params.schedules_attributes)
        format.html { redirect_back fallback_location: '/admin/academic_process', notice: "Sección Creada con Éxito!" }
        format.json { render :show, status: :created, location: @section }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @section.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sections/1 or /sections/1.json
  def update
    if @section.totaly_qualified?
      msg, type = @section.update(section_params) ? ["¡Sección calificada con éxito!", 'success'] : [@section.errors.full_messages.to_sentence, 'danger']
    else
      msg, type = ['Atención: No se pudo cerrar la calificación, faltan calificaciones por completar. Por favor refresque la pantalla e inténte calificar los registros restantes.', 'danger']
    end
    flash[type] = msg
    redirect_back fallback_location: section_url(@section)

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_section
      @section = Section.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def section_params
      params.require(:section).permit(:id, :code, :capacity, :course_id, :teacher_id, :qualified, :modality, :location, :classroom, :enabled)
    end

  # def schedules_params
  #   params.require(:schedules).permit(:day, :starttime, :endtime)
  # end
end
