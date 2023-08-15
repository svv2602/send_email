FROM ruby:3.1.3

RUN apt-get update && apt-get install -y build-essential

RUN gem install rails

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . ./

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]

# Запуск
# docker run --rm -p 3000:3000 my-rails-app