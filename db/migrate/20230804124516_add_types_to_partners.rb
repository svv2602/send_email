class AddTypesToPartners < ActiveRecord::Migration[7.0]
  def change
    add_column :partners, :TipKontragentaILSh, :string, default: ""
    add_column :partners, :TipKontragentaCMK, :string, default: ""
    add_column :partners, :TipKontragentaSHOP, :string, default: ""
  end
end
