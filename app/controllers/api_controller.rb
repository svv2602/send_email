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
            # Обработка ошибок сохранения, если необходимо
            puts "Ошибка сохранения продукта: #{product.errors.full_messages.join(', ')}"
            raise ActiveRecord::Rollback # Откатим транзакцию в случае ошибки
          end
        end
      end

      puts "Данные #{table_key.to_s} успешно импортированы в базу данных!"
    else
      puts "Не удалось получить данные #{table_key.to_s} с API."
    end
    # redirect_to root_path
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


    grouped_results = build_leftovers_combined_query_new.group(:artikul).select(
      "artikul",
      "Nomenklatura",
      "Razmer",
      "Indeksnagruzki",
      "TovarnayaKategoriya",
      "Proizvoditel",
      "VidNomenklatury",
      "TipTovara",
      "SezonnayaGruppa",
      "SUM(Cena_0) as  Cena_0",
      "SUM( Cena_1) as  Cena_1",
      "SUM( Cena_2) as  Cena_2",
      "SUM( Cena_3) as  Cena_3",
      "SUM( Cena_4) as  Cena_4",
      "SUM( Sklad_0) as  Sklad_0",
      "SUM( Sklad_1) as  Sklad_1",
      "SUM( Sklad_2) as Sklad_2"

    )


    # Создание объекта для XLS-файла
    xls_file = Spreadsheet::Workbook.new
    xls_sheet = xls_file.create_worksheet(name: 'Leftovers')

    # Добавление заголовков в таблицу XLS
    xls_sheet.row(0).concat ['Artikul','Nomenklatura', 'Razmer' ,'Indeksnagruzki' , 'TovarnayaKategoriya','Днепр', 'ОСПП', 'РОЗНИЦА', 'Mag','Spec','Opt']

    # Генерация файла и отправка клиенту
    file_path = "#{Rails.root}/tmp/leftovers_with_properties.xls"



   # Заполнение таблицы данными
    grouped_results.each_with_index do |leftover, index|
      xls_sheet.row(index + 1).push(
        leftover.artikul,
        leftover.Nomenklatura,
        leftover.Proizvoditel,
        leftover.VidNomenklatury,
        leftover.TipTovara,
        leftover.SezonnayaGruppa,
        leftover.Razmer,
        leftover.Indeksnagruzki,
        leftover.TovarnayaKategoriya,
        leftover['Cena_0'],
        leftover['Cena_1'],
        leftover['Cena_2'],
        leftover['Cena_3'],
        leftover['Cena_4'],
        leftover['Sklad_0'],
        leftover['Sklad_1'],
        leftover['Sklad_2']
      )
    end

    xls_file.write file_path

    send_file file_path, filename: 'leftovers_with_properties.xls', type: 'application/vnd.ms-excel', disposition: 'attachment'
  end

  def grouped_vidceny
    group = Price.group(:Vidceny).order(:Vidceny).pluck(:Vidceny)
  end

  def build_leftovers_combined_query_new
    strSql = 'products.*'
    query1_select_sklad

    leftover_query = Leftover.joins(:product)
                             .select("Leftovers.Artikul as artikul,
                                    #{query1_select_sklad},
                                    #{query1_select_price(grouped_vidceny)},
                                    #{strSql}")
                             .where("#{query1_where_sklad}")
                             .group("Leftovers.Artikul, products.TovarnayaKategoriya")

    price_query = Price.joins(:product)
                       .select("Prices.Artikul as artikul,
                              #{query2_select_sklad},
                              #{query2_select_price(grouped_vidceny)},
                              #{strSql}")
                       .where("#{query2_where_price(grouped_vidceny)}")
                       .group("Prices.Artikul, products.TovarnayaKategoriya")


    @combined_results = Leftover.from("(#{leftover_query.to_sql} UNION #{price_query.to_sql}) AS leftovers_combined")
                                .order("leftovers_combined.TovarnayaKategoriya, leftovers_combined.artikul")



  end



end

