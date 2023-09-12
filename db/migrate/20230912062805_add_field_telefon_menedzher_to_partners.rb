class AddFieldTelefonMenedzherToPartners < ActiveRecord::Migration[7.0]
  def change
    add_column :partners, :TelefonMenedzher, :string, default: ""
  end
end
