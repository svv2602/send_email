require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Begin 1 ===================== 30.08.2023 =========================
# если ошибка "database is locked" (обычно пр аварийной остановке сервера при
# работающей базе SQLite), то удалить базу данных и установить новые
def setup_database_and_run_server
  db_path = select_database_path

  begin
    db = SQLite3::Database.new(db_path)
  rescue SQLite3::BusyException
    system('ruby setup_with_retry.rb')
  ensure
    db.close if db
  end
end

def select_database_path
  path = "/home/user/RubymineProjects/myProject/send_email/db/"
  if Rails.env.development?
    path + "development.sqlite3"
  elsif Rails.env.test?
    path + "/test.sqlite3"
  elsif Rails.env.production?
    path + "/production.sqlite3"
  else
    raise "Неизвестная среда: #{Rails.env}"
  end

end

setup_database_and_run_server
# end 1 ===================== 30.08.2023 =========================



module SendEmail
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    #===================15.08.2023================================
    config.after_initialize do

      if ActiveRecord::Base.connection.table_exists?('data_write_statuses')
        if DataWriteStatus.respond_to?(:in_progress?) && DataWriteStatus.respond_to?(:set_in_progress)
          DataWriteStatus.set_in_progress(false) if DataWriteStatus.in_progress?
        end
      end

    end
    #=============================================================

  end
end
