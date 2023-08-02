class CreatePrices < ActiveRecord::Migration[7.0]
  def change
    create_table :prices do |t|
      t.text :Artikul, default: ""
      t.text :Vidceny, default: ""
      t.text :Cena, default: ""

      t.timestamps
    end
  end
end
