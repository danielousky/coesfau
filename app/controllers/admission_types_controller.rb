class AdmissionTypesController < ApplicationController
  before_action :set_admission_type, only: %i[ show edit update destroy ]

  # GET /admission_types or /admission_types.json
  def index
    @admission_types = AdmissionType.all
  end

  # GET /admission_types/1 or /admission_types/1.json
  def show
  end

  # GET /admission_types/new
  def new
    @admission_type = AdmissionType.new
  end

  # GET /admission_types/1/edit
  def edit
  end

  # POST /admission_types or /admission_types.json
  def create
    @admission_type = AdmissionType.new(admission_type_params)

    respond_to do |format|
      if @admission_type.save
        format.html { redirect_to admission_type_url(@admission_type), notice: "Admission type was successfully created." }
        format.json { render :show, status: :created, location: @admission_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admission_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admission_types/1 or /admission_types/1.json
  def update
    respond_to do |format|
      if @admission_type.update(admission_type_params)
        format.html { redirect_to admission_type_url(@admission_type), notice: "Admission type was successfully updated." }
        format.json { render :show, status: :ok, location: @admission_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admission_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admission_types/1 or /admission_types/1.json
  def destroy
    @admission_type.destroy

    respond_to do |format|
      format.html { redirect_to admission_types_url, notice: "Admission type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admission_type
      @admission_type = AdmissionType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admission_type_params
      params.require(:admission_type).permit(:code, :name)
    end
end
