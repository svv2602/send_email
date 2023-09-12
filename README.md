# README
## Приложение для рассылки прайсов

### endpoint

* `/import` - Получить данные из 1с по товарам, остаткам, актуальные цены и список клиентов для рассылки. Все предыдущие данные из соответствующих таблиц удаляются.
  * `/import_attr` - Получить данные и создать файлы settings.json, alias.json, dopemail и textshapka  (/lib/assets)
  * `/import_data` - Получить данные для базы данных (без проверки по дате загрузки данных)
* `/report?send=1` или `/report` - просмотреть список отправленных писем за текущий день можно по адресу
* `/report?send=0` - просмотреть список адресов к отправке
* `/send` - Отправить прайсы тестовой группе партнеров. (изменить список можно в `app/controllers/concerns/create_file_xls_methods.rb` метод: `set_test_data_partner`)
* `/export_to_excel` - выгрузить в excel таблицу базы данных. Для выгрузки требуется указать параметр `table`
  * пример для таблицы партнеров: `/export_to_excel?table=partners` (имена таблиц в базе данных: products, emails, partners, leftovers, prices)

#### Внимание!
* `/send?production=1` - Отправить прайсы по списку из 1с8. Для каждой группы клиентов формируется и отправляется свой прайс. При повторном запуске в течении дня отправка писем только тем, у кого нет записи в таблице Email с текущей датой

### +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
### Настройка в `app/controllers/concerns/input_data_methods.rb`
* адреса API для загрузки данных прописаны  в `params_table`
* адреса API для загрузки настроек создаются в `get_json_files_from_api`
* соответствие названий столбцов в базе данных столбцам API в `db_columns`

Внимание! При необходимости добавить:

* новое поле из API в базу данных  - нужно сделать новую  миграцию и установить соответствие в `db_columns`  
* добавить новую таблицу из API в базу данных  - нужно нужно сделать новую  миграцию, добавить новый элемент в `db_columns` и установить соответствие названий, внести данные в `params_table`

### Настройка тестового списка партнеров в `app/controllers/concerns/create_file_xls_data_test.rb`
* данные для создания партнеров находятся в массивах `podrazdelenie`, `city`, `type` и `email`
* в цикле создается `count_simple` записей в таблицу Partner
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

###Внимание! ============================================
После аварийной остановки, если не запускается приложение (ошибка: "database is locked"), выполните из корня приложения:

`ruby setup_with_retry.rb`

эта команда удалит файлы баз данных (будет утерян список email, уже получивших рассылку), и запустит

* `bundle exec rails db:setup`
* `bundle exec rails db:setup RAILS_ENV=production`

для создания новых баз данных. При запуске рассылки, прайсы будут заново отправлены всему списку email

###=====================================================




