require 'httparty'
require 'spreadsheet'

class ApiController < ApplicationController
  include DataAccessMethods
  include InputDataMethods
  include ResponseAggregatorMethods
  include CreateFileXlsMethods

  after_action :delete_old_emails, only: :import_data_from_api

  def import_data_from_api
    @msg_data_load = ""
    unless DataWriteStatus.in_progress?
      DataWriteStatus.set_in_progress(true)
      import_data_load
      DataWriteStatus.set_in_progress(false)
    else
      @msg_data_load = "Процесс уже запущен"
    end
    render plain: @msg_data_load + "\n\n#{Time.now}"
  end

  def create_xls
    if list_partners_to_send_email.any?
      export_to_xls
      render plain: "Создан новый прайс  #{@file_path} \n #{Time.now}"
    else
      render plain: "Список клиентов пуст. Вы скорее всего уже сделали рассылку \n Проверьте отчет о рассылке `/report`"
    end

  end

  def send_email
    export_to_xls
    file_path = @file_path

    # Здесь указываете email получателя
    recipient_email = 'svv@invelta.com.ua'
    #==============================================================
    # Отправляем письмо с вложением
    # Заблочено - раскомментировать для отправки
    # MyMailer.send_email_with_attachment(recipient_email, file_path).deliver_now

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

    Email.delete_all # удалить в рабочей

    directory_path = "#{Rails.root}/tmp/prices/"
    FileUtils.mkdir_p(directory_path) unless Dir.exist?(directory_path)

    name_price = "price"
    @price_path = "#{directory_path}#{name_price}.xls"

    results = list_partners_to_send_email # получить список клиентов не получивших почту сегодня
    kol = 0
    i = 0
    params = nil

    # Обработка результатов
    results.each do |row|
      osnovnoi_meneger = row["OsnovnoiMeneger"]
      email = row["Email"]

      unless params == row["params"]
        # удалить старый прайс
        #  File.delete(@price_path) if File.exist?(@price_path)

        # создать новый прайс
        @hash_value = hash_value_keys_partner(row["TipKontragentaILSh"],
                                              row["TipKontragentaCMK"],
                                              row["TipKontragentaSHOP"],
                                              row["Podrazdelenie"])

        settings_price = set_price_sheet_attributes(@hash_value) # хеш настроек для создания листов прайса
        # puts "settings_price = #{settings_price}"
        kol += 1
        name_price = "price#{kol}"
        @price_path = "#{directory_path}#{name_price}.xls"
        create_book_xls

        params = row["params"]

        # удалить в рабочей
        # =================================================
        if kol >= 5
          break # Выходим из цикла, если значение равно 5
        end
        # =================================================

      end

      i += 1
    end

    render plain: "Сделано #{kol} разa для  #{i} записей"

  end

  def report
    # Получить все успешно доставленные письма за последние 7 дней
    # deliveries = Email.where('created_at > ?', Time.now - 7.days)
    if params[:send].to_i == 0
      params_send = true
      str_head = "Список адресов, ожидающих отправки:\n\n"
    else
      params_send = false
      str_head = "Список рассылок email за сегодня:\n\n"
    end
    request_report(params_send)

    render plain: str_head + @msg_data_load + "\nОтчет создан: #{Time.now}"
  end

  def attr_price
    # Получить данные и создать файлы settings.json и alias.json
    get_json_files_from_api
    render plain: @msg_data_load + "\nОтчет создан: #{Time.now}"
  end

end

