class Period < ApplicationRecord
	#SCHEMA:
    # t.integer "year", null: false
    # t.string "name"
	
	#ASSOCIATIONS:
	# belongs_to
	belongs_to :period_type

	# has_many:
	has_many :academic_processes, dependent: :destroy
	has_many :schools, through: :academic_processes
	has_many :enroll_academic_processes, through: :academic_processes

	# VALIDATIONS:
	validates :year, presence: true
	validates :year, numericality: {only_integer: true, greater_than_or_equal_to: 1920, less_than_or_equal_to: 2100}
	validates :period_type, presence: true
	validates_uniqueness_of :year, scope: [:period_type], message: 'Periodo existente', field_name: false

	# SCOPE:
	# scope :by_name, -> (year, code) {joins(:period_type).where(year: year, 'period_types.code': code)}

	# scope :find_by_name, -> (name) {joins(:period_type).where(year: name.split('-').first, 'period_types.code': name.split('-').last).first}

	before_save :set_name


	def name_revert
		"#{period_type.code.upcase}#{year}" if period_type
	end

	def get_name
		"#{year}-#{period_type.code.upcase}" if period_type
	end

	def period_type_name
		period_type.name if period_type
	end

  rails_admin do
    navigation_label 'Config Específica'
    navigation_icon 'fa-solid fa-clock'
    visible false

    list do 
			field :name
    end

    edit do
    	group :dato_periodo do
    		label 'Datos del Perido'
    		# active false
			field :year do
				a = Date.today.year
				html_attributes do
					{onInput: "$(this).val($(this).val().replace(/[^0-9]/g,''))", min: a-60, max:a+10, step: 1, value: a}
				end  
			end
			field :period_type
		end
    end

    show do
    	fields :name
    end

    export do
    	field :name do
    		label 'Periodo'
    	end
    end
  end

  private

  def set_name
  	self.name = self.get_name
  end

end
