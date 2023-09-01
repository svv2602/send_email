require 'spreadsheet'


class ExportController < ApplicationController
  before_action :set_tab_class, only: :export_to_excel
  # after_action :delete_file_unload, only: :export_to_excel

  def export_to_excel
    if @tab_class.present?
      column_names = @tab_class.column_names

      # Используем пагинацию для извлечения данных порциями
      batch_size = 1000 # Размер пакета данных для каждой итерации
      offset = 0

      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet(name: 'Sheet1')
      sheet.row(0).concat(column_names)

      loop do
        data = @tab_class.limit(batch_size).offset(offset)

        break if data.empty?

        data.each_with_index do |record, index|
          row_data = column_names.map { |column| record[column] }
          sheet.row(offset + index + 1).replace(row_data)
        end

        offset += batch_size
      end

      @file_unload_path = Rails.root.join('tmp/data_unload', "#{@tab_class.to_s.downcase}.xls")
      book.write(@file_unload_path)

      send_file @file_unload_path, type: 'application/xls', disposition: 'attachment'

      # delete_file_unload

    else
      render plain: "Таблицы #{params[:table]} не существует\n#{Time.now}"
    end
  rescue StandardError => e
    render plain: "Произошла ошибка: #{e.message}\n#{Time.now}"
  end

  def set_tab_class
    table_name = params[:table] # Получаем имя таблицы из параметров запроса
    ActiveRecord::Base.connection.table_exists?(table_name) ? @tab_class = table_name.capitalize.singularize.constantize : @tab_class = nil
  end




  def delete_directory_with_contents(directory_path)
    FileUtils.rm_rf(directory_path) if File.directory?(directory_path)
  end

end
