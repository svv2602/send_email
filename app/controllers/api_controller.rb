require 'httparty'
require 'spreadsheet'

class ApiController < ApplicationController
  include DataAccessMethods
  include InputDataMethods
  include ResponseAggregatorMethods
  include CreateFileXlsMethods

  after_action :delete_old_emails, only: :import_data_from_api
  before_action :set_msg_data_load, only: %i[import_data_from_api send_emails import_attr import_data report]

  def import_data_from_api
    run_import_data_from_api
    render plain: @msg_data_load + "\n\n#{Time.now}"
  end

  def run_import_data_from_api
    run_methods(:import_data_load, :get_json_files_from_api)
  end

  def send_emails_to_partners
    if list_partners_to_send_email.any?
      create_and_send_price_to_partner_groups
      @msg_data_load += "Процесс рассылки писем закончен  #{@file_path} "
    else
      @msg_data_load += "Список клиентов пуст. Вы скорее всего уже сделали рассылку \n Проверьте отчет о рассылке `/report`"
    end
  end

  def send_emails
    # Получить данные
    run_import_data_from_api

    # Установить файлы с настройками прайсов (раскомментировать нужное):
    # ================================================================
    # Путь к файлам lib/assets/
    # Использовать тестовые файлы
    set_json_files_path("test_price_settings", "test_price_aliases",
                        "test_price_dopemail", "test_price_textshapka" )

    # Использовать файлы, полученные по API
    # set_json_files_path("price_settings", "price_aliases", "price_dopemail", "price_textshapka")
    # ================================================================

    # Проверка, если Без параметров - отправка тестовому списку клиентов
    set_test_data unless params[:production].to_i == 1

    # Выполнить отправку  почты
    run_methods(:send_emails_to_partners)
    render plain: @msg_data_load + "\n\n #{Time.now}"
  end

  def delete_old_emails
    days_ago = 30.days.ago
    Email.where('created_at < ?', days_ago).destroy_all
    puts "Удалены все записи из Email, старше #{days_ago} дней."
  end

  def report
    if params[:send].to_i == 0
      params_send = true
      str_head = "Список адресов, ожидающих отправки:\n\n"
    else
      params_send = false
      str_head = "Список рассылок email за сегодня:\n\n"
    end
    request = request_report(params_send)

    if request.count == 0
      @msg_data_load = "в базе нет данных\n\n"
    else
      report_out(request, params_send)
    end

    render plain: str_head + @msg_data_load + "\nОтчет создан: #{Time.now}"
  end

  def import_attr
    # Получить данные и создать файлы settings.json и alias.json
    run_methods(:get_json_files_from_api)
    render plain: @msg_data_load + "\nОтчет создан: #{Time.now}"
  end

  def import_data
    # Получить данные в базу данных
    run_methods(:import_data_load)
    render plain: @msg_data_load + "\nОтчет создан: #{Time.now}"

  end
  def set_msg_data_load
    @msg_data_load = ""
  end

  def run_methods(*method_names)
    unless DataWriteStatus.in_progress?
      DataWriteStatus.set_in_progress(true)

      method_names.each do |method_name|
        if respond_to?(method_name)
          send(method_name)
        else
          puts "Метод #{method_name} не существует"
        end
      end

      DataWriteStatus.set_in_progress(false)
    else
      @msg_data_load = "Процесс уже запущен"
    end
    @msg_data_load
  end

end

