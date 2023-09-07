# app/controllers/concerns/data_access_methods.rb
module InputDataMethods
  extend ActiveSupport::Concern

  included do

    def import_data_from_api_select(table_name, url, table_key)

      response = HTTParty.get(url)
      if response.code == 200
        time_load_table = Benchmark.realtime do
          product_class = table_name.capitalize.singularize.constantize

          product_class.delete_all
          data = JSON.parse(response.body)
          product_class.transaction do
            data.each do |json_data|
              product = product_class.new
              db_columns[table_key].each do |column_key, column_name|
                column_value = json_data[column_name.to_s] # Преобразуем имя поля в символ и ищем его в JSON
                product.send("#{column_key}=", column_value) if product.respond_to?("#{column_key}=")
              end

              unless product.save
                # Обработка ошибок сохранения
                puts "Ошибка сохранения продукта: #{product.errors.full_messages.join(', ')}"
                raise ActiveRecord::Rollback # Откатим транзакцию в случае ошибки
              end
            end
          end
        end
        @msg_data_load_select = "Данные #{table_key.to_s} успешно импортированы в базу данных! \n"
        @msg_data_load_select += "Время затраченное на обработку данных #{table_key.to_s} составляет #{time_load_table.round(2)}сек \n"
      else
        @msg_data_load_select = "Не удалось получить данные #{table_key.to_s} с API."
      end

      puts @msg_data_load_select
      @msg_data_load ||= ""
      @msg_data_load += @msg_data_load_select
    end

    def params_table
      [
        { table_name: 'products', url: 'http://192.168.3.14/erp_main/hs/price/noma/', table_key: :Product },
        { table_name: 'leftovers', url: 'http://192.168.3.14/erp_main/hs/price/ostatki/', table_key: :Leftover },
        { table_name: 'prices', url: 'http://192.168.3.14/erp_main/hs/price/prices/', table_key: :Price },
        { table_name: 'partners', url: 'http://192.168.3.14/erp_main/hs/price/kontragent/', table_key: :Partner },
      ]
    end

    def delete_empty_records_from_prices
      # Удалить цены для товаров без остатков
      Price.connection.exec_query("
          DELETE FROM prices
          WHERE NOT EXISTS (
            SELECT *
            FROM leftovers
            WHERE prices.Artikul = leftovers.Artikul
          );
        ")
    end

    def import_data_load
      # удалить тестовые данные
      Partner.where(test: true).delete_all if Partner.exists?(test: true) && params[:production].to_i == 1
      Partner.where(test: false).delete_all if Partner.exists?(test: false) && params[:production].to_i != 1

      @msg_data_load = ""
      params_table.each do |el|

        if @data_import_based_on_dates
          max_update_date = el[:table_key].to_s.capitalize.singularize.constantize.maximum(:updated_at)
          data_import_based_on_dates_result = (max_update_date&.to_date == Date.current)
        else
          data_import_based_on_dates_result = false
        end

        if !el[:table_name].capitalize.singularize.constantize.none? && data_import_based_on_dates_result
          @msg_data_load_select = "Данные #{el[:table_key].to_s} были загружены  #{max_update_date} и не требуют обновления \n"
          puts @msg_data_load_select
          @msg_data_load += @msg_data_load_select
        else
          import_data_from_api_select(el[:table_name], el[:url], el[:table_key])
          bracket_replacement if el[:table_name] == 'leftovers' # Убрать скобки в названиях складов
          if el[:table_name] == 'partners'
            type_replacement # Удалить тип прайса, если нет менеджера
            email_replacement # Нормализация email
          end
        end
      end
      delete_empty_records_from_prices

    end

    def get_json_files_from_api
      # запись данных с настройками прайса
      attr_path = ['settings', 'aliases', 'dopemail', 'textshapka']
      directory_path = "#{Rails.root}/lib/assets"
      FileUtils.mkdir_p(directory_path) unless Dir.exist?(directory_path)

      attr_path.each do |el|
        url = "http://192.168.3.14/erp_main/hs/price/#{el}/"
        response = HTTParty.get(url)
        if response.code == 200
          file_path = "#{directory_path}/price_#{el}.json"
          File.open(file_path, 'wb') { |f| f.write(response.body) }
          @msg_data_load_select = "Получены настройки #{el}  \n"
        else
          @msg_data_load_select = "Не удалось получить данные #{el} из API."
        end
        puts @msg_data_load_select
        @msg_data_load ||= ""
        @msg_data_load += @msg_data_load_select
      end

    end

    def ert

    end

    def db_columns
      # сопоставление названий столбцов таблиц с api
      {
        Product: {
          Artikul: "Артикул",
          Nomenklatura: "Номенклатура",
          Naimenovanie: "Наименование",
          Ves: "Вес",
          Proizvoditel: "Производитель",
          VidNomenklatury: "ВидНоменклатуры",
          TipTovara: "ТипТовара",
          TovarnayaKategoriya: "ТоварнаяКатегория",
          Obem: "Объем",
          SezonnayaGruppa: "СезоннаяГруппа",
          Napravleniegruppy: "Направлениегруппа",
          Posadochnyydiametr: "Посадочныйдиаметр",
          Razmer: "Размер",
          Vysotaprofilya: "Высотапрофиля",
          Indeksnagruzki: "Индекснагрузки",
          Shirinaprofilya: "Ширинапрофиля",
          Indeksskorosti: "Индексскорости",
          Tiprisunkaprotektora: "Типрисункапротектора",
          Stranaproiskhozhdeniya: "Странапроисхождения",
          Segment: "Сегмент",
          Model: "Модель",
          Primenimost: "Применимость",
          God: "Год",
          KodUKTVED: "КодУКТВЭД",
          VyletDiskaET: "ВылетдискаET",
          VidUslugi: "Видуслуги",
          PCDDiska: "PCDдиска",
          DIADiska: "DIAдиска",
          Tipdiska: "Типдиска",
          Shirinadiska: "Ширинадиска",
          Ship: "Шип",
          Os: "Ось",
          KodyTRAOTR: "КодыTRAOTR",
          Indekssloy̆nosti: "Индексслойности",
          Usilenie: "Усиление",
          Komplektnost: "Комплектность",
          Tipkarkasa: "Типкаркаса"
        },

        Leftover: {
          Artikul: "Артикул",
          Sklad: "Склад",
          SkladKod: "СкладКод",
          Kolichestvo: "Количество",
          GruppaSkladov: "ГруппаСкладов",
          Gorod: "Город",
          Podrazdelenie: "Подразделение"
        },

        Price: {
          Artikul: "Артикул",
          Vidceny: "ВидЦены",
          Cena: "Цена"
        },

        Partner: {
          Kontragent: "Контрагент",
          Email: "Email",
          Partner: "Партнер",
          OsnovnoiMeneger: "ОсновнойМенеджер",
          TelefonPodrazdeleniia: "ТелефонПодразделения",
          Gorod: "Город",
          TipKontragentaILSh: "ТипКонтрагентаИЛШ",
          TipKontragentaCMK: "ТипКонтрагентаЦМК",
          TipKontragentaSHOP: "ТипКонтрагентаШОП",
          Podrazdelenie: "Подразделение"
        }
      }

    end

  end
end