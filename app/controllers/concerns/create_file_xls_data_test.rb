module CreateFileXlsDataTest
  extend ActiveSupport::Concern

  included do
    def set_test_data
      # очистка таблиц отправки почты и партнеров с заливкой тестовых данных
      # для проверки рассылки
      Email.delete_all
      Partner.delete_all
      set_test_data_partner
    end

    #================= Данные для теста =====================================
    def set_test_data_partner
      # формирование тестового набора данных в таблице partners в рабочей базе
      podrazdelenie = ["Одесса ОСПП", "Тендерный отдел",
                       "Ровно ОСПП", "Львов ОСПП", "Кривой Рог ОСПП",
                       "Тернополь ОСПП"]
      type = ["B2B",
              "B2C более 50 т.с",
              "B2C до 50 т.с.",
              "Автоимпортер",
              "Автосалон",
              "Автосборочное предприятие",
              "Агрохолдинг",
              "Гос.организация",
              "Интернет-магазин",
              "УкрОборонПром"]

      city = ["Київ", "Запоріжжя", "Миколаїв",
              "Дніпро", "Тернопіль", "Суми",
              "Кривий Ріг", "Харків", "Вінниця", "Львів"]


      email = ["snisar.vv@tot.biz.ua", "pogoreltsev.iv@tot.biz.ua",
               "kopanichuck.da@tot.biz.ua", "shabatura.dn@tot.biz.ua",
               "ivaschenko.sa@tot.biz.ua", "kucherenko.da.tot@gmail.com"]


      email = ["snisar.vv@tot.biz.ua"]

      count_simple = email.size # количество примеров по email

      count_simple.times do |i|
        Partner.create!(
          Kontragent: "Контрагент #{i}",
          Email: email[i],
          Partner: "Партнер #{i}",
          OsnovnoiMeneger: "Менеджер #{rand(count_simple)}",
          TelefonPodrazdeleniia: "123-456-789",
          TelefonMenedzher: "067 00 000 000",
          Gorod: city[rand(city.size)],
          TipKontragentaILSh: type[rand(type.size)],
          TipKontragentaCMK: type[rand(type.size)],
          TipKontragentaSHOP: type[rand(type.size)],
          Podrazdelenie: podrazdelenie[rand(podrazdelenie.size)],
          test: true
        )

      end

    end

    #====================================================================

  end

end