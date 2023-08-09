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



#====================================================================
  end
end