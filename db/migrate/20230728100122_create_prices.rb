class CreatePrices < ActiveRecord::Migration[7.0]
  def change
    create_table :prices do |t|
      t.text :Artikul
      t.text :Vidceny
      t.text :Cena

      t.timestamps
    end
  end
end
