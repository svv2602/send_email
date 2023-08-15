class AddFieldTestToPartners < ActiveRecord::Migration[7.0]
  def change
    add_column :partners, :test, :boolean, default: false
  end
end
