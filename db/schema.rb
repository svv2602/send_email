# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_07_28_100122) do
  create_table "leftovers", force: :cascade do |t|
    t.text "Artikul"
    t.text "Sklad"
    t.text "SkladKod"
    t.text "Kolichestvo"
    t.text "GruppaSkladov"
    t.text "Gorod"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "prices", force: :cascade do |t|
    t.text "Artikul"
    t.text "Vidceny"
    t.text "Cena"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.text "Artikul"
    t.text "Nomenklatura"
    t.text "Ves"
    t.text "Proizvoditel"
    t.text "VidNomenklatury"
    t.text "TipTovara"
    t.text "TovarnayaKategoriya"
    t.text "Obem"
    t.text "SezonnayaGruppa"
    t.text "Napravleniegruppy"
    t.text "Posadochnyydiametr"
    t.text "Razmer"
    t.text "Vysotaprofilya"
    t.text "Indeksnagruzki"
    t.text "Shirinaprofilya"
    t.text "Indeksskorosti"
    t.text "Tiprisunkaprotektora"
    t.text "Stranaproiskhozhdeniya"
    t.text "Segment"
    t.text "Model"
    t.text "Primenimost"
    t.text "God"
    t.text "KodUKTVED"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
