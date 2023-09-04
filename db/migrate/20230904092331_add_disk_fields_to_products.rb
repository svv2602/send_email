class AddDiskFieldsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :VyletDiskaET, :string, default: ""
    add_column :products, :VidUslugi, :string, default: ""
    add_column :products, :PCDDiska, :string, default: ""
    add_column :products, :DIADiska, :string, default: ""
  end
end
