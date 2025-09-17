class Teacher < ApplicationRecord
  include Userable
  # SCHEMA:
  # t.bigint "area_id", null: false

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

  # ASSOCIATIONS:
  belongs_to :user
  # accepts_nested_attributes_for :user

  belongs_to :area
  # accepts_nested_attributes_for :area
  # has_and_belongs_to_many :secondary_teachers, class_name: 'SectionTeacher'

  has_many :sections

  # SCOPES:
  scope :find_by_user_ci, -> (ci) {joins(:user).where('users.ci': ci).first}
  # SCOPES:
  scope :custom_search, -> (keyword) { joins(:user).where("users.ci ILIKE '%#{keyword}%' OR users.email ILIKE '%#{keyword}%' OR users.first_name ILIKE '%#{keyword}%' OR users.last_name ILIKE '%#{keyword}%'") }  

  # VALIDATIONS:
  validates :area, presence: true
  validates :user, presence: true, uniqueness: true

  def desc
    "(#{user.ci}) #{user.reverse_name}" if user
  end

  # CALLBACKS:
  after_destroy :check_user_for_destroy
  
  # HOOKS:
  def check_user_for_destroy
    user_aux = User.find self.user_id
    user_aux.delete if user_aux.without_rol?
  end  

  def description
    if user
      aux = user.description
      aux += " - #{area.name}" if area
    else
      aux = 'Sin descripción'
    end
    return aux
  end



  rails_admin do
    navigation_label 'Gestión de Usuarios'
    navigation_icon 'fa-regular fa-chalkboard-user'

    list do
      search_by :custom_search
      field :user_ci do
        label 'Cédula'
        # sortable 'joins(:user).users.ci'
        # queryable "course_periods_periods.name"
      end

      field :user_last_name do
        label 'Apellidos'
      end
      field :user_first_name do
        label 'Nombres'
      end
      field :user_phone do
        label 'Número Telefónico'
      end
      field :user_email do
        label 'Email'
      end 

      field :area
    end

    show do
      fields :user, :area

      field :sections do
        pretty_value do
          bindings[:view].render(partial: '/sections/index', locals: {sections: bindings[:object].sections.joins(:period).order('periods.name': :desc)})
        end
      end
    end

    edit do
      fields :user
      fields :area do
        inline_edit false
        inline_add false
      end
    end

    export do
      fields :user, :area, :sections, :created_at
    end

    import do
      fields :user_id, :area_id
    end
  end

  def user_ci
    user.ci if user
  end

  def user_last_name
    user.last_name if user
  end
  def user_first_name
    user.first_name if user
  end 
  def user_phone
    user.number_phone if user
  end 
  def user_email
    user.email if user
  end

  private

  def self.import row, fields

    total_newed = total_updated = 0
    no_registred = ""
    if area = Area.find(fields['area_id'])

      if row[0]
        row[0].strip!
        row[0].delete! '^0-9'
      else
        return [0,0,0]
      end
      
      usuario = User.find_or_initialize_by(ci: row[0])
      
      if row[1]
        row[1].strip!
        usuario.email = row[1].remove("mailto:")
      else
        return [0,0,1]
      end

      if row[2]
        row[2].strip!
        usuario.first_name = row[2]
      else
        return [0,0,2]
      end

      if row[3]
        row[3].strip!
        usuario.last_name = row[3] if row[3]
      else
        return [0,0,3]
      end

      if row[4]
        row[4].strip!
        row[4].delete! '^A-Za-z'
        row[4] = :Masculino if row[4][0].upcase.eql? 'M'
        row[4] = :Femenino if row[4][0].upcase.eql? 'F'
        usuario.sex = row[4] 
      end

      usuario.number_phone = row[5] if row[5]
      
      nuevo = usuario.new_record?

      if usuario.save 
        profesor = Teacher.find_or_initialize_by(user_id: usuario.id)
        profesor.area_id = area.id

        nuevo = profesor.new_record?

        if profesor.save
          if nuevo
            total_newed = 1
          else
            total_updated = 1
          end
        else
          no_registred = row
        end
      else
        p "     #{usuario.errors.full_messages.to_sentence  } ... #{usuario.attributes}   ".center(500, "$")
        no_registred = row
      end
    else
        no_registred = 'Área no encontrada'
    end
    [total_newed, total_updated, no_registred]    
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
      self.paper_trail_event = "¡Docente eliminado!"
    end


end
