class Qualification < ApplicationRecord
  # t.integer "value"
  # t.integer "type_q"
  
  belongs_to :academic_record
  # accepts_nested_attributes_for :academic_record

  has_one :enroll_academic_process, through: :academic_record
  has_one :grade, through: :enroll_academic_process


  scope :by_type_q, -> (type_q) {where(type_q: type_q)}
  scope :post, -> {where(type_q: [:diferido, :reparacion])}

  scope :definitive, -> {where(definitive: true)}

  enum type_q: [:final, :diferido, :reparacion]

  validates :academic_record, presence: true
  validates :value, presence: true, numericality: { only_integer: true, in: 0..20 }
  validates :type_q, presence: true
  validates_uniqueness_of :academic_record, scope: [:type_q], message: 'Calificación ya existente', field_name: false
  validates_uniqueness_of :academic_record, scope: [:definitive], message: 'Ya calificada', field_name: false

  after_save :update_academic_record_status

  def name
    "#{type_q.titleize} #{value}" if (type_q and value)
  end

  after_destroy :update_academic_record_status

  def update_academic_record_status

    academic_record.destroy_dup
    definitive_q_value = self.academic_record.definitive_q_value
    if definitive_q_value and !self.academic_record.pi?
      status = (definitive_q_value >= 10) ? :aprobado : :aplazado
      self.academic_record.update(status: status)
    end
    update_status
  end

  def approved?
    if is_valid_numeric_value?
      value >= 10
    else
      false
    end
  end

  def repproved?
    if is_valid_numeric_value?
      value < 10
    else
      false
    end
  end

  def desc_conv
    if self.final?
      if self.academic_record.pi?
        'PI'
      elsif self.academic_record.retirado?
        'RT'
      else
        I18n.t(self.type_q)
      end
    else
      I18n.t(self.type_q)
    end
  end

  def is_valid_numeric_value?
    !value.blank? and (value.is_a? Integer or value.is_a? Float)
  end

  def value_to_02i
    is_valid_numeric_value? ? sprintf("%02i", value) : nil
  end


  rails_admin do
    edit do
      fields :value, :type_q
    end
    export do
      field :value, :string
      field :type_q
    end
  end

  private

  def update_status

    if self.diferido? or self.reparacion?
      self.academic_record.qualifications.final.first.update(definitive: false)
    end

    eap = self.enroll_academic_process
    eap.update(permanence_status: eap.get_regulation) if enroll_academic_process&.finished?
    
    eap.update(efficiency: eap.calculate_efficiency, simple_average: eap.calculate_average, weighted_average: eap.calculate_weighted_average)    

    grado = self.grade
    grado.update(efficiency: grado.calculate_efficiency, simple_average: grado.calculate_average, weighted_average: grado.calculate_weighted_average)
  end
end
