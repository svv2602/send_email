# README

### Приложение для рассылки прайсов

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
(отбираются только те клиенты, которым за сегодня еще не отправлялись прайсы)
* просмотреть список отправленных можно по адресу `/report?send=1` или `/report`
* просмотреть список адресов к отправке `/report?send=0`


* ...
