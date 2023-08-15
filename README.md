# README
### Приложение для рассылки прайсов

### endpoint
* `/test` - Отправить прайсы тестовой группе партнеров. (изменить список в app/controllers/concerns/create_file_xls_methods.rb метод: set_test_data_partner)
* `/import` - Получить данные из 1с по товарам, остаткам, актуальные цены и список клиентов для рассылки. Все предыдущие данные из соответствующих таблиц удаляются.
  * `/import_attr` - Получить данные и создать файлы settings.json и alias.json ()
  * `/import_data` - Получить данные для базы данных
* `/send` - Отправить прайсы. Для каждой группы клиентов формируется и отправляется свой прайс. При повторном запуске в течении дня отправка писем только тем, у кого нет записи в таблице Email с текущей датой
* `/report?send=1` или `/report` - просмотреть список отправленных писем за текущий день можно по адресу 
* `/report?send=0` - просмотреть список адресов к отправке 


## !!! В производстве необходимо
* в `def grup_partner` установить рабочие назавания json-файлов в `set_json_files_path("price_settings_copy", "price_aliases_copy")` 
* в `def grup_partner` удалить Email.delete_all и  test_data_partner


#### ======================================================================
### Настройка в app/controllers/concerns/input_data_methods.rb
* адреса API для загрузки в прописаны  в `params_table`
* соответствие названий столбцов в базе данных столбцам API в `db_columns`

Внимание! При необходимости добавить:

* новое поле из API в базу данных  - нужно сделать новую  миграцию и и установить соответствие в `db_columns`  
* добавить новую таблицу из API в базу данных  - нужно нужно сделать новую  миграцию, добавить новый элемент в `db_columns` и установить соответствие названий, внести данные в `params_table`

### Основные настройки почты
* config/environments/development.rb
* config/environments/production.rb

### Настройки почты в app/mailers/my_mailer.rb
* `default from:` - аттрибуты по умолчанию
* `unsubscribe_url` - адрес для отписки от рассылки в методе `send_email_with_attachment`

### Получение списка клиентов для рассылки
*  в app/controllers/concerns/data_access_methods.rb запрос в методе list_partners_to_send_email 
(отбираются только те клиенты, которым за текущий день еще не отправлялись прайсы)


* ...
