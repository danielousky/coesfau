class Course < ApplicationRecord
  # SCHEMA:
  # t.bigint "academic_process_id", null: false
  # t.bigint "subject_id", null: false
  # t.boolean "offer_as_pci"
  # t.string "name"
  # Course.all.map{|ap| ap.update(name: 'x')}  
  # HISTORY:

  attr_accessor :session_academic_process_id

	has_paper_trail on: [:create, :destroy, :update]

	before_create :paper_trail_create
	before_destroy :paper_trail_destroy
	before_update :paper_trail_update

  # ASSOCIATIONS:
  # belongs_to
  belongs_to :academic_process
  has_one :period, through: :academic_process
  has_one :school, through: :academic_process
  belongs_to :subject
  has_one :area, through: :subject
  
  # has_many
  has_many :sections, dependent: :destroy
  has_many :academic_records, through: :sections

  #VALIDATIONS:
  validates :subject, presence: true
  validates :academic_process, presence: true

  validates_uniqueness_of :subject_id, scope: [:academic_process_id], message: 'Ya existe la asignatura para el proceso académico.', field_name: false

  # SCOPE
  scope :of_academic_process, ->(academic_process_id){where(academic_process_id: academic_process_id)}
  scope :pcis, -> {where(offer_as_pci: true)}
  scope :order_by_subject_ordinal, -> {joins(:subject).order('subjects.ordinal': :asc)}
  scope :order_by_subject_code, -> {joins(:subject).order('subjects.code': :asc)}

  scope :custom_search, -> (keyword) {joins(:period, :subject).where("subjects.name ILIKE '%#{keyword}%' OR subjects.code ILIKE '%#{keyword}%' OR periods.name ILIKE '%#{keyword}%'") }
  # default_scope {of_academic_process(@academic_process.id)}

  # ORIGINAL CON LEFT JOIN
  # scope :without_sections, -> {joins("LEFT JOIN sections s ON s.course_id = courses.id").where(s: {course_id: nil})}
  
  # OPTIMO CON LEFT OUTER JOIN
  scope :without_sections, -> {left_joins(:sections).where('sections.course_id': nil)}


  # CALLBACKS:
  before_save :set_name

  def get_name
    "#{self.academic_process.name}-#{self.subject.desc}" if self.period and self.school and self.subject
  end

  def qualifications_average
    if total_academic_records > 0
      values = academic_records.joins(:qualifications).sum('qualifications.value')
      (values.to_f/total_academic_records.to_f).round(2)
    end
  end

  def total_sections
    sections.count
  end

  def total_academic_records
    academic_records.count
  end

  def newers
    academic_records.joins(:enroll_academic_process).where("enroll_academic_processes.permanence_status = ?", 0)
  end
  def total_new
    newers.count
  end

  def total_new_sc
    newers.sin_calificar.count
  end

  def total_new_aprobados
    newers.not_perdida_por_inasistencia.aprobado.count
  end

  def total_new_aplazados
    newers.not_perdida_por_inasistencia.aplazado.count
  end

  def total_new_retirados
    newers.retirado.count
  end

  def total_new_pi
    newers.perdida_por_inasistencia.count
  end
  
  def total_sc
    academic_records.sin_calificar.count
  end

  def total_aprobados
    academic_records.not_perdida_por_inasistencia.aprobado.count
  end

  def total_aplazados
    academic_records.not_perdida_por_inasistencia.aplazado.count
  end

  def total_retirados
    academic_records.retirado.count
  end

  def total_pi
    academic_records.perdida_por_inasistencia.count
  end 

  def subject_desc_with_pci
    if offer_as_pci
      self.subject.description_code_with_school
    else
      self.subject.description_code
    end
  end

  def curso_name
    "Curso #{self.name}"
  end

  rails_admin do
    # visible false
    navigation_label 'Reportes'
    navigation_icon 'fa-solid fa-shapes'
    weight -2

    object_label_method do
      :curso_name
    end


    list do
      sort_by ['courses.name']
      search_by :custom_search
      field :academic_process do
        queryable true
        label 'Periodo'
        column_width 100
        pretty_value do
          value.period.name
        end
      end
      field :area do
        searchable :name
        sortable :name
      end
      field :subject do
        filterable false
      end
      field :total_sections do
        label "T. Sec"
        pretty_value do
          ApplicationController.helpers.label_status('bg-info', value)
        end
      end

      field :sections do
        column_width '300'
        pretty_value do
          bindings[:object].sections.map{|sec| ApplicationController.helpers.link_to(sec.code, "/admin/section/#{sec.id}")}.to_sentence.html_safe
        end
      end
      field :total_academic_records do
        label 'Ins'
        pretty_value do
          # %{<a href='/admin/academic_record?query=#{bindings[:object].name}'><span class='badge bg-info'>#{ApplicationController.helpers.label_status('bg-info', value)}</span></a>}.html_safe
          ApplicationController.helpers.label_status('bg-info', value)

        end
      end

      field :total_new do
        label 'Nue'
        pretty_value do
          ApplicationController.helpers.label_status('bg-info', value)

        end
      end

      field :total_sc do
        label 'SC'
        help 'Sin Calificar'
        pretty_value do
          ApplicationController.helpers.label_status('bg-secondary', value)
        end
      end

      field :total_new_sc do
        label 'SC Nue'
      end
      
      field :total_aprobados do
        label 'A'
        help 'Aprobado'
        pretty_value do
          ApplicationController.helpers.label_status('bg-success', value)
        end
      end
      
      field :total_new_aprobados do
        label 'A Nue'
        help 'Aprobado Nuevos'
        pretty_value do
          ApplicationController.helpers.label_status('bg-success', value)
        end
      end
      field :total_aplazados do
        label 'AP'
        pretty_value do
          ApplicationController.helpers.label_status('bg-danger', value)
        end        
      end
      field :total_new_aplazados do
        label 'AP Nue'
        help 'Aplazado Nuevos'
        pretty_value do
          ApplicationController.helpers.label_status('bg-danger', value)
        end
      end

      field :total_retirados do
        label 'RT'
        pretty_value do
          ApplicationController.helpers.label_status('bg-secondary', value)
        end        
      end 
      field :total_new_retirados do
        label 'RT Nue'
        help 'Retirados Nuevos'
        pretty_value do
          ApplicationController.helpers.label_status('bg-secondary', value)
        end
      end

      field :total_pi do
        label 'PI'
        pretty_value do
          ApplicationController.helpers.label_status('bg-danger', value)
        end        
      end
      
      field :total_new_pi do
        label 'PI Nue'
        help 'Perdida por Inasistencia Nuevos'
        pretty_value do
          ApplicationController.helpers.label_status('bg-danger', value)
        end
      end
      field :qualifications_average do
        label 'Prom'
        pretty_value do
          ApplicationController.helpers.label_status('bg-info', value)
        end         
      end      
    end

    show do
      fields :academic_process, :subject
      field :sections do
        pretty_value do
          bindings[:view].render(partial: "/sections/index", locals: {sections: bindings[:object].sections, course_id: bindings[:object].id, section_codes: bindings[:object].subject.section_codes})
        end
      end
    end

    edit do
      field :academic_process do
        inline_edit false
        inline_add false        
      end

      field :subject do
        inline_edit false
        inline_add false        
      end
      field :sections
    end

    export do
      fields :academic_process, :period, :subject, :area
      field :total_sections do
        label 'Total Sec'
      end
      field :total_academic_records do
        label 'Inscritos'
      end

      field :total_new do
        label 'Inscritos Nuevos'
      end

      field :total_new_sc do
        label 'Sin Calificar Nuevos'
      end

      field :total_sc do
        label 'Sin Calificar'
      end
      field :total_aprobados do
        label 'Aprobado'
      end
      field :total_new_aprobados do
        label 'Arpobados Nuevos'
      end
      field :total_aplazados do
        label 'Aplazados'
      end
      field :total_new_aplazados do
        label 'Aplazados Nuevos'
      end

      field :total_retirados do
        label 'Retirados'
      end 
      field :total_new_retirados do
        label 'Retirados Nuevos'
      end

      field :total_pi do
        label 'PI'
      end 
      field :total_new_pi do
        label 'PI Nuevos'
      end
      field :qualifications_average do
        label 'Promedio'
      end

    end


  end
  
  private
    def set_name
      self.name = self.get_name
    end

    def paper_trail_update
      changed_fields = self.changes.keys - ['created_at', 'updated_at']
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} actualizado en #{changed_fields.to_sentence}"
    end  

    def paper_trail_create
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} creado!"
    end  

    def paper_trail_destroy
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡Curso eliminado!"
    end
end
