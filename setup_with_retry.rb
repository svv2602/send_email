#!/usr/bin/env ruby

# Удаление файлов всех баз данных (при необходимости)
files_to_delete = Dir.glob("./db/*.sqlite3")

files_to_delete.each do |file_path|
  File.delete(file_path)
  puts "Удален файл: #{file_path}"
end

# Запуск rails db:setup
system('bundle exec rails db:setup')
