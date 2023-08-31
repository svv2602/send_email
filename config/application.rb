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
