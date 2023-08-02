class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.text :Artikul, default: ""
      t.text :Nomenklatura, default: ""
      t.text :Ves, default: ""
      t.text :Proizvoditel, default: ""
      t.text :VidNomenklatury, default: ""
      t.text :TipTovara, default: ""
      t.text :TovarnayaKategoriya, default: ""
      t.text :Obem, default: ""
      t.text :SezonnayaGruppa, default: ""
      t.text :Napravleniegruppy, default: ""
      t.text :Posadochnyydiametr, default: ""
      t.text :Razmer, default: ""
      t.text :Vysotaprofilya, default: ""
      t.text :Indeksnagruzki, default: ""
      t.text :Shirinaprofilya, default: ""
      t.text :Indeksskorosti, default: ""
      t.text :Tiprisunkaprotektora, default: ""
      t.text :Stranaproiskhozhdeniya, default: ""
      t.text :Segment, default: ""
      t.text :Model, default: ""
      t.text :Primenimost, default: ""
      t.text :God, default: ""
      t.text :KodUKTVED, default: ""

      t.timestamps
    end
  end
end
