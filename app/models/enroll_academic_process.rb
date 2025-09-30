class EnrollAcademicProcess < ApplicationRecord
  include Numerizable
  # SCHEMA:
  # t.bigint "grade_id", null: false
  # t.bigint "academic_process_id", null: false
  # t.integer "enroll_status"
  # t.integer "permanence_status"

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

  after_save :update_grade

  # ASSOCIATIONS:
  belongs_to :grade
  has_one :student, through: :grade
  has_one :study_plan, through: :grade
  has_one :user, through: :student
  has_one :school, through: :grade
  
  belongs_to :academic_process
  has_one :period, through: :academic_process
  has_many :payment_reports, as: :payable, dependent: :destroy
  has_many :academic_records, dependent: :destroy
  has_many :sections, through: :academic_records
  has_many :schedules, through: :sections
  has_many :subjects, through: :sections
  has_many :areas, through: :sections

  # ENUMERIZE:
  # IDEA CON ESTADO DE INSCRIPCIÓN EN GRADE Y ENROLL ACADEMIC PROCESS
  enum enroll_status: [:preinscrito, :reservado, :confirmado]
  enum permanence_status: PERMANENCE_STATUSES

  # VALIDATIONS:
  validates :grade, presence: true
  validates :academic_process, presence: true
  validates :enroll_status, presence: true

  validates_uniqueness_of :academic_process, scope: [:grade], message: 'Ya inscrito en período', field_name: false
  # validates :permanence_status, presence: true

  # SCOPE:
  scope :todos, -> {where('0 = 0')}

  scope :of_academic_process, -> (academic_process_id) {where(academic_process_id: academic_process_id)}

  # scope :preinscrito_or_reservado, -> (){where(enroll_status: [:preinscrito, :reservado])}

  scope :sort_by_period, -> {joins(period: :period_type).order('periods.year': :desc, 'period_types.name': :desc)}

  scope :sort_by_period_reverse, -> {joins(period: :period_type).order('periods.year': :asc, 'period_types.name': :asc)}


  scope :valid_to_enroll_in, -> () {joins(:grade).where("grades.current_permanence_status": [:regular, :reincorporado, :articulo3], "grades.appointment_time": nil)}


  scope :sort_by_numbers_of_this_process, -> () {order(['enroll_academic_processes.efficiency': :desc, 'enroll_academic_processes.simple_average': :desc, 'enroll_academic_processes.weighted_average': :desc])}

  scope :without_academic_records, -> {joins(:academic_records).group(:"enroll_academic_processes.id").having('COUNT(*) = 0').count}

  scope :with_any_academic_records, -> {joins(:academic_records).group(:"enroll_academic_processes.id").having('COUNT(*) > 0').count}

  scope :with_n_academic_records, -> (n){joins(:academic_records).group(:"enroll_academic_processes.id").having('COUNT(*) = ?', n).count}
  
  scope :total_with_n_academic_records, -> (n){(with_n_academic_records(n)).count}

  scope :custom_search, -> (keyword) { joins(:user, :period).where("users.ci ILIKE '%#{keyword}%' OR periods.name ILIKE '%#{keyword}%'") }

  scope :with_payment_report, -> {joins(:payment_reports)}
  scope :total_with_payment_report, -> {with_payment_report.count}

  def total_retire?
    academic_records.any? and (academic_records.count.eql? academic_records.retirado.count)
  end

  # FUNCTIONS:

  def overlapped? schedule2
    # self.schedules.where(day: schedule2.day).each do |sh|
    self.schedules.where.not('academic_records.status': 3).where(day: schedule2.day).each do |sh|
      if ((sh.starttime&.to_i < schedule2&.endtime&.to_i) and (schedule2&.starttime&.to_i < sh.endtime&.to_i) )
        return true 
      end
    end
    return false
  end

  def self.type_label_by_enroll type
    # [:preinscrito, :reservado, :confirmado, :retirado]
    case type
    when 'preinscrito' 
      'info'
    when 'reservado' 
      'warning'
    when 'confirmado' 
      'success'
    else
      ''
    end
  end

  def get_regulation

    if PERMANENCE_STATUSES_SETEABLES.include? self.permanence_status&.to_sym
      return self.permanence_status.to_sym
    else
      reglamento_aux = :regular
      if !(self.grade.academic_records.qualified.any?)
        reglamento_aux = :nuevo
      elsif total_retire?
        reglamento_aux = :retiro_semestre
      elsif self.academic_records.sin_calificar.any?
        reglamento_aux = :por_calificar
      elsif self.academic_records.coursed.any?
        if coursed_but_not_approved_any?
          reglamento_aux = :articulo3
          iep_anterior = self.before_enrolled
          if iep_anterior&.coursed_but_not_approved_any?
            reglamento_aux = :articulo6
            iep_anterior2 = iep_anterior.before_enrolled
            if iep_anterior2&.coursed_but_not_approved_any?
              reglamento_aux = :articulo7
            end
          end
        end
      end
    end

    return reglamento_aux
  end

  def coursed_but_not_approved_any?
    self.academic_records.coursed.any? and !(self.academic_records.aprobado.any?)
  end
  def finished?
    academic_records.any? and (academic_records.count.eql? academic_records.qualified.count)
  end

  def before_enrolled
    
    if before_process = self.academic_process.process_before
      EnrollAcademicProcess.where(grade_id: self.grade_id, academic_process_id: before_process.id).first
    end
  end


  def any_permanence_articulo?
    (self.articulo3? or self.articulo6? or self.articulo7?)
  end

  def set_default_values_by_import
    self.enroll_status = :confirmado
    self.permanence_status = :regular
  end

  def enrolling?
    school.enroll_process_id.eql? academic_process_id  
  end

  def historical?
    !enrolling?
  end

  def resume_sections
    self.academic_records.includes(:section).map{|ar| ar.section.desc_subj_code}
  end

  def total_academic_records
    self.subjects.count
  end

  def total_subjects_not_retired
    subjects.where.not('academic_records.status': 3).count
  end

  def total_credits
    subjects.sum(:unit_credits)
  end

  def total_credits_not_retired
    subjects.where.not('academic_records.status': 3).sum(:unit_credits)
  end  

  def short_name
    "#{self.school.code}_#{self.period.name_revert}_#{self.student.user_ci}"
  end

  def name
    "(#{self.school.code}) #{self.period.name}:#{self.student.name}" if ( self.period and self.school and self.student)
  end

  def label_status
    # ["CO", "INS", "NUEVO", "PRE", "REINC", "RES", "RET", "VAL"] 
    case self.enroll_status
    when 'confirmado'
      label_color = 'success'
    when 'preinscrito'
      label_color = 'info'
    when 'retirado'
      label_color = 'danger'
    else
      label_color = 'secondary'
    end
    return ApplicationController.helpers.label_status("bg-#{label_color}", self.enroll_status&.titleize)
  end

  rails_admin do
    navigation_label 'Reportes'
    navigation_icon 'fa-solid fa-calendar-check'
    weight 0
    
    show do
      field :enrolling do
        label do 
          "INSCRIPCIÓN #{bindings[:object].period.name} de #{bindings[:object].user.reverse_name}"
        end
        visible do
          current_user = bindings[:view]._current_user
          (current_user and current_user.admin and current_user.admin.authorized_manage? 'EnrollAcademicProcess')
        end
        formatted_value do          
          grade = bindings[:object].grade          
          if bindings[:object].enrolling?
            totalCreditsReserved = bindings[:object].total_credits_not_retired
            totalSubjectsReserved = bindings[:object].total_subjects_not_retired

            bindings[:view].render(partial: '/enroll_academic_processes/form', locals: {grade: grade, academic_process: bindings[:object].academic_process, totalCreditsReserved: totalCreditsReserved, totalSubjectsReserved: totalSubjectsReserved})
          else
            bindings[:view].render(partial: "/academic_records/making_historical", locals: {enroll: bindings[:object]})
          end
        end
      end      
    end

    edit do
      fields :grade, :academic_process, :enroll_status, :permanence_status
    end

    list do
      search_by :custom_search
      # filters [:period_name, :student]
      scopes [:todos, :preinscrito, :reservado, :confirmado, :retiro_semestre]

      field :enroll_status_label do
        label 'Estado'
        column_width 100
        searchable :enroll_status
        filterable false
        sortable false
        formatted_value do
          bindings[:object].label_status
        end
      end

      field :period do
        label 'Período'
        column_width 100
        searchable :name
        # filterable 'periods.name'
        sortable :name
      end

      field :student do
        column_width 340
        # searchable ['users.ci', 'users.first_name', 'users.last_name']
        # filterable ['users.ci', 'users.first_name', 'users.last_name']
        # sortable ['users.ci', 'users.first_name', 'users.last_name']
      end
      field :total_subjects do
        label 'Tot Asig'
        column_width 40
      end

      field :total_credits do
        label 'Tot Cred'
        column_width 40
      end

      field :areas do
        label 'Áreas'
        column_width 100
        filterable true
      end

      field :created_at do
        label 'Fecha de Inscripción'
        searchable false
      end

      field :permanence_status do
        pretty_value do
          bindings[:object].label_permanence_status
        end
      end

      field :payment_reports do
        # filterable true #"joins(:payment_reports).count"
        # queryable true
        associated_collection_cache_all false
        associated_collection_scope do

          Proc.new { |scope|
            scope = scope.joins(:payment_reports)
            scope = scope.limit(30)
          }
        end        
      end
      fields :efficiency, :simple_average, :weighted_average
    end

    export do
      fields :enroll_status, :permanence_status, :grade, :study_plan

      field :period do
        label 'Período'
        column_width 100
        searchable :name
        # filterable 'periods.name'
        sortable :name
      end

      fields :student, :user

      field :efficiency do
        label 'Edifiencia en el Período'
      end
      
      field :simple_average do
        label 'Promedio en el Período'
      end
      field :weighted_average do
        label 'Ponderado en el Período'
      end

      field :resume_sections do
        label 'Resumen Asignaturas del Periodo'
      end
      field :total_subjects do
        label 'Total Asignaturas en Periodo'
      end
      field :total_credits do
        label 'Total Créditos en Periodo'
      end
      field :payment_reports do
        label 'Reporte de Pago'
      end

      fields :efficiency, :simple_average, :weighted_average

    end
  end

  def is_the_last_enroll_of_grade?
    self.grade.last_enrolled.eql? self
  end

  def is_the_first_enroll_of_grade?
    self.grade.first_enrolled.eql? self
  end
  
  def is_unique_enroll_of_grade?
    self.grade.enroll_academic_processes.count.eql? 1
  end


  private

    def update_grade
      if is_unique_enroll_of_grade?
        grade.update(start_process_id: self.academic_process_id, current_permanence_status: self.permanence_status) 
      elsif is_the_first_enroll_of_grade?
        grade.update(start_process_id: self.academic_process_id)
      elsif is_the_last_enroll_of_grade?
        grade.update(current_permanence_status: self.permanence_status)
      end
    end

    def paper_trail_update
      changed_fields = self.changes#.keys - ['created_at', 'updated_at']
      changed_fields = changed_fields.map do |fi|
        if fi[0] != 'updated_at'
          elem = I18n.t("activerecord.attributes.#{self.model_name.param_key}.#{fi[0]}").to_s
          elem += " de #{fi[1][0]} a #{fi[1][1]}"
        end
      end
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} actualizada en: #{changed_fields.to_sentence}"
    end  
    def paper_trail_create
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} registrado!"
    end  

    def paper_trail_destroy
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡Proceso Académico eliminado!"
    end


end
