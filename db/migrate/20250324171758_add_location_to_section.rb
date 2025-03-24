class AddLocationToSection < ActiveRecord::Migration[7.0]
  def change
    add_column :sections, :location, :integer, null: false, default: 0
  end
end
