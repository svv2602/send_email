class CreateLeftovers < ActiveRecord::Migration[7.0]
  def change
    create_table :leftovers do |t|
      t.text :Artikul, default: ""
      t.text :Sklad, default: ""
      t.text :SkladKod, default: ""
      t.text :Kolichestvo, default: ""
      t.text :GruppaSkladov, default: ""
      t.text :Gorod, default: ""

      t.timestamps
    end
  end
end
