require 'redcarpet'

class ReadmeController < ApplicationController
  def show
    # Путь к файлу Readme.md, здесь предполагается, что файл находится в корне проекта
    readme_path = Rails.root.join('README.md')
    # readme_path = Rails.root.join('send_email', 'Readme.md')
    # Чтение содержимого файла
    readme_content = File.read(readme_path)

    # Инициализация парсера Markdown
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

    # Преобразование Markdown в HTML
    @rendered_markdown = markdown.render(readme_content)
  end
end