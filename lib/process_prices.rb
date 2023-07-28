require 'net/http'
require 'uri'
require 'json'
require 'active_record'

class PriceProcessor
  def request_get
    url = URI.parse('http://192.168.3.14/erp_main/hs/price/noma/')

    # Создание объекта HTTP-запроса (POST)
    request = Net::HTTP::Get.new(url.request_uri)

    # Создание объекта Net::HTTP для установки соединения и отправки запроса
    http = Net::HTTP.new(url.host, url.port)

    # Выполнение запроса и получение ответа
    response = http.request(request)
    # Парсинг данных из JSON-формата
    data = JSON.parse(response.body)

    # Вывод полученных данных
    puts data

  end


end

# PriceProcessor.delete_all_data_from_table('product')

data = PriceProcessor.new
data.request_get



