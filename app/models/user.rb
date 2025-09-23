class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable, :trackable, :timeoutable


  # SCHEMA:
  # t.string "email", default: "", null: false
  # t.string "ci", null: false
  # t.string "encrypted_password", default: "", null: false
  # t.string "name"
  # t.string "last_name"
  # t.string "number_phone"
  # t.integer "sex"
  # t.datetime "remember_created_at"
  # t.integer "sign_in_count", default: 0, null: false
  # t.datetime "current_sign_in_at"
  # t.datetime "last_sign_in_at"
  # t.string "current_sign_in_ip"
  # t.string "last_sign_in_ip"  

  # ENUMERIZE:
  enum sex: [:Femenino, :Masculino]

  # VALIDATION PASSWORD:
  before_update :set_updated_password

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]
  
  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

  after_create :send_welcome_email

  # ASSOCIATIONS:
  has_one :admin, inverse_of: :user, foreign_key: :user_id, dependent: :destroy
  accepts_nested_attributes_for :admin
  
  has_one :student, inverse_of: :user, foreign_key: :user_id, dependent: :destroy
  accepts_nested_attributes_for :student

  has_one :teacher, inverse_of: :user, dependent: :destroy
  accepts_nested_attributes_for :teacher

  has_one_attached :profile_picture do |attachable|
    attachable.variant :icon, resize_to_limit: [35, 35]
    attachable.variant :thumb, resize_to_limit: [100, 100]
  end

  def profile_picture_as_thumb
    begin
      profile_picture.variant(resize_to_limit: [100, 100]).processed
    rescue Exception => e
      
    end
  end

  def ci_image_as_thumb
    begin
      ci_image.variant(resize_to_limit: [100, 100]).processed
    rescue Exception => e
    end
  end  

  attr_accessor :remove_profile_picture
  after_save { profile_picture.purge if remove_profile_picture.eql? '1' } 

  has_one_attached :ci_image do |attachable|
    attachable.variant :thumb, resize_to_limit: [100,100]
  end

  attr_accessor :remove_ci_image
  after_save { ci_image.purge if remove_ci_image.eql? '1' } 

  # attr_accessor :allow_blank_password

  # VALIDATIONS:
  validates :ci, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: {case_sensitive: false}
  validates :first_name, presence: true#, unless: :new_record?
  validates :last_name, presence: true#, unless: :new_record?
  validates_format_of :email, with: URI::MailTo::EMAIL_REGEXP

  # validates :profile_picture , presence: true, on: :update, if: lambda{ |object| (object.profile_picture.present? or object.ci_image.present?)}
  
  # validates :ci_image , presence: true, on: :update, if: lambda{ |object| (object.profile_picture.present? or object.ci_image.present?)}

  # validates :number_phone, presence: true, on: :update, unless: lambda{ |object| (object.profile_picture.present? and object.ci_image.present?)}

  # validates :sex, presence: true, on: :update, unless: lambda{ |object| (object.profile_picture.present? and object.ci_image.present?)}
  
  # validates :password_confirmation, presence: true, on: :update, if: lambda{ |object| (object.password.present?)}
  # validates :password, presence: true, confirmation: true, on: :update, if: lambda{ |object| !(object.profile_picture.present? or object.ci_image.present?)}
  
  # attr_accessor :password_confirmation

  # SCOPES:
  scope :my_search, -> (keyword) {where("ci ILIKE '%#{keyword}%' OR email ILIKE '%#{keyword}%' OR first_name ILIKE '%#{keyword}%' OR last_name ILIKE '%#{keyword}%' OR number_phone ILIKE '%#{keyword}%'") }

  # CALLBACKS:
  # before_create :set_default_values#, if: :new_record?

  before_validation(on: :create) do
    self.password ||= self.ci #if self.password.blank?
    self.email = "temp#{self.ci}@mailinator.com" if self.email.blank? and attribute_present?("ci")
    
  end

  before_validation :set_clean_values
  # HOOKS:
  def after_import_save(record)
    # called on the model after it is saved
    p "<   #{record}   >".center(200, "-") 
  end

  def set_clean_values
    # self.password ||= self.ci 
    self.clean_names if (first_name and last_name)
    self.ci&.delete! '^0-9'
    self.clean_phone if number_phone
    self.clean_email if email
  end

  def clean_email
    self.email.strip!
    self.email.downcase!
    self.email&.remove!("mailto:")
    self.email.delete! '^A-Za-z|0-9|@. '
  end

  def clean_phone
    self.number_phone.strip!
    self.number_phone.delete! '^0-9'
  end

  def clean_names
    self.first_name.delete! '^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ '
    self.first_name.strip!
    self.first_name.upcase!

    self.last_name.delete! '^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ '
    self.last_name.strip!
    self.last_name.upcase!
  end

  # def set_default_values
  #   self.password ||= self.ci #if self.password.blank?
  #   self.email = "temp#{self.ci}@mailinator.com" if self.email.blank? and !self.ci.blank?
  # end

  #FUNCTIONS:

  # PERSONAL AND CONTACT DETAILS
  def email_temp?
    email.include? 'mailinator'
  end

  def empty_info?
    empty_any_image? or empty_personal_info?
  end

  def empty_personal_info?
    (self.email.blank? or self.email_temp? or self.first_name.blank? or last_name.blank? or self.number_phone.blank? or self.sex.blank?)
  end

  def empty_any_image?
     empty_profile_picture? or empty_ci_image?
  end

  def empty_profile_picture?
    (self.profile_picture.nil? or (self.profile_picture and !self.profile_picture.attached?))
  end

  def empty_ci_image?
    (self.ci_image.nil? or (self.ci_image and !self.ci_image.attached?))
  end

  # SEXO
  def sexo_to_s
    aux = 'Mujer' if self.Femenino?
    aux = 'Hombre' if self.Masculino?
    return aux.blank? ? 'Indefinido' : aux
  end

  def la_el
    self.Femenino? ? 'la' : 'el'
  end

  def genero
    gen = "@"
    gen = "a" if self.Femenino?
    gen = "o" if self.Masculino?
    return gen
  end

  def short_name
    "#{first_name} #{last_name.first}."
  end
  def nick_name
    first_name.split(" ").first
  end

  def admin?
    self.admin.nil? ? false : true
  end

  def student?
    self.student.nil? ? false : true
  end

  def teacher?
    self.teacher.nil? ? false : true
  end

  def roles
    aux = []
    aux << I18n.t('activerecord.models.admin.one') if admin?
    aux << I18n.t('activerecord.models.student.one') if student?
    aux << I18n.t('activerecord.models.teacher.one') if teacher?
    return aux.to_sentence
  end

  def reverse_name
    "#{last_name}, #{first_name}"
  end

  def description
    "#{self.ci} (#{self.email}): #{self.first_name} #{self.last_name}"
  end

  def email_desc
    compile = last_name ? "#{last_name.titleize} " : "" 
    compile += "#{first_name.titleize} " if first_name
    compile += "<#{email}>"
    compile
  end

  def ci_fullname
    "#{ci}: #{full_name}"
  end

  def name
    description
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def without_rol?
    (self.how_many_roles? == 0)
  end

   def links_to_detail
    aux = []
    aux << "<i class='fa-regular fa-user-tie'></i>#{I18n.t('activerecord.models.admin.one')}" if admin?
    aux << "<a href='/admin/student/#{id}'><i class='fa-regular fa-user-graduate'></i>#{I18n.t('activerecord.models.student.one')}</a>" if student?
    aux << "<a href='/admin/teacher/#{id}'><i class='fa-regular fa-chalkboard-user'></i>#{I18n.t('activerecord.models.teacher.one')}</a>" if teacher?
    return aux.to_sentence.html_safe
  end 

  def how_many_roles?
    aux = 0
    aux += 1 if admin?
    aux += 1 if student?
    aux += 1 if teacher?    
    return aux
  end

  # def profile_set
  #   # "<img src='/assets/foto_perfil_default_35.png' class='img-thumbnail' />"
  #   if self.profile_picture and self.profile_picture.attached? and self.profile_picture.representable?
  #     ActionController::Base.helpers.image_tag(Object.new.extend(ActionView::Helpers::AssetUrlHelper).image_url(self.profile_picture, class: "img-thumbnail"))

  #     # "<img src='#{Object.new.extend(ActionView::Helpers::AssetUrlHelper).image_url(self.profile_picture)}' class='img-thumbnail' />"
      
  #   end
  # end


  # INTENTOS FALLIDOS REGEXP, AHORA INCLUYE Ñ PERO FALTA EL ACENTO
  # regexp_español = "/^[a-zA-ZÀ-ÿ\u00f1\u00d1]+(\s*[a-zA-ZÀ-ÿ\u00f1\u00d1]*)*[a-zA-ZÀ-ÿ\u00f1\u00d1]+$/g"
  # regexp_español2 = "/[^A-Z\u00e0-\u00fc| ]/g"
  # regexp_español3 = "/[^a-zA-Z\u00C0-\u017F| ]/g" 
  # regexp_español4 = "/[^a-zA-ZÀ-ÿ\u00f1\u00d1 ]+(\s*[a-zA-ZÀ-ÿ\u00f1\u00d1]*)*[a-zA-ZÀ-ÿ\u00f1\u00d1]+$/g"
  # regexp_español_ori = "/[^A-Za-z| ]/g"
  # Para Probar: .replace(/[\x00-\x09\x0B\x0C\x0E-\x1F\x7F-\x9F]/g, '');

  regexp_español3 = "/[^a-zA-Z\u00C1\u00C9\u00CD\u00D3\u00DA\u00DC\u00E1\u00E9\u00ED\u00F3\u00FA\u00FC| ]/g" #√


  # RAILS_ADMIN:
  rails_admin do
    visible false
    navigation_icon 'fa-regular fa-user'
    # def self.full_name
    #   "#{name} #{last_name}"
    # end

    edit do
      field :ci do
        html_attributes do
          {:length => 8, :size => 8, :onInput => "$(this).val($(this).val().toUpperCase().replace(/[^0-9]/g,''))"}
        end
      end
      field :email

      field :first_name do
        help 'Ningún caracater especial será guardado, expectuando la letra Ñ y cualquier tipo de acento'
        # OJO: SE LIMPIA EN EL SERVIDOR ANTES DE GUARDAR
        # html_attributes do
        #   {:onInput => "$(this).val($(this).val().toUpperCase().replace(#{regexp_español3},''))"}
        # end  
      end

      field :last_name do
        help 'Ningún caracater especial será guardado, expectuando la letra Ñ y cualquier tipo de acento'
        # OJO: SE LIMPIA EN EL SERVIDOR ANTES DE GUARDAR
        # html_attributes do
        #   {:onInput => "$(this).val($(this).val().toUpperCase().replace(#{regexp_español3},''))"}
        # end  
      end

      field :password do
        # read_only true
        aux = 'Si está creando un nuevo usuario, la contraseña será igual a la cédula de identidad. Posteriormente, el usuario mismo podrá cambiarla al iniciar sesión. Si está editando un usuario ya creado, podrá autogestionar su contraseña mediante la opción "Recuperar contraseña" del inicio de sesión.'
        help aux

      end
      field :number_phone do
        html_attributes do
          {length: 8, size: 8, onInput: "$(this).val($(this).val().toUpperCase().replace(/[^0-9]/g,''))"}
        end
      end

      field :sex #
      # field :sex, :enum do
      #   html_attributes do
      #     {:as => :radio }
      #   end        
      # end

      field :profile_picture, :active_storage do
        label 'Imagen de Perfil'
        delete_method :remove_profile_picture
      end
      field :ci_image, :active_storage do
        label 'Imagen CI'
        delete_method :remove_ci_image
      end 
    end

    show do
      # field :profile_picture, :active_storage  do

        # formatted_value do
        #   bindings[:view].tag(:img, { :src => bindings[:object].profile_picture }) << value
        # end
        # formatted_value do
        #   bindings[:view].render(partial: "rails_admin/main/image", locals: {object: bindings[:object]})
        # end
      # end
      field :links_to_detail do
        label 'Roles'
      end      
      field :profile_picture, :active_storage 
      field :ci_image, :active_storage 
      field :ci
      field :email
      field :first_name
      field :last_name
      field :number_phone
      field :sex
      field :password

    end

    list do
      items_per_page 10
      search_by :my_search #[:email, :first_name, :last_name, :ci]
      field :ci
      field :links_to_detail do
        label 'Roles'
      end      
      field :email
      field :first_name
      field :last_name
      field :number_phone
      field :sex do
        formatted_value do # used in form views
          value.titleize if value
        end

        pretty_value do # used in list view columns and show views, defaults to formatted_value for non-association fields
          value.titleize if value
        end

      end
      field :profile_picture
    end

    export do
      field :ci 
      field :email 
      field :first_name 
      field :last_name 
      field :number_phone 
      field :sex
    end

    import do
      fields :ci, :email, :first_name, :last_name#, :student, :teacher
      mapping_key :ci 

    end

  end

  private

    def send_welcome_email
      begin
        UserMailer.welcome(self).deliver_now
        # UserMailer.welcome(self).deliver_later
      rescue Exception => e
        
      end
    end

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
      self.paper_trail_event = "¡Usuario eliminado!"
    end

    def set_updated_password
      chagebles = self.changes.keys - ['updated_at']
      if (chagebles.count.eql? 1 and chagebles.include? "encrypted_password")
        self.updated_password = true
      end
    end

end
