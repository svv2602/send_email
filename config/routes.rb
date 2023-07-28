Rails.application.routes.draw do
  get 'import_data', to: 'api#import_data_from_api'
end
