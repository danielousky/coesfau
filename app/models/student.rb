class Student < ApplicationRecord

  # SCHEMA:
  # t.boolean "active", default: true
  # t.integer "disability"
  # t.integer "nacionality"
  # t.integer "marital_status"
  # t.string "origin_country"
  # t.string "origin_city"
  # t.date "birth_date"  

  # GLOBALS VARIABLES:
  ESTADOS_CIVILES = ['Soltero/a', 'Casado/a', 'Concubinato', 'Divorciado/a', 'Viudo/a']
  NACIONALIDAD = ['Venezolano/a', 'Venezolano/a Nacionalizado/a', 'Extranjero/a']

  DISCAPACIDADES = ['Sensorial Visual', 'Sensorial Auditiva', 'Motora Miembros Inferiores', 'Motora Medios Superiores', 'Motora Ambos Miembros']

  enum nacionality: NACIONALIDAD
  enum disability: DISCAPACIDADES
  enum marital_status: ESTADOS_CIVILES

  # ASSOCIATIONS:
  has_paper_trail
  #belons_to
  belongs_to :user
  # accepts_nested_attributes_for :user
  # has_one
  has_one :location
  # has_many
  has_many :grades
  accepts_nested_attributes_for :grades

  has_many :study_plans, through: :grades
  has_many :admission_types, through: :grades


  # VALIDATIONS:
  validates :user, presence: true, uniqueness: true
  # validates :nacionality, presence: true, unless: :new_record?
  # validates :marital_status, presence: true, unless: :new_record?
  # validates :origin_country, presence: true, unless: :new_record?
  # validates :origin_city, presence: true, unless: :new_record?
  # validates :birth_date, presence: true, unless: :new_record?
  # validates :location, presence: true, unless: :new_record?
  # validates :grades, presence: true
  # How to validate if student is not created for assosiation

  # SCOPES:
  scope :custom_search, -> (keyword) { joins(:user).where("users.ci ILIKE '%#{keyword}%' OR users.email ILIKE '%#{keyword}%' OR users.first_name ILIKE '%#{keyword}%' OR users.last_name ILIKE '%#{keyword}%' OR users.number_phone ILIKE '%#{keyword}%'") }

  scope :find_by_user_ci, -> (ci) {joins(:user).where('users.ci': ci).first}

  # CALLBACKS:
  after_destroy :check_user_for_destroy
  
  # HOOKS:
  def check_user_for_destroy
    user_aux = User.find self.user_id
    user_aux.delete if user_aux.without_rol?
  end


  # FUNCTIONS:

  def name
    user.description if user
  end

  def user_ci
    self.user.ci if self.user
  end

  # CALLBACKS:
  # HOOKS:

  # IMPORT:

  def self.before_import_find(record)
    if (ci = record[:ci])
      if (user = User.find_by_ci(ci))
        user.update(first_name: record[:first_name], last_name: record[:last_name], email: record[:email])
      else
        user = User.create(ci: record[:ci], first_name: record[:first_name], last_name: record[:last_name], email: record[:email])
      end
      self.user_id = user.id
    end 
    p "ESTOY AQUI 01"


    # if (study_plan = StudyPlan.find_by_code(record[:study_plan_code]) && admission_type = AdmissionType.find_by_code(record[:admission_type_name]))
    #   p "ESTOY AQUIIIIIII"
    #   self.grades.create(study_plan_id: study_plan.id, admission_type_id: admission_type.id)
    # end      
  end

  def after_import_save(record)
    if (study_plan = StudyPlan.find_by_code(record[:study_plan_code]) && admission_type = AdmissionType.find_by_code(record[:admission_type_name]))
      self.grades.create(study_plan_id: study_plan.id, admission_type_id: admission_type.id)
    end  
  end

  # def before_import_save(record)
  #   if (ci = record[:ci])
  #     if (user = User.find_by_ci(ci))
  #       user.update(record[:user])
  #     else
  #       user = User.create(record[:user])
  #     end
  #     self.user_id = user.id
  #   end
  # end

  # def before_import_save(record)
  #     self.user_id = record[:user_id]
  #     self.ci = record[:ci]
  # end
  # def before_import_save(row, map)
  #   self.created_nested_items(row, map)
  # end  
  
  rails_admin do
    navigation_label 'Gestión de Usuarios'
    navigation_icon 'fa-regular fa-user-graduate'

    edit do
      # field :user do
      #   # searchable :full_name
      # end
      field :user
      # field :nacionality do
      #   formatted_value do 
      #     value.to_s.upcase
      #   end
      # end

      field :grades do
        # inline_add false
        associated_collection_scope do
          student = bindings[:object]

          proc { |scope| scope.where(student_id: student.id) }
        end
      end

      fields :nacionality, :origin_country, :origin_city, :birth_date, :marital_status, :location

    end

    show do

      fields :user, :grades, :nacionality, :origin_country, :origin_city, :birth_date, :marital_status, :location, :created_at
    end

    list do
      search_by :custom_search
      fields :user, :study_plans, :origin_city, :birth_date, :marital_status, :created_at
    end

    export do
      fields :user, :nacionality, :origin_country, :origin_city, :birth_date, :marital_status, :location, :created_at
    end

    import do
      field :ci
      field :email
      field :first_name
      field :last_name
      field :study_plan_code
      field :admission_type_name

      # mapping_key_list ['user[ci]', 'user[email]', 'user[first_name]','user[last_name]']
      # mapping_key_list ['ci', 'email', 'first_name','last_name']
    end

  end


  def self.import row, fields

    total_newed = total_updated = 0
    no_registred = nil

    if row[0]
      row[0].strip!
      row[0].delete! '^0-9'
    else
      return [0,0,0]
    end
    
    usuario = User.find_or_initialize_by(ci: row[0])
    
    if row[1]
      row[1].strip!
      usuario.email = row[1]
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
      row[4] = :masculino if row[4].upcase.eql? 'M'
      row[4] = :femenino if row[4].upcase.eql? 'F'
      usuario.sex = row[4] 
    end

    usuario.number_phone = row[5] if row[5]

    if usuario.save
      estudiante = Student.find_or_initialize_by(user_id: usuario.id)

      if estudiante.save
        grado = Grade.find_or_initialize_by(student_id: estudiante.id, study_plan_id: fields[:study_plan_id])
        grado.admission_type_id = fields[:admission_type_id]
        grado.registration_status = fields[:registration_status]
        nuevo_grado = grado.new_record?

        if grado.save
          if nuevo_grado
            total_newed = 1
          else
            total_updated = 1
          end
        else
          no_registred = row
        end
      else
        no_registred = row
      end
    else
      no_registred = row
    end

    [total_newed, total_updated, no_registred]
  end


end
