class AddFieldNaimenovanieToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :Naimenovanie, :string, default: ""
  end
end
