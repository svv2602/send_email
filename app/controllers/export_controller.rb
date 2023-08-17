require 'spreadsheet'

class ExportController < ApplicationController
  def export_to_excel
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(name: 'Sheet1')

    # Получите названия столбцов из модели
    column_names = Product.column_names
    sheet.row(0).concat(column_names)

    data = Product.all

    data.each_with_index do |record, index|
      row_data = column_names.map { |column| record[column] }
      sheet.row(index + 1).replace(row_data)
    end

    file_path = Rails.root.join('public', 'data.xlsx')
    book.write(file_path)

    send_file file_path, type: 'application/xlsx', disposition: 'attachment'
  end
end
