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

ActiveRecord::Schema[7.0].define(version: 2023_09_04_092331) do
  create_table "data_write_statuses", force: :cascade do |t|
    t.boolean "in_progress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "emails", force: :cascade do |t|
    t.string "to"
    t.string "subject"
    t.text "body"
    t.boolean "delivered", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "leftovers", force: :cascade do |t|
    t.text "Artikul", default: ""
    t.text "Sklad", default: ""
    t.text "SkladKod", default: ""
    t.text "Kolichestvo", default: ""
    t.text "GruppaSkladov", default: ""
    t.text "Gorod", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "Podrazdelenie", default: ""
  end

  create_table "partners", force: :cascade do |t|
    t.text "Kontragent", default: ""
    t.text "Email", default: ""
    t.text "Partner", default: ""
    t.text "OsnovnoiMeneger", default: ""
    t.text "TelefonPodrazdeleniia", default: ""
    t.text "Gorod", default: ""
    t.text "Podrazdelenie", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "TipKontragentaILSh", default: ""
    t.string "TipKontragentaCMK", default: ""
    t.string "TipKontragentaSHOP", default: ""
    t.boolean "test", default: false
  end

  create_table "prices", force: :cascade do |t|
    t.text "Artikul", default: ""
    t.text "Vidceny", default: ""
    t.text "Cena", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.text "Artikul", default: ""
    t.text "Nomenklatura", default: ""
    t.text "Ves", default: ""
    t.text "Proizvoditel", default: ""
    t.text "VidNomenklatury", default: ""
    t.text "TipTovara", default: ""
    t.text "TovarnayaKategoriya", default: ""
    t.text "Obem", default: ""
    t.text "SezonnayaGruppa", default: ""
    t.text "Napravleniegruppy", default: ""
    t.text "Posadochnyydiametr", default: ""
    t.text "Razmer", default: ""
    t.text "Vysotaprofilya", default: ""
    t.text "Indeksnagruzki", default: ""
    t.text "Shirinaprofilya", default: ""
    t.text "Indeksskorosti", default: ""
    t.text "Tiprisunkaprotektora", default: ""
    t.text "Stranaproiskhozhdeniya", default: ""
    t.text "Segment", default: ""
    t.text "Model", default: ""
    t.text "Primenimost", default: ""
    t.text "God", default: ""
    t.text "KodUKTVED", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "Naimenovanie", default: ""
    t.string "VyletDiskaET", default: ""
    t.string "VidUslugi", default: ""
    t.string "PCDDiska", default: ""
    t.string "DIADiska", default: ""
  end

end
