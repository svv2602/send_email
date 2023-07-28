require 'httparty'
require_relative '../../lib/assets/db_const'

class ApiController < ApplicationController

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
    import_data_from_api_select('products', 'http://192.168.3.14/erp_main/hs/price/noma/', :Product)
    import_data_from_api_select('leftovers', 'http://192.168.3.14/erp_main/hs/price/ostatki/', :Leftover)
    import_data_from_api_select('prices', 'http://192.168.3.14/erp_main/hs/price/prices/', :Price)
  end

end
