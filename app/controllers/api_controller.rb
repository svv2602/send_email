require 'httparty'
require_relative '../../lib/assets/db_const'
require 'spreadsheet'
require_relative '../services/response_aggregator'

class ApiController < ApplicationController
  include ResponseAggregator
  after_action :delete_old_emails, only: :import_data_from_api

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
      @msg_data_load_select = "Данные #{table_key.to_s} успешно импортированы в базу данных! \n"
    else
      @msg_data_load_select = "Не удалось получить данные #{table_key.to_s} с API."
    end

    puts @msg_data_load_select
    @msg_data_load += @msg_data_load_select
  end

  def import_data_from_api
    @msg_data_load = ""
    import_data_load
    render plain: @msg_data_load

    # export_to_xls
    # generate_and_send_email

  end

  def import_data_load
    params_table = [{table_name:'products', url:'http://192.168.3.14/erp_main/hs/price/noma/', table_key: :Product},
                    {table_name:'leftovers', url:'http://192.168.3.14/erp_main/hs/price/ostatki/', table_key: :Leftover},
                    {table_name:'prices', url:'http://192.168.3.14/erp_main/hs/price/prices/', table_key: :Price},
                    {table_name:'partners', url:'http://192.168.3.14/erp_main/hs/price/kontragent/', table_key: :Partner},
    ]

    params_table.each  do | el |
      max_update_date = el[:table_key].to_s.capitalize.singularize.constantize.maximum(:updated_at)

      if max_update_date && max_update_date.to_date == Date.current
        @msg_data_load_select = "Данные #{el[:table_key].to_s} были загружены  #{max_update_date} и не требуют обновления \n"
        puts @msg_data_load_select
        @msg_data_load += @msg_data_load_select
      else
        import_data_from_api_select(el[:table_name], el[:url], el[:table_key])
        bracket_replacement if el[:table_name] == 'leftovers' # Убрать скобки в названиях складов
      end
    end

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
    @file_path = "#{Rails.root}/tmp/leftovers_with_properties.xls"
    File.open(@file_path, 'wb') { |f| f.write(xls_data.string) }
    puts "Создан новый прайс  #{@file_path}"

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

  def generate_and_send_email
    export_to_xls
    file_path = @file_path

    # Здесь указываете email получателя
    recipient_email = 'svv@invelta.com.ua'

    # Отправляем письмо с вложением
    MyMailer.send_email_with_attachment(recipient_email, file_path).deliver_now

    # Удалить временный файл
    File.delete(@file_path) if File.exist?(@file_path)

    # Отображаем результат пользователю
    render plain: 'Email sent successfully!'
  end

  def report_email
    # Получить все успешно доставленные письма за последние 7 дней
    deliveries = Email.where('created_at > ?', Time.now - 7.days)

    @msg_data_load = ""
    # Вывести email-адреса получателей
    deliveries.each do |delivery|
      @msg_data_load_select = " #{delivery.to } #{" "*20} время: #{delivery.created_at } \n"
      @msg_data_load += @msg_data_load_select
      puts @msg_data_load_select
    end

    render plain: @msg_data_load
  end

  def delete_old_emails
    days_ago = 30.days.ago
    Email.where('created_at < ?', days_ago).destroy_all
    puts "Удалены все записи из Email, старше #{days_ago} дней."
  end

end

