class EnrollAcademicProcess < ApplicationRecord
  # SCHEMA:
  # t.bigint "grade_id", null: false
  # t.bigint "academic_process_id", null: false
  # t.integer "enroll_status"
  # t.integer "permanence_status"

  # ASSOCIATIONS:
  belongs_to :grade
  has_one :student, through: :grade
  has_one :user, through: :student
  has_one :school, through: :grade
  
  belongs_to :academic_process
  has_one :period, through: :academic_process
  has_many :payment_reports, as: :payable
  has_many :academic_records

  # ENUMERIZE:
  enum enroll_status: [:preinscrito, :reservado, :confirmado, :retirado]
  enum permanence_status: [:nuevo, :regular, :reincorporado, :articulo3, :articulo6, :articulo7]  

  # VALIDATIONS:
  validates :grade, presence: true
  validates :academic_process, presence: true
  validates :enroll_status, presence: true
  # validates :permanence_status, presence: true

  # SCOPE:
  scope :of_academic_process, -> (academic_process_id) {where(academic_process_id: academic_process_id)}

  scope :without_academic_records, -> {joins(:academic_records).group(:"enroll_academic_processes.id").having('COUNT(*) = 0').count}

  scope :with_any_academic_records, -> {joins(:academic_records).group(:"enroll_academic_processes.id").having('COUNT(*) > 0').count}

  scope :with_i_academic_records, -> (i){joins(:academic_records).group(:"enroll_academic_processes.id").having('COUNT(*) = ?', i).count}
  
  scope :total_with_i_academic_records, -> (i){(joins(:academic_records).group(:"enroll_academic_processes.id").having('COUNT(*) = ?', i).count).count}

  # FUNCTIONS:
  def set_default_values_by_import
    self.enroll_status = :confirmado
    self.permanence_status = :regular
  end

  def total_academic_records
    self.academic_records.count
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
    return ApplicationController.helpers.label_status("bg-#{label_color}", self.enroll_status.titleize)

  end  

  rails_admin do
    navigation_label 'Inscripciones'
    navigation_icon 'fa-solid fa-calendar-check'

    list do
      # filters [:student, :period, :enroll_status, :permanence_status, :created_at]
      fields :enroll_status#, :permanence_status

      field :student do
        searchable :name
        filterable :name
        sortable :name
      end

      field :period do
        searchable :name
        filterable :name
        sortable :name
      end
      field :total_academic_records do
        label 'Total Asignaturas Inscritas'
      end

      field :created_at do
        label 'Fecha de Inscripci??n'
      end
    end

    edit do
      fields :grade, :academic_process, :enroll_status#, :permanence_status
    end

    export do
      fields :enroll_status, :permanence_status, :grade, :academic_process, :student, :user
    end
  end

end
