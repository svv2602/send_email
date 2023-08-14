# Product.delete_all
# Price.delete_all
# Leftover.delete_all
Partner.delete_all
Email.delete_all


podrazdelenie = ["Одесса ОСПП", "Тендерный отдел",
                 "Ровно ОСПП","Львов ОСПП", "Кривой Рог ОСПП",
                 "", "Тернополь ОСПП"]
type = [ "B2B",
         "B2C более 50 т.с",
         "B2C до 50 т.с.",
         "Автоимпортер",
         "Автосалон",
         "Автосборочное предприятие",
         "Агрохолдинг",
         "Гос.организация",
         "Интернет-магазин",
         "УкрОборонПром"]

email = ["1@example.com", "2@example.com",
         "3@example.com", "4@example.com",
         "5@example.com"]

10.times do |i|
  Partner.create!(
    Kontragent: "Контрагент #{i}",
    Email: email[rand(5)],
    Partner: "Партнер #{i}",
    OsnovnoiMeneger: "Менеджер #{i}",
    TelefonPodrazdeleniia: "123-456-789",
    Gorod: "Город #{i}",
    TipKontragentaILSh: type[rand(10)],
    TipKontragentaCMK: type[rand(10)],
    TipKontragentaSHOP: type[rand(10)],
    Podrazdelenie: podrazdelenie[rand(7)]
  )

end

