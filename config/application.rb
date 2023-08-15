require_relative "boot"

require "rails/all"

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


    #===================15.08.2023================================
    # Закомментировать при разворачивании - может выдать ошибку
    # failed to solve: executor failed running [/bin/sh -c rails db:migrate]:
    config.after_initialize do
      if DataWriteStatus.in_progress?
        DataWriteStatus.set_in_progress(false)
      end
    end
    #=============================================================



  end
end
