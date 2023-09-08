require_relative "boot"

require "rails/all"
require 'fileutils'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

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

    config.time_zone = 'Kyiv'

    #===================15.08.2023================================
    config.after_initialize do
      def create_directory_if_not_exists(directory_path)
        FileUtils.mkdir_p(directory_path) unless File.directory?(directory_path)
      end
      create_directory_if_not_exists("./tmp/data_unload")
      if ActiveRecord::Base.connection.table_exists?('data_write_statuses')
        if DataWriteStatus.respond_to?(:in_progress?) && DataWriteStatus.respond_to?(:set_in_progress)
          DataWriteStatus.set_in_progress(false) if DataWriteStatus.in_progress?
        end
      end

    end
    #=============================================================

    at_exit do
      directory_path = './tmp/data_unload'
      if File.directory?(directory_path)
        FileUtils.rm_rf(directory_path)
        puts "Папка #{directory_path} успешно удалена при завершении приложения."
      end
    end
  end
end
