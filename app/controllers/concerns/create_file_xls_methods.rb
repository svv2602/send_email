module CreateFileXlsMethods
  extend ActiveSupport::Concern

  included do
    def export_to_xls
      set_sheet_params

      # Получить хеш с для построения запроса
      hash_with_params_sklad = hash_query_params_all(@skl, @grup, @podrazdel, @price, @product, @max_count, @sheet_select)

      results = build_leftovers_combined_query(hash_with_params_sklad)

      grouped_results = results.group(:artikul, :Tovar_Kategoriya)
                               .select(hash_grouped_name_collumns(hash_with_params_sklad)[:attr_query])

      # Создание объекта для XLS-файла
      xls_file = Spreadsheet::Workbook.new
      xls_sheet = xls_file.create_worksheet(name: @sheet_name)

      # Создание стиля для зеленого фона
      green_background = Spreadsheet::Format.new(color: :white, pattern: 1,
                                                 pattern_fg_color: :green,
                                                 border: :thin)
      # Создание стиля с границей
      border_style = Spreadsheet::Format.new(border: :thin, color: :black)

      # Добавление заголовков в таблицу XLS
      column_names = hash_grouped_name_collumns(hash_with_params_sklad)[:attr_query_name_collumn]
      xls_sheet.row(0).concat column_names

      # Применение стиля к каждой ячейке заголовков, если она содержит значение
      column_names.each_with_index do |value, col_index|
        if value.present?
          xls_sheet.row(0).set_format(col_index, green_background)
        end
      end

      # Заполнение таблицы данными
      grouped_results.each_with_index do |leftover, index|
        row_values = column_names.map { |column| leftover.send(column) }
        xls_sheet.row(index + 1).push(*row_values)

        # Применение стиля с границей к каждой ячейке в строках с данными
        row_values.each_with_index do |cell_value, col_index|
          xls_sheet.row(index + 1).set_format(col_index, border_style)
        end
      end

      xls_data = StringIO.new
      xls_file.write xls_data

      # Сохраняем файл на сервере
      @file_path = "#{Rails.root}/tmp/prices/leftovers_with_properties.xls"
      File.open(@file_path, 'wb') { |f| f.write(xls_data.string) }
      puts "Создан новый прайс  #{@file_path} \n #{Time.now}"

    end

    def create_book_xls(arr)
      #
      #      из контрагента получить
      #        TipKontragentaILSh , TipKontragentaCMK , TipKontragentaSHOP , Podrazdelenie
      #
      # При первой обработке json с параметрами листов создать массив(может хеш) с названиями листов
      # Дальнейшая обработка - итерация по массиву
      # установить параметры для каждого листа
      #        Настройки получить из json и сделать 5 переменных с настройками
      #        добавить доп цены для каждого типа контрагента (может быть стоит разобрать, получаем как массив)
      #       добавить склад для Podrazdelenie

    end

    def hash_value_keys_partner(tk_ilsh, tk_cmk, tk_shop, skl_pdrzd)
      { TipKontragentaILSh: tk_ilsh,
        TipKontragentaCMK: tk_cmk,
        TipKontragentaSHOP: tk_shop,
        Podrazdelenie: skl_pdrzd
      }
    end

    def set_price_sheet_attributes
      tabPartner = db_columns[:Partner]

      hash_value_keys_partner = { TipKontragentaILSh: "B2B",
                                  TipKontragentaCMK: "B2C более 50 т.с",
                                  TipKontragentaSHOP: "Автоимпортер",
                                  Podrazdelenie: "ТСЦ-04 К (Киев, Оболонь)"
      }

      file_path = "#{Rails.root}/tmp/prices/price_settings.json"
      json_string = File.read(file_path)

      hash_settings = JSON.parse(json_string) # test_setting
      #===========================================================
      hash_settings = test_setting
      # временные переменные, заменить на получаемые по API
      # ===========================================================

      list = {}
      if hash_settings

        hash_settings.each do |key, value|
          sheet_name = ""
          skl = []
          grup = []
          podrazdel = []
          price = []
          product = []
          sheet_select_product = {}
          max_count = 0

          # ====================================================
          # Название листа в файле и максимальное количество
          # ====================================================
          sheet_name = value[:name] || key.to_s
          max_count = value[:items].to_i

          # ====================================================
          # Массив свойств номенлатуры
          # ====================================================
          product = value[:settings].is_a?(Hash) && value[:settings][:Свойства] ? value[:settings][:Свойства] : []

          # ====================================================
          # Определение фильтров по видам номенклатуры и категоий товара
          # ====================================================
          ktg = value[:settings].is_a?(Hash) && value[:settings][:ТоварнаяКатегория] ? value[:settings][:ТоварнаяКатегория] : []
          vid = value[:settings].is_a?(Hash) && value[:settings][:ВидНоменклатуры] ? value[:settings][:ВидНоменклатуры] : []

          sheet_select_product = {
            TovarnayaKategoriya: ktg,
            VidNomenklatury: vid
          }

          # ====================================================
          # Определение типов цен для контрагента по листам
          # ====================================================

          if value[:settings][:ТипыЦен].is_a?(Hash) && value[:settings][:ТипыЦен]
            if value[:settings][:ТипыЦен][:maintype]
              result = value[:settings][:ТипыЦен][:maintype].downcase
              result2 = tabPartner.find { |key, value| value.downcase == result }
            else
              result2 = ""
            end

            value[:settings][:ТипыЦен][:settings].each do |el|
              el.each do |key, value|
                price << el[:default] if key == :default
                price << el[:prices] if el[:type] == result2
              end
            end
            price = price.flatten.uniq
          else
            price = []
          end

          # ====================================================
          # Определение дополнительного склада для подразделения
          # ====================================================
          podrazdel << hash_value_keys_partner[:Podrazdelenie]

          value[:settings][:Склады].each do |el|
            el[:ЭтоГруппа] == "Да" ? grup << el[:Склад] : skl << el[:Склад]
          end

          list[key] = { sheet_name: sheet_name,
                        product: product,
                        price: price,
                        podrazdel: podrazdel,
                        sheet_select_product: sheet_select_product,
                        grup: grup,
                        skl: skl,
                        max_count: max_count
          }
          # puts list
        end
      else
        puts "Нет настроек для прайс-листа"
      end

      list
    end

    def test_setting
      {
        "list1": {
          "settings": {
            "Свойства": [
              "Индекс нагрузки",
              "Индекс скорости",
              "Индекс слойности",
              "Модель",
              "Размер",
              "Производитель",
              "СезоннаяГруппа"
            ],
            "ВидНоменклатуры": [
              "легковые"
            ],
            "Склады": [
              {
                "Склад": "ОСПП и ТСС",
                "ЭтоГруппа": "Да"
              },
              {
                "Склад": "РОЗНИЦА",
                "ЭтоГруппа": "Да"
              }
            ],
            "ТипыЦен": {
              "maintype": "ТипконтрагентаИЛШ",
              "settings": [
                {
                  "default": [
                    "Интернет",
                    "База"
                  ]
                },
                {
                  "type": "B2B",
                  "prices": [
                    "Опт"
                  ]
                },
                {
                  "type": "B2C более 50 т.с",
                  "prices": [
                    "Спец А"
                  ]
                },
                {
                  "type": "B2C до 50 т.с.",
                  "prices": [
                    "Спец Б"
                  ]
                },
                {
                  "type": "Автоимпортер",
                  "prices": [
                    "Спец С"
                  ]
                },
                {
                  "type": "Автосалон",
                  "prices": [
                    "Спец С"
                  ]
                },
                {
                  "type": "Автосборочное предприятие",
                  "prices": [
                    "Спец Б"
                  ]
                },
                {
                  "type": "Агрохолдинг",
                  "prices": [
                    "Спец С"
                  ]
                },
                {
                  "type": "Гос.организация",
                  "prices": [
                    "Тендер"
                  ]
                },
                {
                  "type": "Интернет платформа",
                  "prices": [
                    "Маг3"
                  ]
                },
                {
                  "type": "Интернет-магазин",
                  "prices": [
                    "Интернет"
                  ]
                },
                {
                  "type": "УкрОборонПром",
                  "prices": [
                    "Спец С"
                  ]
                }
              ]
            }
          },
          "name": "Легковые шины",
          "items": "12"
        },
        "list2": {
          "settings": {
            "Свойства": [
              "DIA диска",
              "PCD диска",
              "Вылет диска ET",
              "Ширина диска",
              "Производитель"
            ],
            "ВидНоменклатуры": [
              "диски"
            ],
            "Склады": [
              {
                "Склад": "ОСПП и ТСС",
                "ЭтоГруппа": "Да"
              },
              {
                "Склад": "РОЗНИЦА",
                "ЭтоГруппа": "Да"
              }
            ],
            "ТипыЦен": {
              "maintype": "ТипконтрагентаИЛШ",
              "settings": [
                {
                  "default": [
                    "База",
                    "Розница"
                  ]
                }
              ]
            }
          },
          "name": "Диски",
          "items": "4"
        },
        "list3": {
          "settings": {
            "Свойства": [
              "Размер",
              "Тип каркаса",
              "Тип шины",
              "Производитель",
              "СезоннаяГруппа"
            ],
            "ВидНоменклатуры": [
              "грузовые",
              "грузовые импортные",
              "грузовые отечественные"
            ],
            "Склады": [
              {
                "Склад": "ОСПП и ТСС",
                "ЭтоГруппа": "Да"
              },
              {
                "Склад": "РОЗНИЦА",
                "ЭтоГруппа": "Да"
              },
              {
                "Склад": "",
                "ЭтоГруппа": ""
              }
            ],
            "ТипыЦен": {
              "maintype": "ТипконтрагентаЦМК",
              "settings": [
                {
                  "default": [
                    "Опт",
                    "Мин",
                    "Розница"
                  ]
                }
              ]
            }
          },
          "name": "Грузовые шины",
          "items": "4"
        },
        "list4": {
          "settings": {
            "Свойства": [
              "Размер",
              "Тип каркаса",
              "Тип шины",
              "Производитель"
            ],
            "ВидНоменклатуры": [
              "грузовые диски"
            ],
            "Склады": [
              {
                "Склад": "ОСПП и ТСС",
                "ЭтоГруппа": "Да"
              },
              {
                "Склад": "РОЗНИЦА",
                "ЭтоГруппа": "Да"
              }
            ],
            "ТипыЦен": ""
          },
          "name": "Грузовые диски",
          "items": "4"
        },
        "list5": {
          "settings": {
            "Свойства": [
              "Размер",
              "Тип каркаса",
              "Тип шины",
              "Производитель"
            ],
            "ВидНоменклатуры": [
              "с/х"
            ],
            "Склады": [
              {
                "Склад": "ОСПП и ТСС",
                "ЭтоГруппа": "Да"
              },
              {
                "Склад": "РОЗНИЦА",
                "ЭтоГруппа": "Да"
              }
            ],
            "ТипыЦен": ""
          },
          "name": "СХ",
          "items": "6"
        }
      }

      #====================================================================
    end
  end

end