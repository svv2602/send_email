require 'httparty'
require_relative '../../lib/assets/db_const'
require 'spreadsheet'
require_relative '../services/response_aggregator'

class ApiController < ApplicationController
  include ResponseAggregator

  def import_data_from_api_select(table_name, url, table_key)
    response = HTTParty.get(url)
    if response.code == 200
      product_class = table_name.capitalize.singularize.constantize

      product_class.delete_all
      data = JSON.parse(response.body)
      product_class.transaction do
        data.each do |json_data|
          product = product_class.new
          DB_COLUMNS[table_key].each do |column_key, column_name|
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

      puts "Данные #{table_key.to_s} успешно импортированы в базу данных!"
    else
      puts "Не удалось получить данные #{table_key.to_s} с API."
    end

  end

  def import_data_from_api
    # import_data_load
    export_to_xls

  end

  def import_data_load
    import_data_from_api_select('products', 'http://192.168.3.14/erp_main/hs/price/noma/', :Product)
    import_data_from_api_select('leftovers', 'http://192.168.3.14/erp_main/hs/price/ostatki/', :Leftover)
    import_data_from_api_select('prices', 'http://192.168.3.14/erp_main/hs/price/prices/', :Price)
    import_data_from_api_select('partners', 'http://192.168.3.14/erp_main/hs/price/kontragent/', :Partner)
    bracket_replacement
  end

  def bracket_replacement
    ActiveRecord::Base.connection.execute("UPDATE leftovers SET Sklad = REPLACE(Sklad, '(', '') WHERE Sklad LIKE '%(%'")
    ActiveRecord::Base.connection.execute("UPDATE leftovers SET Sklad = REPLACE(Sklad, ')', '') WHERE Sklad LIKE '%)%'")
  end



  def export_to_xls

    set_sheet_params

    # Получить хеш с для построения запроса
    hash_with_params_sklad = hash_query_params_all(@skl, @grup, @price, @product, @max_count)

    results = build_leftovers_combined_query(hash_with_params_sklad)
    grouped_results = results.group(:artikul)
                             .select( hash_grouped_name_collumns(hash_with_params_sklad)[:attr_query])

    # Создание объекта для XLS-файла
    xls_file = Spreadsheet::Workbook.new
    xls_sheet = xls_file.create_worksheet(name: @sheet_name)

    # Добавление заголовков в таблицу XLS
    column_names = hash_grouped_name_collumns(hash_with_params_sklad)[:attr_query_name_collumn]

    xls_sheet.row(0).concat column_names

    # Генерация файла и отправка клиенту
    file_path = "#{Rails.root}/tmp/leftovers_with_properties.xls"

    # Заполнение таблицы данными
    grouped_results.each_with_index do |leftover, index|
      row_values = column_names.map { |column| leftover.send(column) }
      xls_sheet.row(index + 1).push(*row_values)
    end

    xls_file.write file_path

    send_file file_path, filename: 'leftovers_with_properties.xls', type: 'application/vnd.ms-excel', disposition: 'attachment'
  end

  def grouped_vidceny
    Price.group(:Vidceny).order(:Vidceny).pluck(:Vidceny)
  end

  def set_sheet_params
    # временные переменные, заменить на получаемые по API
    @sheet_name = "Легковая шина"
    @skl = ['Винница ОСПП оптовый склад','Главный склад Днепр  оптовый склад'].uniq
    @grup = ['ОСПП и ТСС', 'РОЗНИЦА'].uniq
    @price = ["Интернет", "Мин", "Опт", "Спец С", "Интернет", "Мин", "Опт", "Спец С"].uniq
    @product = ["id","Artikul","Nomenklatura", "Ves", "Artikul","Nomenklatura", "Ves", "Proizvoditel", "VidNomenklatury", "TipTovara", "TovarnayaKategoriya"].uniq
    @max_count = 20
  end

end

