require 'httparty'
require 'spreadsheet'

class ApiController < ApplicationController
  include DataAccessMethods
  include InputDataMethods
  include ResponseAggregatorMethods
  after_action :delete_old_emails, only: :import_data_from_api

  def import_data_from_api
    @msg_data_load = ""
    import_data_load
    render plain: @msg_data_load + "\n #{Time.now}"
  end

  def create_xls
    if list_partners_to_send_email.any?
      export_to_xls
      render plain: "Создан новый прайс  #{@file_path} \n #{Time.now}"
    else
      render plain: "Список клиентов пуст. Вы скорее всего уже сделали рассылку \n Проверьте отчет о рассылке `/report`"
    end

  end

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
    @file_path = "#{Rails.root}/tmp/leftovers_with_properties.xls"
    File.open(@file_path, 'wb') { |f| f.write(xls_data.string) }
    puts "Создан новый прайс  #{@file_path} \n #{Time.now}"

  end

  # def grouped_vidceny
  #   Price.group(:Vidceny).order(:Vidceny).pluck(:Vidceny)
  # end

  def generate_and_send_email
    export_to_xls
    file_path = @file_path

    # Здесь указываете email получателя
    recipient_email = 'svv@invelta.com.ua'
    #==============================================================
    # Отправляем письмо с вложением
    # Заблочено - раскомментировать для отправки
    MyMailer.send_email_with_attachment(recipient_email, file_path).deliver_now

    # Удалить временный файл
    File.delete(@file_path) if File.exist?(@file_path)
    #==============================================================

    # Отображаем результат пользователю
    render plain: 'Email sent successfully!'
  end

  def delete_old_emails
    days_ago = 30.days.ago
    Email.where('created_at < ?', days_ago).destroy_all
    puts "Удалены все записи из Email, старше #{days_ago} дней."
  end

  def grup_partner
    # Email.delete_all
    results = list_partners_to_send_email
    kol = 0
    i = 0
    params = nil

    # Обработка результатов
    results.each do |row|
      osnovnoi_meneger = row["OsnovnoiMeneger"]
      email = row["Email"]
      tip_kontragenta_ilsh = row["TipKontragentaILSh"]
      tip_kontragenta_cmk = row["TipKontragentaCMK"]
      tip_kontragenta_shop = row["TipKontragentaSHOP"]
      podrazdelenie = row["Podrazdelenie"]

      unless params == row["params"]
        # удалить старый прайс
        # создать новый
        params = row["params"]
        kol += 1
      end
      # Ваш код обработки для каждой строки
      # Например, вы можете использовать эти значения для отправки писем или других действий
      puts "OsnovnoiMeneger: #{osnovnoi_meneger}, Email: #{email}, TipKontragentaILSh: #{tip_kontragenta_ilsh}, TipKontragentaCMK: #{tip_kontragenta_cmk}, TipKontragentaSHOP: #{tip_kontragenta_shop}, Podrazdelenie: #{podrazdelenie}"
      Email.create(to: email, subject: "прайс№ #{kol}", body: "OsnovnoiMeneger: #{osnovnoi_meneger}, Podrazdelenie: #{podrazdelenie}", delivered: true)
      i += 1
    end

    render plain: "Сделано #{kol} разa для  #{i} записей"

  end

  def report_email
    # Получить все успешно доставленные письма за последние 7 дней
    # deliveries = Email.where('created_at > ?', Time.now - 7.days)
    deliveries = Email.where("DATE(emails.created_at) = DATE('now')")

    @msg_data_load = ""
    # Вывести email-адреса получателей
    deliveries.each_with_index do |delivery, i|
      ind = i < 10 ** 10 ? 11 - (i + 1).to_s.length.to_i : 1
      @msg_data_load_select = "#{i + 1}: #{delivery.created_at } #{" " * ind} #{delivery.to }; #{delivery.body }\n"
      @msg_data_load += @msg_data_load_select
      puts @msg_data_load_select
    end

    render plain: "Список рассылок email за сегодня:\n\n" + @msg_data_load + "\nОтчет создан: #{Time.now}"
  end

end

