class AddDopFieldsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :Tipdiska, :string, default: ""
    add_column :products, :Shirinadiska, :string, default: ""
    add_column :products, :Ship, :string, default: ""
    add_column :products, :Os, :string, default: ""
    add_column :products, :KodyTRAOTR, :string, default: ""
    add_column :products, :Indekssloy̆nosti, :string, default: ""
    add_column :products, :Usilenie, :string, default: ""
    add_column :products, :Komplektnost, :string, default: ""
    add_column :products, :Tipkarkasa, :string, default: ""
  end
end
