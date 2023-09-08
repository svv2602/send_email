FROM ruby:3.2.2

RUN apt-get update && apt-get install -y build-essential

RUN gem install rails

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install


COPY . ./

# Установка часового пояса внутри контейнера
RUN ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]

# Запуск
# docker build -t send_email .
# docker run --rm -p 3000:3000 send_email