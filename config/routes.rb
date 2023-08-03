Rails.application.routes.draw do
  get 'import_data', to: 'api#import_data_from_api'
  get 'xls', to: 'api#export_to_xls'
  get 'send_email', to: 'api#generate_and_send_email'

end
