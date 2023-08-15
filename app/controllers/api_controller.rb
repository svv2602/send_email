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

  def send_emails_to_partners
    if list_partners_to_send_email.any?
      create_and_send_price_to_partner_groups
      render plain: "Процесс рассылки писем закончен  #{@file_path} \n #{Time.now}"
    else
      render plain: "Список клиентов пуст. Вы скорее всего уже сделали рассылку \n Проверьте отчет о рассылке `/report`"
    end

  end

  def delete_old_emails
    days_ago = 30.days.ago
    Email.where('created_at < ?', days_ago).destroy_all
    puts "Удалены все записи из Email, старше #{days_ago} дней."
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

