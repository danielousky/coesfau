class School < ApplicationRecord
  # SCHEMA:
  # t.string "code", null: false
  # t.string "name", null: false
  # t.integer "type_entity", default: 0, null: false
  # t.boolean "enable_subject_retreat"
  # t.boolean "enable_change_course"
  # t.boolean "enable_dependents"
  # t.bigint "active_process_id"
  # t.bigint "enroll_process_id"
  # t.datetime "created_at", null: false
  # t.datetime "updated_at", null: false
  # t.bigint "faculty_id"
  # t.string "contact_email", default: "coes.fau@gmail.com", null: false

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update
  
  # ASSOCIATIONS
  belongs_to :active_process, foreign_key: 'active_process_id', class_name: 'AcademicProcess', optional: true
  belongs_to :enroll_process, foreign_key: 'enroll_process_id', class_name: 'AcademicProcess', optional: true

  belongs_to :faculty

  has_many :bank_accounts, dependent: :destroy
  accepts_nested_attributes_for :bank_accounts, allow_destroy: true

  has_many :academic_processes
  has_many :areas, dependent: :destroy
  has_many :study_plans, dependent: :destroy
  has_many :grades, through: :study_plans
  accepts_nested_attributes_for :study_plans

  has_many :subjects, through: :areas
  has_many :periods, through: :academic_processes
  has_many :admins, as: :env_authorizable 

  # accepts_nested_attributes_for :areas, :academic_processes, :admission_types

  # ENUMERATIONS:
  enum type_entity: [:pregrado, :postgrado, :extension, :investigacion]

  # VALIDATIONS
  validates :type_entity, presence: true
  validates :code, presence: true, uniqueness: {case_sensitive: false}
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :contact_email, presence: true

  # CALLBAKCS:
  # after_initialize :set_unique_faculty
  before_save :clean_name_and_code

  # HOOKS:

  def clean_name_and_code
    self.name.delete! '^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ '
    self.name.strip!
    self.name.upcase!

    self.code.delete! '^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ'
    self.code.strip!
    self.code.upcase!
  end

  def set_unique_faculty
    self.faculty_id = Faculty.first.id if Faculty.count.eql? 1
  end

  # FUNCTIONS:
  def all_grades_to_csv

    CSV.generate do |csv|
      csv << ['Cédula', 'Apellido y Nombre', 'Sede', 'Eficiencia', 'Promedio', 'Ponderado', 'Última Calificación']
      grades.all.each do |grade|
        user = grade.user
        csv << [user.ci, user.reverse_name, grade.student.sede, grade.efficiency, grade.simple_average, grade.weighted_average, grade.academic_records.last&.get_value_by_status]
      end
    end
  end


  def enroll_period_name
    self.enroll_process ? self.enroll_process.name : 'Inscripción Cerrada'
  end

  def short_name
    self.name.split(" ")[2] if self.name
  end


  def modalities
    academic_processes.map{|ap| ap.modality}.uniq.to_sentence if academic_processes.any?
  end

  def description
    "#{self.code}: #{self.name}. (#{self.faculty.name}) #{self.type_entity.titleize}"
  end

  def enable_dependents?
    (enable_dependents.eql? true)
  end


  rails_admin do
    navigation_label 'Config General'
    navigation_icon 'fa-regular fa-school'
    weight -3
    # visible false


    list do
      checkboxes false
      field :code do
        sortable false
        queryable false
        filterable false
        searchable false
      end

      field :name do
        sortable false
        queryable false
        filterable false
        searchable false
        pretty_value do
          bindings[:object].short_name
        end
      end

      field :enable_dependents do
        label '¿Prelaciones?'
        queryable false
        filterable false
        searchable false
        sortable false
        sortable false
        pretty_value do

          current_user = bindings[:view]._current_user
          admin = current_user.admin
          active = admin and admin.authorized_manage? 'School'

          if active
            bindings[:view].render(partial: "/schools/form_dependents", locals: {school: bindings[:object]})
          else
            value
          end
        end

      end

      field :enable_enroll_payment_report do
        label '¿Permitir Reportes de Pago?'
        queryable false
        filterable false
        searchable false
        sortable false
        sortable false
        pretty_value do

          current_user = bindings[:view]._current_user
          admin = current_user.admin
          active = admin&.authorized_manage? 'School'

          if active
            bindings[:view].render(partial: "/schools/form_enroll_payment_reports", locals: {school: bindings[:object]})
          else
            value
          end
        end
      end

      fields :enroll_process do
        label 'Período Inscripción'
        queryable false
        filterable false
        searchable false
        sortable false
        help ''

        html_attributes do
          {'data-bs-original-title': ''}
        end
        pretty_value do

          current_user = bindings[:view]._current_user
          admin = current_user.admin
          active = admin and admin.authorized_manage? 'School'

          if active
            bindings[:view].render(partial: "/schools/form_enabled_enroll", locals: {school: bindings[:object]})
          end
        end

      end
      fields :active_process do
        label 'Período Activo'
        queryable false
        filterable false
        searchable false
        sortable false

        pretty_value do

          current_user = bindings[:view]._current_user
          admin = current_user.admin
          active = admin and admin.authorized_manage? 'School'

          if active
            bindings[:view].render(partial: "/schools/form_enabled_active", locals: {school: bindings[:object]})
          else
            value
          end
        end
      end

      field :download_all_grades do
        label 'Total Estudiantes'

        pretty_value do
          if bindings[:view]._current_user&.admin&.yo?
            bindings[:view].render(partial: "/schools/all_grades_link", locals: {school: bindings[:object]})
          else
            ApplicationController.helpers.label_status('bg-info', bindings[:object].grades.count)
          end
        end
      end 
    end

    show do

      field :description

      field :enable_prelations do
        label '¿Prelaciones?'
        formatted_value do
          current_user = bindings[:view]._current_user
          admin = current_user.admin
          active = admin and admin.authorized_manage? 'School'

          if active
            bindings[:view].render(partial: "/schools/form_dependents", locals: {school: bindings[:object]})
          else
            value
          end
        end
      end

      field :enable_payment_report do
        label '¿Permitir Reportes de Pago?'
        formatted_value do
          current_user = bindings[:view]._current_user
          admin = current_user.admin
          active = admin&.authorized_manage? 'School'

          if active
            bindings[:view].render(partial: "/schools/form_enroll_payment_reports", locals: {school: bindings[:object]})
          else
            value
          end
        end
      end

      field :process_active do
        label 'Período Activo'

        formatted_value do
          bindings[:view].render(partial: "/schools/form_enabled_active", locals: {school: bindings[:object]})
        end
      end

      field :process_enroll do
        label 'Período Inscripción'
        help 'Esta acción modificará la posibilidad de inscribirse a los estudiantes. Para cerrar la inscripción seleccione "Inscripción Cerrada"'
        formatted_value do
          bindings[:view].render(partial: "/schools/form_enabled_enroll", locals: {school: bindings[:object]})
        end
      end

      # field :download_all_grades do
      #   label 'Total Estudiantes'

      #   formatted_value do
      #     if bindings[:view]._current_user&.admin&.yo?
      #       bindings[:view].render(partial: "/schools/all_grades_link", locals: {school: bindings[:object]})
      #     else
      #       ApplicationController.helpers.label_status('bg-info', bindings[:object].grades.count)
      #     end
      #   end
      # end 

    end

    edit do


      field :code do
        read_only true

      end
      field :name do
        read_only true

      end

      field :bank_accounts do
      end

      fields :contact_email, :boss_name
    end

    export do
      fields :code, :name, :type_entity
    end
  end

  private


    def paper_trail_update
      # changed_fields = self.changes.keys - ['created_at', 'updated_at']
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      # self.paper_trail_event = "¡#{object} actualizado en #{changed_fields.to_sentence}"
      self.paper_trail_event = "#{object} actualizada."
    end  

    def paper_trail_create
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} registrada!"
    end  

    def paper_trail_destroy
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡Escuela eliminada!"
    end

end
