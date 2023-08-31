require 'spreadsheet'

class ExportController < ApplicationController
  before_action :set_tab_class, only: :export_to_excel
  after_action :delete_file_unload, only: :export_to_excel
  def export_to_excel
    puts "@tab_class = #{@tab_class}"
    if @tab_class.present?

      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet(name: 'Sheet1')

      # Получите названия столбцов из модели
      column_names = @tab_class.column_names
      sheet.row(0).concat(column_names)

      data = @tab_class.all

      data.each_with_index do |record, index|
        row_data = column_names.map { |column| record[column] }
        sheet.row(index + 1).replace(row_data)
      end

      @file_unload_path = Rails.root.join('tmp', "#{@tab_class.to_s.downcase}.xls")
      book.write(@file_unload_path)

      send_file @file_unload_path, type: 'application/xls', disposition: 'attachment'
    else
      render plain: "Таблицы не существует \n#{Time.now}"
    end
  end

  def set_tab_class
    table_name = params[:table] # Получаем имя таблицы из параметров запроса
    ActiveRecord::Base.connection.table_exists?(table_name) ? @tab_class = table_name.capitalize.singularize.constantize : @tab_class = nil
  end

  def delete_file_unload
    File.delete(@file_unload_path) if File.exist?(@file_unload_path)
  end




end
