class EnrollmentDay < ApplicationRecord
  # SCHEMA:
  # t.bigint "academic_process_id", null: false
  # t.datetime "start"
  # t.integer "total_duration_hours", limit: 2
  # t.integer "max_grades", limit: 2
  # t.integer "slot_duration_minutes", limit: 2

  #RELATIONSHIPS:
  belongs_to :academic_process
  has_one :school, through: :academic_process 
  has_one :period, through: :academic_process 
  
  # VALIDACIONES
  validates :academic_process_id, presence: true
  validates :start, presence: true
  validates :total_duration_hours, presence: true
  validates :max_grades, presence: true
  validates :slot_duration_minutes, presence: true

  validates_with UniqEnrollmentDayValidator, field_name: false, if: :new_record?

  #CALLBACK
  after_destroy :clean_grades_with_appointment_time

  #SCOPE
  scope :current_process, -> (academic_process_id) { of_today.where(academic_process_id: academic_process_id)}

  scope :of_today, -> {where(start: Time.zone.now.all_day)}
  
  def active_now?
    Time.zone.now > self.start and Time.zone.now < self.start+total_duration_hours.hours
  end

  #MÉTODOS

  #CSV:
  def name_to_file
    "#{academic_process.school.code}_#{academic_process.period.name}_#{start.strftime('%Y%m%d')}_#{self.id}"
  end

  def own_grades_to_csv

    CSV.generate do |csv|
      csv << ['Cédula', 'Apellido y Nombre', 'Sede', 'Desde', 'Hasta', 'Eficiencia', 'Promedio', 'Ponderado']
      own_grades_sort_by_appointment.each do |grade|
        
        # csv << [grade[:ci], user.reverse_name, grade.student.sede, grade.appointment_from, grade.appointment_to, eap.efficiency_desc, eap.simple_average_desc, eap.weighted_average_desc]
        csv << [grade[:user_ci], ActionView::Base.full_sanitizer.sanitize(grade[:student_link]), grade[:sede], grade[:from], grade[:to], grade[:efficiency], grade[:simple_average], grade[:weighted_average]]
      end
    end
  end

  def total_timeslots #total_franjas
    (slot_duration_minutes.eql? 0) ? 0 : (self.total_duration_hours/self.slot_duration_minutes.to_f*60).to_i
  end

  def grades_by_timeslot #grado_x_franja 
    if self.total_timeslots > max_grades 
      return max_grades 
    else
      (self.total_timeslots > 0) ? (max_grades/total_timeslots) : 0
    end
  end

  def mod_to_grades
    (total_timeslots.eql? 0) ? 0 : max_grades%total_timeslots
  end


  def own_grades
    self.school.grades.with_day_enroll_eql_to(self.start).uniq
  end

  def own_grades_count
    self.own_grades.count
  end

  def own_grades_sort_by_appointment
    # self.own_grades.order([appointment_time: :asc, duration_slot_time: :asc, efficiency: :desc, simple_average: :desc, weighted_average: :desc])
    
    # self.own_grades.sort_by{|e| [e.efficiency, e.simple_average, e.weighted_average]}
    # self.own_grades.unscope(:order).joins(:enroll_academic_processes).order(['enroll_academic_processes.efficiency': :desc, 'enroll_academic_processes.simple_average': :desc, 'enroll_academic_processes.weighted_average': :desc]).map

    self.own_grades.map(&:desc_to_enrollment_day).sort_by{|e| [e[:efficiency], e[:simple_average], e[:weighted_average]]}.reverse
    
  end

  def own_grades_sort_by_numbers
    self.own_grades.order([efficiency: :desc, simple_average: :desc, weighted_average: :desc])
  end

  def clean_grades_with_appointment_time
    self.own_grades.update_all(appointment_time: nil, duration_slot_time: nil)
  end

end
