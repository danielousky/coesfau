class DeleteSchoolReferenceToAdmissionType < ActiveRecord::Migration[7.0]
  def change
    remove_reference :admission_types, :school, null: false, foreign_key: true
  end
end
