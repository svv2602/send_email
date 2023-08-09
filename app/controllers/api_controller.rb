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

  # def grouped_vidceny
  #   Price.group(:Vidceny).order(:Vidceny).pluck(:Vidceny)
  # end

  def send_email
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
    Email.delete_all
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
      export_to_xls if kol < 2
      # Ваш код обработки для каждой строки
      # Например, вы можете использовать эти значения для отправки писем или других действий
      puts "OsnovnoiMeneger: #{osnovnoi_meneger}, Email: #{email}, TipKontragentaILSh: #{tip_kontragenta_ilsh}, TipKontragentaCMK: #{tip_kontragenta_cmk}, TipKontragentaSHOP: #{tip_kontragenta_shop}, Podrazdelenie: #{podrazdelenie}"
      Email.create(to: email, subject: "прайс№ #{kol}", body: "OsnovnoiMeneger: #{osnovnoi_meneger}, Podrazdelenie: #{podrazdelenie}", delivered: true)
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

end

