class Subject < ApplicationRecord
  # SCHEMA:
  # t.string "code", null: false
  # t.string "name", null: false
  # t.boolean "active", default: true
  # t.integer "unit_credits", default: 24, null: false
  # t.integer "ordinal", default: 0, null: false
  # t.integer "qualification_type"
  # t.integer "modality"
  # t.bigint "area_id", null: false  
  # t.boolean "force_absolute", default: false  

  # HISTORY:
  has_paper_trail on: [:create, :destroy, :update]

  before_create :paper_trail_create
  before_destroy :paper_trail_destroy
  before_update :paper_trail_update

  # ASSOCIATIONS:
  belongs_to :area
  has_one :school, through: :area

  has_many :courses, dependent: :destroy
  has_many :periods, through: :courses 
  has_many :sections, through: :courses
  has_many :academic_records, through: :sections

  # LINKS
    # ATENCIÓN, MUCHA ATENCIÓN: Pareciera que las foraign_keys están al revés pero no es asi.
    # Si quiero ver las prelaciones de una materia, no debo ver las prelate_subject_id porque serían las asignaturas cuyas prelate_subject_id sean iguales a esta, es decir, las decendientes y eso sí estaría mal.
    # PRELATE:
      has_many :prelate_links, foreign_key: :depend_subject_id, class_name: 'SubjectLink', dependent: :destroy
      has_many :prelate_subjects, through: :prelate_links
      # accepts_nested_attributes_for :prelate_links, allow_destroy: true
      # accepts_nested_attributes_for :prelate_subjects, allow_destroy: true

    # DEPEND:
      has_many :depend_links, foreign_key: :prelate_subject_id, class_name: 'SubjectLink', dependent: :destroy
      has_many :depend_subjects, through: :depend_links
      # accepts_nested_attributes_for :dependent_links, allow_destroy: true


  # ENUMS:
  enum qualification_type: [:numerica, :absoluta]
  enum modality: [:obligatoria, :electiva, :optativa] 

  # VALIDATIONS:
  validates :code, presence: true, uniqueness: {case_sensitive: false}
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :ordinal, presence: true
  validates :modality, presence: true
  validates :qualification_type, presence: true
  validates :unit_credits, presence: true
  validates :area, presence: true

  # SCOPES: 

  scope :todos, -> {where('0 = 0')}

  scope :custom_search, -> (keyword) {joins([:area]).where("subjects.name ILIKE ? or subjects.code ILIKE ? or areas.name ILIKE ?", "%#{keyword}%", "%#{keyword}%", "%#{keyword}%")} 

  # scope :independents, -> {joins('LEFT JOIN subject_links ON subject_links.prelate_subject_id = subjects.id').where('subject_links.prelate_subject_id IS NULL')}

  scope :independents, -> {left_joins(:prelate_links).where('subject_links.prelate_subject_id': nil)}

  scope :not_inicial, -> {where('ordinal != 1')}

  scope :sort_by_code, -> {order(code: :asc)}

  # CALLBACKS:
  before_save :clean_values

  
  # HOOKS:
  def clean_values
    self.name.delete! '^0-9|^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ.() '
    self.name.strip!
    self.code.delete! '^0-9|^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ'
    self.code.strip!
    self.name.upcase!
    self.code.upcase!
    self.code = "0#{self.code}" if self.code[0] != '0' 
  end

  # GENERALS FUNCTIONS: 
  def self.ordinal_to_cardinal numero, type_school

    case numero
    when 0
      0
    when 1..12
      "#{numero}º #{type_school&.titleize}"
    end

  end

  def option_status
    if self.absoluta?
      '<option>Aprobado</option><option>Aplazado</option><option>Retirado</option>'
    else
      "<option>Sin Calificar</option><option>Calificar</option><option>Pérdida por Inasistencia</option><option>Retirado</option>" 
    end

  end
  def remove_redundant_courses_of academic_process_id
    redundance_courses = self.courses.where(academic_process_id: academic_process_id)
    if redundance_courses.count > 1
      pivote_id = redundance_courses&.first&.id

      sections = Section.where(course_id: redundance_courses.ids)
      (p '           Actualizando secciones           '.center(2000, 'A')) if sections.update_all(course_id: pivote_id)
      redundance_courses.each do |c| 
        unless c.sections.any?
          aux = "#{c.id} #{c.subject.name}"
          if c.destroy
            p "        Sección destruida #{aux}        ".center(500, ';) ') 
          else
            p "        No se pudo destruir #{aux}      ".center(500, ':/ ') 
          end
        end
      end
    else
      'Sin redundancia'
    end
  end

  def section_codes
    # sections.select(:code).distinct.map{|s| s.code}
    sections.order(code: :asc).map{|s| s.code}.uniq
  end

  # DEPENDENCIES FUNCTIONS:

  def full_dependency_tree_ids
    aux = []
    aux << prelate_tree
    aux << depend_tree
    return aux.flatten.uniq
  end  

  def prelate_tree
    self.prelate_links.map{|link| [link.prelate_subject_id, link.prelate_subject.prelate_tree].uniq.flatten} 
  end

  def depend_tree
    self.depend_links.map{|link| [link.depend_subject_id, link.depend_subject.depend_tree].uniq.flatten} 
  end  

  # def prelate_tree names=false

  #   if (prelate_links.count > 1)
  #     prelate_links.map{|subj_link| subj_link.prelate_subject.prelate_tree (names)}
  #   elsif (prelate_links.count.eql? 1)
  #     if aux = self.prelate_links.first.prelate_subject
  #       names ? aux.name : aux.id
  #     end
  #   end
  # end

  # def depend_tree names=false
  #   if (depend_links.count > 1)
  #     depend_links.map{|subj_link| subj_link.depend_subject.depend_tree (names)}
  #   elsif (depend_links.count.eql? 1)
  #     if aux = self.depend_links.first.depend_subject
  #       names ? aux.name : aux.id
  #     end
  #   end
  # end

  # DESCRIPTIONS TYPES:

  def desc
    "#{self.code}: #{self.name}"
  end

  def desc_confirm_enroll
    "- #{self.name} - #{self.unit_credits}"
  end

  def desc_id
    "#{id} #{desc}"
  end

  def description_code
    desc
  end

  def description_id_with_credits
    "#{description_code} (#{unit_credits} Unidades de Créditos)"
  end

  def desc_to_select
    "- #{self.description_code} - #{self.unit_credits}"
  end

  def description_code_with_school
    "#{description_code} <span class='badge badge-success'>#{self.school.code}</span>".html_safe
  end

  def description_complete
    "#{description_code} - #{self.area.name}"
  end

  def as_absolute?
    self.absoluta? or self.force_absolute?
  end

  def conv_header
    data = ["N°", "CÉDULA", "APELLIDOS Y NOMBRES", "PLAN", "CALIF. DESCR.", "TIPO", "CALIF. EN LETRAS"]

    data.insert(6, "CALIF. NUM.") unless self.as_absolute?

    return data

  end


  def label_credits
    return ApplicationController.helpers.label_status("bg-info", self.unit_credits)
  end

  def label_modality
    return ApplicationController.helpers.label_status("bg-info", self.modality.titleize) if self.modality
  end

  def label_qualification_type
    return ApplicationController.helpers.label_status("bg-info", self.qualification_type.titleize) if self.qualification_type
  end
  

  def modality_initial_letter
    case modality
    when 'obligatoria'
      'B'
    when 'electiva'
      'O'
    when 'optativa'
      'L'
    when 'proyecto'
      'P'
    end      
  end

  def total_dependencies
    self.depend_subjects.count
  end

  def total_courses
    courses.count
  end

  rails_admin do
    navigation_label 'Config General'
    navigation_icon 'fa-regular fa-book'
    weight 2

    object_label_method do
      :desc
    end

    list do
      scopes [:todos, :obligatoria, :electiva, :optativa]
      search_by :custom_search
      checkboxes false
      sidescroll(num_frozen_columns: 3)

      field :area do
        searchable true
      end

      field :code do
        filterable false
        searchable true
      end

      field :name do
        column_width 300
        searchable false
      end

      # field :school do
      #   filterable true
      #   pretty_value do
      #     bindings[:object].school.short_name
      #   end
      # end

      field :periods do
        label 'Periodos'
        pretty_value do
          bindings[:object].periods.map{|pe| pe.name}.to_sentence          
        end
      end


      field :unit_credits do 
        label 'Crédi'
        column_width 20
      end

      field :ordinal do
        label 'Orden'
        column_width 20
      end

      field :total_courses do
        label 'Cursos'
        column_width 20
      end

      field :modality do
        column_width 20
        filterable false

        pretty_value do
          bindings[:object].label_modality
        end        
      end

      field :qualification_type do
        label 'Tipo Calif'
        column_width 20
        pretty_value do
          bindings[:object].label_qualification_type
        end
      end

      field :total_dependencies do
        label 'Depends'
        column_width 20
      end
    end

    show do
      # fields :area, :code, :name, :unit_credits, :ordinal, :qualification_type, :modality, :created_at, :updated_at
      field :periods do
        label 'Períodos en los que se ha dictado'
        pretty_value do
          if bindings[:object].periods.any?
            bindings[:object].periods.map{|pe| pe.name}.to_sentence
          else
            'Aún no se ha dictado la asignatura'
          end
        end        
      end
      field :desc_show do
        label 'Descripción'
        formatted_value do
          bindings[:view].render(partial: "subjects/desc_table", locals: {subject: bindings[:object]})
        end
      end

      field :sections do
        label 'Secciones'
        pretty_value do
          bindings[:view].render(partial: "/sections/index", locals: {sections: bindings[:object].sections.joins(:academic_process).order('academic_processes.name': :desc ), adelante: false})
        end
      end

      field :prelate_subjects do
        label do
          if bindings[:object].prelate_subjects.any?
            "#{bindings[:object].name} es prelada por la(s) siguiente(s) asignatura(s):"
          else
            "#{bindings[:object].name} No tiene prelación"
          end
        end
        pretty_value do
          if bindings[:object].prelate_subjects.any?
            bindings[:view].render(partial: "/subject_links/index", locals: {subject: bindings[:object], adelante: false})
          else
            "<span class='alert alert-success'>Sin prelaciones: No hay otras asignaturas que sean requisito para cursar #{bindings[:object].name}.</span>".html_safe
          end
        end
      end
      field :depend_subjects do
        label do
          "Asignaturas que prela #{bindings[:object].name}:"
        end        
        pretty_value do
          if bindings[:object].depend_subjects.any?
            bindings[:view].render(partial: "/subject_links/index", locals: {subject: bindings[:object], adelante: true})

          else
            "<span class='alert alert-success'>No hay otras asignaturas que el estudiante pueda cursar una vez apruebe #{bindings[:object].name}.</span>".html_safe
          end
        end
      end
    end

    edit do
      field :area do
        inline_edit false
        inline_add false
      end
      field :code do
        html_attributes do
          {length: 20, size: 20, onInput: "$(this).val($(this).val().toUpperCase().replace(/[^A-Za-z0-9]/g,''))"}
        end  
      end
      field :name do
        html_attributes do
          {:onInput => "$(this).val($(this).val().toUpperCase())"}
        end  
      end      
      fields :modality, :unit_credits

      field :ordinal do
        html_attributes do
          {min: 0, max: 20}
        end
        help 'Semestre o año en que se ubica la asignatura.'
      end

      field :qualification_type do
        # help 'Parcial3 equivale a asignatura con 3 calificaciones parciales'
        # formatted_value do
        #   bindings[:object].label_qualification_type
        # end
      end

      field :prelate_subjects do
        inline_add false
        inline_edit false
        label do
          "Prelación(es) de #{bindings[:object].name}"
        end
        help do
          "Asignatura(s) que prela(n) #{bindings[:object].name}: El estudiante debe aprobar la(s) asignatura(s) indicadas(s) arriba para poder cursar #{bindings[:object].name}."
        end
      end

      # field :depend_subjects do
      #   inline_add false
      #   inline_edit false
      #   help 'Asignatura(s) que depende(n) de esta asignatura. Si el estudiante aprueba esta asignatura, la(s) asignatura(s) seleccionada(s) arriba podrán ser ofertadas.'
      # end
    end

    export do
      field :code, :string 
      fields :name, :area, :unit_credits, :ordinal, :qualification_type, :modality
    end
  end

  private
  
  def self.import row, fields
    total_newed = total_updated = 0
    no_registred = nil
    area = Area.find(fields['area_id'])

    if row[0] #CODIGO
      row[0].strip!
      row[0].delete! '^A-Za-z|0-9'
    else
      return [0,0,0]
    end

    subject = Subject.find_or_initialize_by(code: row[0])

    nueva = subject.new_record?
    subject.area_id = area.id

    if row[1] #Nombre
      row[1].strip!
    else
      return [0,0,1]
    end
      
    subject.name = row[1]

    # UNITS CREIDTS
    credit = row[2] ? row[2].to_i : fields['unit_credits']
    subject.unit_credits = credit

    # ORDER
    order = row[3] ? row[3].to_i : fields['order']
    subject.ordinal = order

    # MODALITY
    # p "     #{row[4].strip.downcase.to_sym}      ".center(500, "!")
    modality = fields['modality']
    if row[4]
      aux = row[4].strip.downcase
      modality = aux if Subject.modalities.keys.include? aux
    end
    
    subject.modality = modality
      
    # QUALIFICATION TYPE
    qualification_type = row[5] ? row[5].strip.downcase.to_sym : fields['qualification_type']
    qualification_type = :numerica if qualification_type.eql? :numérica
      
    subject.qualification_type = qualification_type

    if subject.save
      if nueva
        total_newed = 1
      else
        total_updated = 1
      end
    else
      no_registred = 1
    end

    return [total_newed, total_updated, no_registred]
  end

  private


    def paper_trail_update
      # changed_fields = self.changes.keys - ['created_at', 'updated_at']
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      # self.paper_trail_event = "¡#{object} actualizado en #{changed_fields.to_sentence}"
      self.paper_trail_event = "¡#{object} actualizada!"
    end  

    def paper_trail_create
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡#{object} registrada!"
    end  

    def paper_trail_destroy
      object = I18n.t("activerecord.models.#{self.model_name.param_key}.one")
      self.paper_trail_event = "¡Asignatura eliminada!"
    end

end
