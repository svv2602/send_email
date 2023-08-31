module CreateFileXlsMethods
  extend ActiveSupport::Concern

  included do
    def set_sheet_params_new(el_hash)
      @sheet_name = el_hash[:sheet_name]
      @skl = el_hash[:skl].uniq.reject { |value| value.nil? ||value.empty? }
      @city = el_hash[:city].uniq.reject { |value| value.nil? ||value.empty? }
      @grup = el_hash[:grup].uniq.reject { |value| value.nil? ||value.empty? }
      @podrazdel = el_hash[:podrazdel].uniq.reject { |value| value.nil? ||value.empty? }
      @price = el_hash[:price].uniq.reject { |value| value.nil? ||value.empty? }
      @product = el_hash[:product].uniq.reject { |value| value.nil? ||value.empty? }
      @max_count = el_hash[:max_count]
      @sheet_select = el_hash[:sheet_select_product]

    end

    def find_key_product(product_el)
      str = product_el.gsub(" ", "")
      hash_product = db_columns[:Product]
      hash_product.each do |key, value|
        return key if value.downcase == str.downcase
      end
      key = ""
    end

    def create_new_arr_product(arr_product)
      arr = []
      arr_product.each do |product_el|
        arr << find_key_product(product_el)
      end
      arr.uniq.reject { |value| value.empty? }
    end

    def find_value_product(product_el)
      normalized_key = product_el.gsub(" ", "").downcase
      hash_product = db_columns[:Product]

      hash_product.each do |key, value|
        return value if key.to_s.downcase == normalized_key
      end

      product_el
    end

    def set_test_data
      # очистка таблиц отправки почты и партнеров с заливкой тестовых данных
      # для проверки рассылки
      Email.delete_all
      Partner.delete_all
      set_test_data_partner
    end

    def create_and_send_price_to_partner_groups

      directory_path = "#{Rails.root}/tmp/prices/"
      FileUtils.mkdir_p(directory_path) unless Dir.exist?(directory_path)

      name_price = "price"
      @price_path = "#{directory_path}#{name_price}.xls"
      name_price_ind = "price_ind"
      @price_ind_path = "#{directory_path}#{name_price_ind}.xls"

      results = list_partners_to_send_email # получить список клиентов не получивших почту сегодня
      params = nil

      # сделать хеш дополнительных цен для email
      hash_dop_email = set_dopemail
      i = 0 # количество отправок
      j1 = 0 # количество прайсов
      j2 = 0 # количество индивидуальных прайсов

      # Обработка результатов
      results.each do |row|
        osnovnoi_meneger = row["OsnovnoiMeneger"]
        recipient_email = row["Email"]

        # При изменении params создать новый прайс
        unless params == row["params"]
          # удалить старый прайс
          File.delete(@price_path) if File.exist?(@price_path)
          # создать новый прайс
          @hash_value = hash_value_keys_partner(row["TipKontragentaILSh"],
                                                row["TipKontragentaCMK"],
                                                row["TipKontragentaSHOP"],
                                                row["Podrazdelenie"],
                                                row["Gorod"],
                                                {})

          set_price_sheet_attributes(@hash_value) # хеш настроек для создания листов прайса
          create_book_xls(@price_path)
          params = row["params"]
          j1 += 1 # количество прайсов
        end

        # ===================================================================
        # Создать индивидуальный прайс для email, если он есть в доп настройках
        if hash_dop_email.include?(recipient_email)
          # удалить старый прайс
          File.delete(@price_ind_path) if File.exist?(@price_ind_path)
          recipient_email_price = hash_dop_email[recipient_email]
          # создать новый индивидуальный прайс
          @hash_value = hash_value_keys_partner(row["TipKontragentaILSh"],
                                                row["TipKontragentaCMK"],
                                                row["TipKontragentaSHOP"],
                                                row["Podrazdelenie"],
                                                row["Gorod"],
                                                recipient_email_price)

          set_price_sheet_attributes(@hash_value) # хеш настроек для создания листов прайса
          create_book_xls(@price_ind_path)
          j2 += 1 # количество индивидуальных прайсов
        end

        # отправить прайс
        file_path_to_send = hash_dop_email.include?(recipient_email) ? @price_ind_path : @price_path

        MyMailer.send_email_with_attachment(recipient_email.to_s, file_path_to_send, osnovnoi_meneger).deliver_now

        i += 1 # количество отправок
      end

      @msg_data_load += "\n"
      @msg_data_load += "количество сформированных прайсов #{j1}\n"
      @msg_data_load += "количество сформированных индивидуальных прайсов #{j2}\n"
      @msg_data_load += "количество отправок #{i}\n"

    end

    def create_book_xls(price_path)

      # Создание объекта для XLS-файла
      @xls_file = Spreadsheet::Workbook.new

      # Создание стиля для зеленого фона
      @header_style = Spreadsheet::Format.new(color: :black,
                                              pattern: 1,
                                              pattern_fg_color: :cyan,
                                              border: :thin,
                                              text_wrap: true,
                                              bold: true,
                                              vertical_align: :top,
                                              horizontal_align: :center
      )
      # Создание стиля с границей
      @border_style = Spreadsheet::Format.new(border: :thin, color: :black, size: 10, text_wrap: true)
      # Создание стиля с границей
      @border_style_with_right_align = Spreadsheet::Format.new(border: :thin, color: :black, size: 10,
                                                               text_wrap: true, horizontal_align: :right)

      settings_price = set_price_sheet_attributes(@hash_value) # хеш настроек для создания листов прайса

      settings_price.each do |key, el_hash|
        creat_sheet_xls(el_hash)
      end

      xls_data = StringIO.new
      @xls_file.write xls_data

      # Сохраняем файл на сервере
      File.open(price_path, 'wb') { |f| f.write(xls_data.string) }

    end

    def creat_sheet_xls(el_hash)
      # Установить параметры для построения прайса
      set_sheet_params_new(el_hash)
      # Создать переменную cо значениями алиасов
      set_variable_with_array_of_aliases

      # Получить хеш с для построения запроса
      hash_with_params_sklad = hash_query_params_all(@skl, @city, @grup, @podrazdel, @price, @product, @max_count, @sheet_select)
      results = build_leftovers_combined_query(hash_with_params_sklad)

      grouped_results = results.group(:artikul, :Tovar_Kategoriya)
                               .select(hash_grouped_name_collumns(hash_with_params_sklad)[:attr_query])

      xls_sheet = @xls_file.create_worksheet(name: set_alias_el(@sheet_name))

      correction_index = 0

      # Добавление заголовков в таблицу XLS
      column_names = hash_grouped_name_collumns(hash_with_params_sklad)[:attr_query_name_collumn]

      # Формирование заголовков с alias
      new_column_names = column_names.map { |element| find_value_product(element) }
      xls_sheet.row(correction_index).concat set_alias(new_column_names)

      # Применение стиля к каждой ячейке заголовков, если она содержит значение
      new_column_names.each_with_index do |value, col_index|
        if value.present?
          xls_sheet.row(correction_index).set_format(col_index, @header_style)
        end
      end
      # Установка высоты строки
      xls_sheet.row(correction_index).height = 30
      correction_index += 1
      #==============================================

      # Заполнение таблицы данными
      grouped_results.each_with_index do |leftover, index|
        row_values = column_names.map { |column| format_value(leftover.send(column)) }
        xls_sheet.row(index + correction_index).push(*row_values)

        # Применение стиля с границей к каждой ячейке в строках с данными
        row_values.each_with_index do |cell_value, col_index|
          format = contains_only_digits_spaces_dots_and_commas?(cell_value) ? @border_style_with_right_align : @border_style
          xls_sheet.row(index + correction_index).set_format(col_index, format)
        end
      end

      #==============================================
      # Определение максимальной длины данных в каждом столбце
      # Проходим в цикле по всем столбцам и применяем автоподбор ширины
      xls_sheet.column_count.times do |col_index|
        max_length = xls_sheet.column(col_index).map(&:length).max
        xls_sheet.column(col_index).width = [max_length + 2, 50].min
      end

      correction_index = 0
      create_head_sheet(xls_sheet, correction_index, column_names.size, @sheet_name)

    end

    def norma_color(arr_attr)
      # полный список стандартных имен цветов, поддерживаемых в библиотеке spreadsheet
      arr_color = [:black, :white, :red, :green, :blue, :yellow, :purple, :orange,
                   :gray, :brown, :cyan, :magenta, :silver, :lime, :navy, :fuchsia, :aqua]
      new_arr = []
      arr_attr.each do |el|
        el_hash = {}
        el.each do |key, value|
          case key
          when "colorbackground"
            el_hash[key] = arr_color.include?(el["colorbackground"]&.to_sym) ? el["colorbackground"]&.to_sym : :white
          when "colorfont"
            el_hash[key] = arr_color.include?(el["colorfont"]&.to_sym) ? el["colorfont"]&.to_sym : :black
          else
            el_hash[key] = value
          end
        end
        new_arr << el_hash
      end
      new_arr
    end

    def create_head_sheet(xls_sheet, correction_index, column_count, sheet_name)

      json_string = File.read(@file_price_textshapka_path)
      arr_full = JSON.parse(json_string).to_a
      row_begin = correction_index
      # выполняем добавление строк, если есть соответствующий лист
      if arr_full.any? { |element| element["list"] == sheet_name }
        arr_attr = norma_color(arr_full.find { |element| element["list"] == sheet_name }["data"])

        current_style = {}
        arr_attr.each do |el|
          unless el["text"].nil?
            # Создание стиля
            size_value = el["size"].to_i
            size_value = 12 unless (10..24).include?(size_value)
            current_style = Spreadsheet::Format.new(color: el["colorfont"]&.to_sym || :black,
                                                    pattern: 1,
                                                    pattern_fg_color: el["colorbackground"]&.to_sym || :white,
                                                    bold: el["bold"]&.to_s.downcase == "да" || false,
                                                    italic: el["italic"]&.to_s.downcase == "да" || false,
                                                    size: size_value,
                                                    text_wrap: true,
                                                    horizontal_align: :center,
                                                    vertical_align: :center
            )

            insert_row_and_format_block(xls_sheet, correction_index, column_count, current_style)

            xls_sheet[correction_index, 0] = el["text"]
            # Установка высоты строки
            xls_sheet.row(correction_index).height = 30

            correction_index += 1
          end
        end
      end
      # добавить строку разрыва между заголовком и таблицей
      insert_row_and_format_block(xls_sheet, correction_index, column_count, current_style) if row_begin < correction_index
    end

    def insert_row_and_format_block(xls_sheet, correction_index, column_count, current_style)
      xls_sheet.insert_row(correction_index)
      # Применение стиля к каждой ячейке заголовков, если она содержит значение
      column_count.times do |column|
        xls_sheet[correction_index, column] = " "
        xls_sheet.row(correction_index).set_format(column, current_style)
      end
      xls_sheet.merge_cells(correction_index, 0, correction_index, column_count - 1)
    end

    def contains_only_digits_spaces_dots_and_commas?(str)
      # Проверяем, что строка состоит только из цифр, пробелов, точек и запятых
      # return str.match?(/\A(?:\d+(?:[.,]\d*)?|\>\d+)\z/)
      return str.match?(/\A(?:\d+(?:[.,]\d*)?|\>\d+|[\d\s.,]+)\z/)
    end

    def hash_value_keys_partner(tk_ilsh, tk_cmk, tk_shop, skl_pdrzd, skl_gorod, hash_email_price)
      { TipKontragentaILSh: tk_ilsh,
        TipKontragentaCMK: tk_cmk,
        TipKontragentaSHOP: tk_shop,
        Podrazdelenie: skl_pdrzd,
        Gorod: skl_gorod,
        hash_email_price: hash_email_price
      }
    end

    def set_json_files_path(price_settings, price_aliases, price_dopemail, price_textshapka)
      @file_price_settings_path = "#{Rails.root}/lib/assets/#{price_settings}.json"
      @file_price_aliases_path = "#{Rails.root}/lib/assets/#{price_aliases}.json"
      @file_price_dopemail_path = "#{Rails.root}/lib/assets/#{price_dopemail}.json"
      @file_price_textshapka_path = "#{Rails.root}/lib/assets/#{price_textshapka}.json"
    end

    def set_dopemail
      json_string = File.read(@file_price_dopemail_path)
      arr_dopemail = JSON.parse(json_string).to_a
      result = {}
      arr_dopemail.each do |element|
        if element.key?("emails")
          element["emails"].each do |el_arr|
            if element.key?("list") && element.key?("price")
              result[el_arr] ||= {}
              result[el_arr][element["list"]] = element["price"]
            end
          end
        end
      end
      result
      # пример вывода:
      # {"iiiiiii@gmail.com"=>{"Легковые шины"=>"Мин", "Диски"=>"Опт"},
      #  "speczapchast.agro@ukr.net"=>{"Легковые шины"=>"Мин", "Диски"=>"Опт"},
      #  "mpkcompany5@gmail.com"=>{"Легковые шины"=>"Мин", "Диски"=>"Опт"}}

    end

    def set_variable_with_array_of_aliases
      json_string = File.read(@file_price_aliases_path)
      @arr_aliases = JSON.parse(json_string).to_a
    end

    def set_alias_el(el)
      found_alias = nil # Инициализируем переменную перед блоком each
      @arr_aliases.each do |alias_hash|
        normalized_key = alias_hash["Объект"].gsub(" ", "").downcase
        if normalized_key == el.gsub(" ", "").downcase
          found_alias = alias_hash["Алиас"] unless alias_hash["Алиас"]&.empty?
          break
        end
      end
      result = (found_alias || el)
    end

    def set_alias(arr_name_columns)
      result = []
      arr_name_columns.each do |name_column|
        result << set_alias_el(name_column)
      end
      result
    end

    def set_price_sheet_attributes(hash_value)
      tabPartner = db_columns[:Partner]

      # hash_value_keys_partner = @hash_value
      json_string = File.read(@file_price_settings_path)

      hash_settings = JSON.parse(json_string) # test_setting
      #===========================================================
      # hash_settings = test_setting
      # временные переменные, заменить на получаемые по API
      # ===========================================================

      list = {}
      if hash_settings
        hash_settings.each do |key, value|
          skl = []
          city = []
          grup = []
          podrazdel = []
          price = []
          sheet_name = ""
          product = []
          sheet_select_product = {}
          max_count = 0

          # ====================================================
          # Название листа в файле и максимальное количество
          # ====================================================
          sheet_name = value["name"] || key.to_s
          max_count = value["items"].to_i

          # ====================================================
          # Массив свойств номенлатуры
          # ====================================================
          product = value["settings"].is_a?(Hash) && value["settings"]["Свойства"] ? value["settings"]["Свойства"] : []

          # ====================================================
          # Определение фильтров по видам номенклатуры и категоий товара
          # ====================================================
          ktg = value["settings"].is_a?(Hash) && value["settings"]["ТоварнаяКатегория"] ? value["settings"]["ТоварнаяКатегория"] : []
          vid = value["settings"].is_a?(Hash) && value["settings"]["ВидНоменклатуры"] ? value["settings"]["ВидНоменклатуры"] : []

          sheet_select_product = {
            TovarnayaKategoriya: ktg,
            VidNomenklatury: vid
          }

          # ====================================================
          # Определение типов цен для контрагента по листам
          # ====================================================
          if value["settings"]["ТипыЦен"].is_a?(Hash) && value["settings"]["ТипыЦен"]

            if value["settings"]["ТипыЦен"]["maintype"]
              result = value["settings"]["ТипыЦен"]["maintype"].downcase
              result2 = tabPartner.find { |key, value| value.downcase == result }
            else
              result2 = ""
            end

            value["settings"]["ТипыЦен"]["settings"].each do |el|
              el.each do |key, value|
                price << el["default"] if key == "default"
                price << el["prices"] if el["type"] == result2
              end
            end

          end
          # Добавить к списку цен индивидуальную колонку
          price << hash_value[:hash_email_price][sheet_name] if hash_value[:hash_email_price][sheet_name].present?
          price = price.flatten.uniq

          # ====================================================
          # Определение дополнительного склада для подразделения
          # ====================================================
          # podrazdel << hash_value[:Podrazdelenie] # если использовать подразделение менеджера
          city << hash_value[:Gorod] # если использовать город менеджера

          # ====================================================
          # Определение списка складов для подразделения
          # ====================================================
          value["settings"]["Склады"].each do |el|

            case el["ЭтоГруппа"].downcase
            when "да"
              grup << el["Склад"]
            when "нет"
              skl << el["Склад"]
            when "city"
              city << el["Склад"]
            end

          end

          list[key] = { sheet_name: sheet_name,
                        product: product,
                        price: price,
                        podrazdel: podrazdel,
                        sheet_select_product: sheet_select_product,
                        grup: grup,
                        skl: skl,
                        city: city,
                        max_count: max_count
          }

        end
      else
        puts "Нет настроек для прайс-листа"
      end
      puts "DEBUG  list = #{list}"
      list
    end

    def format_value(value)
      if value.is_a?(Numeric)
        value = ">#{@max_count}" if value.to_i == @max_count
        format_number_with_thousands(value)
      else
        value
      end
    end

    def format_number_with_thousands(number)
      number.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1 ')
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

      email = ["postmaster@tot.biz.ua", "prokoleso_logs@tot.biz.ua",
               "test@tot.biz.ua", "test1@tot.biz.ua","pogoreltsev.iv@tot.biz.ua",
               "test2@tot.biz.ua", "test3@tot.biz.ua", "test4@tot.biz.ua"]

      email = ["svv2602@gmail.com", "snisar.vv@tot.biz.ua","pogoreltsev.iv@tot.biz.ua"]

      count_simple = 10 # количество примеров
      count_simple.times do |i|
        Partner.create!(
          Kontragent: "Контрагент #{i}",
          Email: email[rand(email.size)],
          Partner: "Партнер #{i}",
          OsnovnoiMeneger: "Менеджер #{rand(count_simple)}",
          TelefonPodrazdeleniia: "123-456-789",
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