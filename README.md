# README
## Приложение для рассылки прайсов
###Внимание! ============================================
После аварийной остановки, если не запускается приложение (ошибка: "database is locked"), выполните из корня приложения:

`ruby setup_with_retry.rb`

эта команда удалит файлы баз данных, и запустит `rails db:setup` для создания чистой базы данных

###=====================================================

### endpoint

* `/import` - Получить данные из 1с по товарам, остаткам, актуальные цены и список клиентов для рассылки. Все предыдущие данные из соответствующих таблиц удаляются.
  * `/import_attr` - Получить данные и создать файлы settings.json, alias.json, dopemail и textshapka  (/lib/assets)
  * `/import_data` - Получить данные для базы данных
* `/report?send=1` или `/report` - просмотреть список отправленных писем за текущий день можно по адресу
* `/report?send=0` - просмотреть список адресов к отправке
* `/send` - Отправить прайсы тестовой группе партнеров. (изменить список можно в `app/controllers/concerns/create_file_xls_methods.rb` метод: `set_test_data_partner`)
* `/export_to_excel` - выгрузить в excel таблицу базы данных. Для выгрузки требуется указать параметр `table`
  * пример: `http://127.0.0.1:3000/export_to_excel?table=partners` (имена таблиц как в базе данных)

#### Внимание!
* `/send?production=1` - Отправить прайсы по списку из 1с8. Для каждой группы клиентов формируется и отправляется свой прайс. При повторном запуске в течении дня отправка писем только тем, у кого нет записи в таблице Email с текущей датой


#### Установить файлы с настройками прайсов (раскомментировать нужное):
    # #`app/controllers/api_controller.rb`
    #  def send_emails
    # ...
    # ================================================================
    # Путь к файлам lib/assets/
    # Использовать тестовые файлы:
    # set_json_files_path("price_settings_copy", "price_aliases_copy")

    # Использовать файлы, полученные по API
    # set_json_files_path("price_settings", "price_aliases")
    # ================================================================
    # ...
    # end


### +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
### Настройка в `app/controllers/concerns/input_data_methods.rb`
* адреса API для загрузки данных прописаны  в `params_table`
* адреса API для загрузки настроек создаются в `get_json_files_from_api`
* соответствие названий столбцов в базе данных столбцам API в `db_columns`

Внимание! При необходимости добавить:

* новое поле из API в базу данных  - нужно сделать новую  миграцию и и установить соответствие в `db_columns`  
* добавить новую таблицу из API в базу данных  - нужно нужно сделать новую  миграцию, добавить новый элемент в `db_columns` и установить соответствие названий, внести данные в `params_table`

### Настройка тестового списка партнеров в `app/controllers/concerns/create_file_xls_methods.rb`
* данные для создания партнеров находятся в трех массивах `podrazdelenie`, `type` и `email`
* в цикле создается 10 записей в таблицу Partner
* Важно: метка `test: true` - для определения тестовых данных


### Основные настройки почты
* config/environments/development.rb
* config/environments/production.rb

### Изменение текста письма для рассылки 
* `app/views/my_mailer/send_email_with_attachment.html.erb`

### Настройки почты в app/mailers/my_mailer.rb
* `default from:` - аттрибуты по умолчанию
* `unsubscribe_url` - адрес для отписки от рассылки в методе `send_email_with_attachment`

### Получение списка клиентов для рассылки
*  в app/controllers/concerns/data_access_methods.rb запрос в методе `list_partners_to_send_email` 
(отбираются только те клиенты, которым за текущий день еще не отправлялись прайсы)


* ...


