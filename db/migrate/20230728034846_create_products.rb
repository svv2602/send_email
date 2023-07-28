class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.text :Artikul
      t.text :Nomenklatura
      t.text :Ves
      t.text :Proizvoditel
      t.text :VidNomenklatury
      t.text :TipTovara
      t.text :TovarnayaKategoriya
      t.text :Obem
      t.text :SezonnayaGruppa
      t.text :Napravleniegruppy
      t.text :Posadochnyydiametr
      t.text :Razmer
      t.text :Vysotaprofilya
      t.text :Indeksnagruzki
      t.text :Shirinaprofilya
      t.text :Indeksskorosti
      t.text :Tiprisunkaprotektora
      t.text :Stranaproiskhozhdeniya
      t.text :Segment
      t.text :Model
      t.text :Primenimost
      t.text :God
      t.text :KodUKTVED

      t.timestamps
    end
  end
end
