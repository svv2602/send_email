class CreatePartners < ActiveRecord::Migration[7.0]
  def change
    create_table :partners do |t|
      t.text :Kontragent, default: ""
      t.text :Email, default: ""
      t.text :Partner, default: ""
      t.text :OsnovnoiMeneger, default: ""
      t.text :TelefonPodrazdeleniia, default: ""
      t.text :Gorod, default: ""
      t.text :Podrazdelenie, default: ""

      t.timestamps
    end
  end
end
