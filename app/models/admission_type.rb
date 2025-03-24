class AdmissionType < ApplicationRecord
  # SCHEMA:
  # t.string "name"
  # t.bigint "school_id", null: false

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

  #ASSOCIATIONS:
  has_many :grades, dependent: :destroy
  has_many :students, through: :grades

  #VALIDATIONS:
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  rails_admin do
    navigation_label 'Config General'
    navigation_icon 'fa-regular fa-user-tag'
    weight -1

    list do
      field :name
      field :code

      field :total_students do
        label 'Total Estudiantes'
      end

      field :created_at
    end

    show do
      field :name
      field :code
    end

    edit do
      field :name
      field :code do
        html_attributes do
          {length: 4, size: 4, onInput: "$(this).val($(this).val().replace(/[^0-9]/g,''))"}
        end
        help 'Sólo 4 dígitos numéricos permitidos' 
      end
    end

    export do
      fields :name
      fields :code
    end
  end

  def total_students
    students.count
  end

  private


    def paper_trail_update
      # changed_fields = self.changes.keys - ['created_at', 'updated_at']
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      # self.paper_trail_event = "¡#{object} actualizado en #{changed_fields.to_sentence}"
      self.paper_trail_event = "¡#{object} actualizado!"
    end  

    def paper_trail_create
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} registrado!"
    end  

    def paper_trail_destroy
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡Tipo de Admisión eliminado!"
    end
end
