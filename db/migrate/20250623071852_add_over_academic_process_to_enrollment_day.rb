class AddOverAcademicProcessToEnrollmentDay < ActiveRecord::Migration[7.0]
  def change
    add_column :enrollment_days, :over_academic_process_id, :bigint
  end
end
