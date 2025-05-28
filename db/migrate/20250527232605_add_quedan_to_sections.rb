class AddQuedanToSections < ActiveRecord::Migration[7.0]
  def change
    add_column :sections, :quedan, :integer, default: 0, null: false
  end
end
