class CreateLeftovers < ActiveRecord::Migration[7.0]
  def change
    create_table :leftovers do |t|
      t.text :Artikul
      t.text :Sklad
      t.text :SkladKod
      t.text :Kolichestvo
      t.text :GruppaSkladov
      t.text :Gorod

      t.timestamps
    end
  end
end
